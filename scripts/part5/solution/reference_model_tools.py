"""
Testbench helpers of Part 5 (no LLM calls in here).

The testbench of Part 5 contains ONLY the examples that are in the YAML spec:

  1. the tb_generator agent converts the spec's examples into a small Python file
         SPEC_EXAMPLES = [ {"name": "...", "inputs": [ {cycle 0 inputs}, ... ], "outputs": [ {cycle 0 outputs}, ... ]} ]
     (values copied from the spec; vectors are packed with the built-in helper pack(), never by hand);
  2. evaluate_examples() checks the file (ports, widths, cycles), testbench_from_vectors() writes a
     deterministic Verilog testbench from it. No expected value comes from an LLM's arithmetic.

OPTIONAL extra tests (agents.reference_model.enabled: true):

  3. the reference_model agent writes a Python BLACK-BOX MODEL of the design:
         def stimuli():          -> list of sequences (a sequence is a list of cycles {input port: int})
         def simulate(sequence): -> list with one {output port: int or None} per cycle
     evaluate_model() runs it: it must reproduce the spec's examples (so its timing is right).
     Python then computes the expected values of the extra tests.

Cycle semantics (the generated testbench follows them exactly):
    combinational design: inputs[k] are applied, outputs[k] are read after the logic settles
    sequential design   : inputs[k] are applied before the k-th rising clock edge (and kept),
                          outputs[k] are read just after that edge.
    None = do not check (e.g. before the first reset).
"""
import json
import random
import subprocess
import sys
import tempfile
from pathlib import Path

import rtl_planner_tools as pt

MIN_EXAMPLE_CHECKS = 1   # a spec has at least one example
MIN_EXTRA_CHECKS = 10    # the extra tests of a model must check at least this many outputs
MAX_CYCLES = 4000        # per testbench (simulation time)
MAX_FAIL_LINES = 25      # failing tests printed in detail by the testbench

_HARNESS = r'''
import json, sys, importlib.util

def pack(values, width):
    """Flat vector from element values: element 0 in the LOWEST bits. Negative values are two's complement."""
    r = 0
    for i, v in enumerate(values):
        r |= (int(v) & ((1 << width) - 1)) << (i * width)
    return r

def unpack(value, width, count, signed=False):
    """Inverse of pack: list of count elements (element 0 = lowest bits)."""
    out = []
    for i in range(count):
        e = (value >> (i * width)) & ((1 << width) - 1)
        if signed and e >= (1 << (width - 1)):
            e -= 1 << width
        out.append(e)
    return out

def to_signed(value, width):
    value &= (1 << width) - 1
    return value - (1 << width) if value >= (1 << (width - 1)) else value

spec = importlib.util.spec_from_file_location("ref_model", sys.argv[1])
m = importlib.util.module_from_spec(spec)
m.pack, m.unpack, m.to_signed = pack, unpack, to_signed     # provided to the file (it may redefine them)
spec.loader.exec_module(m)
mode = sys.argv[2]
out = {}
if mode == "examples":
    out["examples"] = list(getattr(m, "SPEC_EXAMPLES"))
elif mode == "model":
    ex = json.loads(sys.stdin.read() or "[]")          # the spec examples: simulate() must reproduce them
    out["sequences"] = [{"inputs": s, "outputs": m.simulate(s)} for s in m.stimuli()]
    out["examples"] = [{"inputs": e["inputs"], "expected": e["outputs"], "got": m.simulate(e["inputs"])} for e in ex]
else:   # unit: function <name> on given input vectors
    fn = getattr(m, mode)
    vecs = json.loads(sys.stdin.read())
    out["outputs"] = [fn(dict(v)) for v in vecs]
print("@@JSON@@" + json.dumps(out, default=int))
'''


def strip_code(raw: str) -> str:
    return pt.strip_fences(raw)


def _run_python(code: str, mode: str, stdin: str = "", timeout: int = 30) -> tuple:
    """Run the agent's Python code in a separate, isolated interpreter. Returns (ok, data or error text)."""
    with tempfile.TemporaryDirectory() as d:
        mod = Path(d) / "ref_model.py"
        mod.write_text(code)
        harness = Path(d) / "harness.py"
        harness.write_text(_HARNESS)
        try:
            p = subprocess.run([sys.executable, "-I", str(harness), str(mod), mode], input=stdin,
                               capture_output=True, text=True, timeout=timeout, cwd=d)
        except subprocess.TimeoutExpired:
            return False, f"the Python file did not finish in {timeout} s (infinite loop or too many vectors?)"
    if p.returncode != 0 or "@@JSON@@" not in p.stdout:
        return False, "the Python file raised an error:\n" + pt.tail(p.stderr or p.stdout, 3000)
    try:
        return True, json.loads(p.stdout.split("@@JSON@@", 1)[1])
    except ValueError as e:
        return False, f"the Python file returned values that are not numbers: {e}"


def ports_of(header: dict, clock: str = None) -> tuple:
    ins = [p for p in header["ports"] if p["dir"] == "input" and p["name"] != clock]
    outs = [p for p in header["ports"] if p["dir"] == "output"]
    return ins, outs


def clock_port(header: dict):
    for p in header["ports"]:
        if p["dir"] == "input" and p["name"].lower() in ("clk", "clock", "i_clk", "clk_i"):
            return p["name"]
    return None


def _fits(v, p) -> bool:
    w = p["width"] or 1
    return (-(1 << (w - 1)) <= v < (1 << w)) if p["signed"] or v < 0 else (0 <= v < (1 << w))


def _fmt(v):
    return "None" if v is None else (f"{v}" if -256 < v < 256 else f"0x{v & ((1 << 128) - 1):x}")


# ----------------------------------------------------------------------------- checking sequences
def _check_sequences(seqs, header: dict, labels: list, min_checks: int, max_cycles: int) -> tuple:
    """Check a list of sequences {"inputs": [...], "outputs": [...]} against the ports of the design.
    Inputs missing in a cycle keep their previous value (0 at the start); outputs missing are not checked.
    Returns (issues, number of checked outputs). The sequences are cleaned in place."""
    clock = clock_port(header)
    ins, outs = ports_of(header, clock)
    in_ports = {p["name"]: p for p in ins}
    out_ports = {p["name"]: p for p in outs}
    issues, cycles, checks, checked = [], 0, 0, set()

    if not isinstance(seqs, list) or not seqs:
        return ["no sequence found: give a non-empty list"], 0
    for s, seq in enumerate(seqs):
        lab = labels[s]
        cin, cout = (seq.get("inputs"), seq.get("outputs")) if isinstance(seq, dict) else (None, None)
        if not isinstance(cin, list) or not isinstance(cout, list) or not cin or len(cin) != len(cout):
            issues.append(f"{lab}: 'inputs' and 'outputs' must be lists with one dict per cycle and the same "
                          f"length ({len(cin) if isinstance(cin, list) else '?'} inputs, "
                          f"{len(cout) if isinstance(cout, list) else '?'} outputs)")
            continue
        held = {n: 0 for n in in_ports}
        for k, (ci, co) in enumerate(zip(cin, cout)):
            cycles += 1
            if not isinstance(ci, dict) or not isinstance(co, dict):
                issues.append(f"{lab} cycle {k}: inputs and outputs must be dicts")
                break
            extra = set(ci) - set(in_ports)
            if extra:
                issues.append(f"{lab} cycle {k}: unknown input(s) {sorted(extra)}"
                              + (f" (never drive the clock '{clock}')" if clock in extra else "")
                              + f"; the inputs are {sorted(in_ports)}")
            for n in in_ports:
                if n in ci:
                    v = ci[n]
                    if not isinstance(v, int) or isinstance(v, bool) or not _fits(v, in_ports[n]):
                        issues.append(f"{lab} cycle {k}: input {n} = {v!r} is not an integer that fits "
                                      f"{in_ports[n]['width']} bits")
                    else:
                        held[n] = v
                else:
                    ci[n] = held[n]                  # not given: keeps its value
            for n, v in list(co.items()):
                if n not in out_ports:
                    issues.append(f"{lab} cycle {k}: unknown output '{n}'; the outputs are {sorted(out_ports)}")
                elif v is not None:
                    if not isinstance(v, int) or isinstance(v, bool) or not _fits(v, out_ports[n]):
                        issues.append(f"{lab} cycle {k}: output {n} = {v!r} is not an integer that fits "
                                      f"{out_ports[n]['width']} bits")
                    else:
                        checks += 1
                        checked.add(n)
            if len(issues) > 15:
                break
        if len(issues) > 15:
            break
    if cycles > max_cycles:
        issues.append(f"{cycles} cycles in total: use at most {max_cycles}")
    if checks < min_checks and not issues:
        issues.append(f"only {checks} output value(s) are checked: at least {min_checks} are needed")
    return issues, checks


def _label_seqs(examples) -> list:
    out = []
    for i, e in enumerate(examples):
        name = e.get("name") if isinstance(e, dict) else None
        out.append(f"SPEC_EXAMPLES[{i}]" + (f" ({name})" if isinstance(name, str) and name else ""))
    return out


def evaluate_examples(code: str, header: dict) -> tuple:
    """The agent's SPEC_EXAMPLES file. Returns (ok, issues, seqs); seqs have a 'label' for the testbench."""
    ok, data = _run_python(code, "examples")
    if not ok:
        return False, [data], None
    ex = data.get("examples")
    if not isinstance(ex, list) or not ex:
        return False, ["SPEC_EXAMPLES must be a non-empty list of {'inputs': [...], 'outputs': [...]}"], None
    labels = _label_seqs(ex)
    issues, _ = _check_sequences(ex, header, labels, MIN_EXAMPLE_CHECKS, MAX_CYCLES)
    if issues:
        return False, issues[:20], None
    clock = clock_port(header)
    ports = {p["name"] for p in header["ports"]}
    out = []
    for e, lab in zip(ex, labels):
        out.append({"label": lab, "inputs": e["inputs"], "outputs": e["outputs"]})
    return True, [], out


# ----------------------------------------------------------------------------- the optional black-box model
def _shift_hint(exp, got):
    """If the model's outputs equal the expected ones moved by 1 or 2 cycles, say so."""
    for d in (1, 2, -1, -2):
        n_ok, n_all = 0, 0
        for k, ce in enumerate(exp):
            if not 0 <= k + d < len(got):
                continue
            for name, v in (ce or {}).items():
                if v is None:
                    continue
                n_all += 1
                if (got[k + d] or {}).get(name) == v:
                    n_ok += 1
        if n_all >= 2 and n_ok == n_all:
            if d > 0:
                return (f"HINT: your outputs are {d} cycle(s) LATE (the model's output at cycle k+{d} equals the "
                        f"spec's output at cycle k). Update the registers FIRST, then append the outputs of that "
                        f"cycle: outputs are read just AFTER the clock edge, so a register that loads at this edge "
                        f"already shows its new value.")
            return (f"HINT: your outputs are {-d} cycle(s) EARLY (the model's output at cycle k{d} equals the "
                    f"spec's output at cycle k). You have one register stage too few: the result appears "
                    f"{-d} cycle(s) later.")
    return ""


def _example_report(label, ex, ins):
    """'' if the model reproduces the spec example, else a report with the whole trace."""
    exp, got = ex.get("expected") or [], ex.get("got") or []
    bad = []
    for k, ce in enumerate(exp):
        cg = got[k] if k < len(got) else {}
        for n, v in (ce or {}).items():
            if v is not None and (cg or {}).get(n) != v:
                bad.append((k, n, (cg or {}).get(n), v))
    if not bad:
        return ""
    cin = ex.get("inputs") or []
    lines = [f"{label} is not reproduced by simulate(). Full trace (cycle: inputs | spec | model):"]
    for k in range(max(len(exp), len(got))):
        i_txt = " ".join(f"{p['name']}={_fmt(cin[k].get(p['name']))}" for p in ins if k < len(cin) and p['name'] in cin[k])
        e_txt = " ".join(f"{n}={_fmt(v)}" for n, v in ((exp[k] if k < len(exp) else {}) or {}).items())
        g_txt = " ".join(f"{n}={_fmt(v)}" for n, v in ((got[k] if k < len(got) else {}) or {}).items())
        mark = "  <-- differs" if any(b[0] == k for b in bad) else ""
        lines.append(f"  cycle {k}: {i_txt} | spec: {e_txt} | model: {g_txt}{mark}")
    hint = _shift_hint(exp, got)
    if hint:
        lines.append(hint)
    elif any(b[2] is None for b in bad):
        lines.append("HINT: the model gives None where the spec gives a value. After the reset cycle the registers "
                     "hold their RESET value (e.g. 0): give that value, not None. None is only for cycles before "
                     "the first reset.")
    return "\n".join(lines)


def evaluate_model(code: str, header: dict, example_seqs: list) -> tuple:
    """The optional black-box model. It must run, give valid values and reproduce the spec examples.
    Returns (ok, issues, extra sequences with a 'label')."""
    ex_payload = [{"inputs": e["inputs"], "outputs": e["outputs"]} for e in example_seqs]
    ok, data = _run_python(code, "model", stdin=json.dumps(ex_payload))
    if not ok:
        return False, [data], None
    seqs = data.get("sequences")
    labels = [f"model test {i + 1}" for i in range(len(seqs) if isinstance(seqs, list) else 0)]
    issues, _ = _check_sequences(seqs, header, labels, MIN_EXTRA_CHECKS,
                                 max(MAX_CYCLES - sum(len(e["inputs"]) for e in example_seqs), 100))
    clock = clock_port(header)
    ins, _o = ports_of(header, clock)
    for ex, src in zip(data.get("examples") or [], example_seqs):
        msg = _example_report(src["label"], ex, ins)
        if msg:
            issues.append(msg)
    if issues:
        return False, issues[:20], None
    return True, [], [{"label": lab, "inputs": s["inputs"], "outputs": s["outputs"]} for s, lab in zip(seqs, labels)]


# ----------------------------------------------------------------------------- the testbench
def _lit(v: int, w: int) -> str:
    return f"{w}'h{(v & ((1 << w) - 1)):x}"


def testbench_from_vectors(header: dict, seqs: list, top: str = None, period_ns: int = 10) -> tuple:
    """A deterministic Verilog-2001 testbench for the vectors. Returns (code, number of checks).
    It prints 'TEST: FAIL | ...' for the first failures, 'RESULT: P of T tests passed', and a final
    PASS or FAIL line (the flow's success criterion). Sequences may carry a 'label'."""
    top = top or header["name"]
    clock = clock_port(header)
    ins, outs = ports_of(header, clock)
    half = max(period_ns // 2, 1)
    L = ["`timescale 1ns/1ps", "module tb;"]
    if clock:
        L.append(f"  reg {clock};")
    for p in ins:
        L.append(f"  reg {'signed ' if p['signed'] else ''}[{p['width'] - 1}:0] {p['name']};")
    for p in outs:
        L.append(f"  wire {'signed ' if p['signed'] else ''}[{p['width'] - 1}:0] {p['name']};")
    conns = ([f".{clock}({clock})"] if clock else []) + [f".{p['name']}({p['name']})" for p in ins + outs]
    L.append(f"  {top} dut ({', '.join(conns)});")
    L += ["  integer tests, errors;"]
    if clock:
        L += [f"  initial {clock} = 1'b0;", f"  always #{half} {clock} = ~{clock};"]
    L.append("  initial begin")
    L.append("    tests = 0; errors = 0;")
    for p in ins:
        L.append(f"    {p['name']} = 0;")
    n_checks = 0
    for s, seq in enumerate(seqs, 1):
        label = str(seq.get("label") or f"seq {s}").replace('"', "'").replace("%", "")
        for k, (ci, co) in enumerate(zip(seq["inputs"], seq["outputs"])):
            sets = " ".join(f"{p['name']} = {_lit(ci[p['name']], p['width'])};" for p in ins)
            if clock:
                L.append(f"    @(negedge {clock}); {sets} @(posedge {clock}); #1;")
            else:
                L.append(f"    {sets} #{half};")
            inputs_txt = " ".join(f"{p['name']}=0x{(ci[p['name']] & ((1 << p['width']) - 1)):x}" for p in ins)
            for p in outs:
                v = co.get(p["name"])
                if v is None:
                    continue
                n_checks += 1
                exp = _lit(v, p["width"])
                L.append(f"    tests = tests + 1; if ({p['name']} !== {exp}) begin errors = errors + 1; "
                         f"if (errors <= {MAX_FAIL_LINES}) $display(\"TEST: FAIL | {label} cycle {k} | Inputs: {inputs_txt} | "
                         f"Expected: {p['name']}=0x%0h | Output: {p['name']}=0x%0h\", {exp}, {p['name']}); end")
    L += ["    $display(\"RESULT: %0d of %0d tests passed\", tests - errors, tests);",
          "    if (errors == 0) $display(\"PASS\"); else $display(\"FAIL: %0d tests\", errors);",
          "    $finish;", "  end", "endmodule", ""]
    return "\n".join(L), n_checks


# ----------------------------------------------------------------------------- unit models (planner)
def random_vectors(header: dict, n: int = 40, seed: int = 1) -> list:
    """Input vectors for a combinational module: zeros, all ones, and random values."""
    rnd = random.Random(seed)
    ins = [p for p in header["ports"] if p["dir"] == "input"]
    vecs = [{p["name"]: 0 for p in ins}, {p["name"]: (1 << p["width"]) - 1 for p in ins}]
    for _ in range(n):
        vecs.append({p["name"]: rnd.getrandbits(p["width"]) for p in ins})
    return vecs


def unit_vectors(models_code: str, name: str, header: dict, n: int = 40) -> tuple:
    """Run the planner's Python function <name>(inp) on random inputs. Returns (ok, seqs or error)."""
    vecs = random_vectors(header, n)
    ok, data = _run_python(models_code, name, stdin=json.dumps(vecs))
    if not ok:
        return False, data
    outs = data.get("outputs") or []
    out_ports = {p["name"]: p for p in header["ports"] if p["dir"] == "output"}
    seq = {"inputs": [], "outputs": []}
    for v, o in zip(vecs, outs):
        if not isinstance(o, dict):
            return False, f"{name}() must return a dict of output values"
        clean = {}
        for k, val in o.items():
            if k in out_ports and isinstance(val, int):
                clean[k] = val & ((1 << out_ports[k]["width"]) - 1)
        seq["inputs"].append(v)
        seq["outputs"].append(clean)
    return True, [seq]


def model_functions(models_code: str) -> set:
    """Names of the top-level functions defined in the planner's module_models code."""
    import ast
    try:
        tree = ast.parse(models_code or "")
    except SyntaxError:
        return set()
    return {n.name for n in tree.body if isinstance(n, ast.FunctionDef)}
