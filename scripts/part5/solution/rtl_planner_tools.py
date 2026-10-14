"""
Helpers of the RTL planner flow (Part 5). No LLM calls in here, only plain Python and the EDA tools:

  - parse_header / port_diff        Verilog-2001 module headers (ports, widths, parameters) and their differences
  - check_plan                      the plan of the RTL planner: structure, contracts, hierarchy
  - stub_module / design_files      stubs of the planned modules, the integrated design file
  - iverilog_compile / yosys_check  compile and lint checks (module alone, plan with stubs, whole design)
  - unit_testbench                  a small testbench from the planner's input/output examples
  - owners_of                       which module(s) an error message points to (feedback routing)
"""
import ast
import json
import re
import subprocess
import tempfile
from pathlib import Path

TIMESCALE = "`timescale 1ns/1ps"

VERILOG_KEYWORDS = {
    "always", "and", "assign", "begin", "buf", "case", "casex", "casez", "default", "defparam", "else", "end",
    "endcase", "endfunction", "endgenerate", "endmodule", "endtask", "for", "function", "generate", "genvar",
    "if", "initial", "inout", "input", "integer", "localparam", "module", "nand", "negedge", "nor", "not", "or",
    "output", "parameter", "posedge", "reg", "signed", "task", "wire", "while", "xor", "xnor", "logic",
}

# Yosys warnings that do not point to a real problem of the RTL
BENIGN_YOSYS = (r"Replacing memory .* with list of registers", r"is used but has no driver.*\$bb",
                r"Literal has a width of")


# ----------------------------------------------------------------------------- text helpers
def tail(text: str, n: int = 6000) -> str:
    """The last n characters of a (long) log: the end of a log is where the failure is."""
    text = text or ""
    return text if len(text) <= n else "... (log shortened) ...\n" + text[-n:]


def strip_comments(code: str) -> str:
    code = re.sub(r"/\*.*?\*/", " ", code, flags=re.S)
    return re.sub(r"//[^\n]*", "", code)


def strip_fences(raw: str) -> str:
    raw = (raw or "").strip()
    raw = re.sub(r"^```\w*\s*\n", "", raw)
    return re.sub(r"\n```\s*$", "", raw).strip()


def extract_json(raw: str) -> dict:
    """The JSON object inside an LM answer (fences and text around it are ignored)."""
    text = strip_fences(raw)
    start, end = text.find("{"), text.rfind("}")
    if start < 0 or end <= start:
        raise ValueError("no JSON object found in the answer")
    try:
        return json.loads(text[start:end + 1])
    except ValueError as first:
        try:                                    # YAML accepts some JSON mistakes (trailing commas, single quotes)
            import yaml
            data = yaml.safe_load(text[start:end + 1])
            if isinstance(data, dict):
                return data
        except Exception:
            pass
        raise ValueError(str(first))


def module_blocks(code: str) -> dict:
    """{module name: 'module ... endmodule'} of every module in the code, in order."""
    out = {}
    for m in re.finditer(r"\bmodule\s+(\w+)\b.*?\bendmodule\b", code or "", flags=re.S):
        out.setdefault(m.group(1), m.group(0))
    return out


def extract_module(raw: str, name: str) -> str:
    """The module 'name' from an LM answer (fences, timescale and other modules are dropped)."""
    code = strip_fences(raw)
    code = re.sub(r"`(?!(define|include|timescale|ifdef|ifndef|endif|else|undef)\b)", "", code)
    code = re.sub(r"`timescale[^\n]*\n?", "", code)
    blocks = module_blocks(code)
    if name in blocks:
        return blocks[name].strip()
    if len(blocks) == 1:            # one module with another name: keep it, the header check reports it
        return next(iter(blocks.values())).strip()
    return code.strip()


# ----------------------------------------------------------------------------- module headers
def _balanced(text: str, start: int) -> int:
    """Index of the ')' that closes the '(' at text[start]."""
    depth = 0
    for k in range(start, len(text)):
        if text[k] == "(":
            depth += 1
        elif text[k] == ")":
            depth -= 1
            if depth == 0:
                return k
    raise ValueError("unbalanced parentheses in the module header")


def _split_top(text: str) -> list:
    """Split on commas that are not inside (), [] or {}."""
    parts, depth, cur = [], 0, ""
    for ch in text:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur)
    return [p.strip() for p in parts if p.strip()]


_ALLOWED = (ast.Expression, ast.BinOp, ast.UnaryOp, ast.Constant, ast.Name, ast.Load, ast.Add, ast.Sub,
            ast.Mult, ast.Div, ast.FloorDiv, ast.Mod, ast.Pow, ast.USub, ast.UAdd, ast.LShift, ast.RShift)


def eval_expr(expr: str, params: dict):
    """Value of a simple constant expression (numbers, parameters, + - * / % ** << >>), or None."""
    expr = (expr or "").strip()
    expr = re.sub(r"\b\d*'[sS]?[dD](\d+)\b", r"\1", expr)              # 8'd5 -> 5
    expr = re.sub(r"\b\d*'[sS]?[hH]([0-9a-fA-F_]+)\b", lambda m: str(int(m.group(1).replace("_", ""), 16)), expr)
    expr = re.sub(r"\b\d*'[sS]?[bB]([01_]+)\b", lambda m: str(int(m.group(1).replace("_", ""), 2)), expr)
    expr = expr.replace("/", "//")
    try:
        tree = ast.parse(expr, mode="eval")
    except SyntaxError:
        return None
    for node in ast.walk(tree):
        if not isinstance(node, _ALLOWED):
            return None
        if isinstance(node, ast.Name) and node.id not in params:
            return None
    try:
        return int(eval(compile(tree, "<expr>", "eval"), {"__builtins__": {}}, dict(params)))
    except Exception:
        return None


def width_of(rng: str, params: dict):
    """Number of bits of a range like '7:0' or 'N*WIDTH-1:0' (None if it cannot be evaluated)."""
    if not rng:
        return 1
    if ":" not in rng:
        return None
    msb, lsb = rng.split(":", 1)
    a, b = eval_expr(msb, params), eval_expr(lsb, params)
    return None if a is None or b is None else abs(a - b) + 1


_PORT = re.compile(r"^(?:(input|output|inout)\s+)?(?:(wire|reg|logic)\s+)?(?:(signed)\s+)?"
                   r"(?:\[\s*([^\]]+?)\s*\]\s*)?([A-Za-z_]\w*)$")


def parse_header(code: str) -> dict:
    """Name, parameters and ports of the FIRST module of an ANSI-style Verilog-2001 header.

    Returns {"name", "params": {name: value}, "ports": [{"name","dir","signed","range","width"}], "text"}.
    Raises ValueError with a readable message if the header cannot be parsed.
    """
    src = strip_comments(code or "")
    m = re.search(r"\bmodule\s+([A-Za-z_]\w*)\s*", src)
    if not m:
        raise ValueError("no 'module <name>' found")
    name, pos = m.group(1), m.end()
    params = {}
    if src[pos:pos + 1] == "#" or src[pos:].lstrip().startswith("#"):
        p_open = src.index("(", pos)
        p_close = _balanced(src, p_open)
        for item in _split_top(src[p_open + 1:p_close]):
            item = re.sub(r"^\s*parameter\s+", "", item)
            item = re.sub(r"^(integer|signed|\[[^\]]*\])\s+", "", item)
            pm = re.match(r"([A-Za-z_]\w*)\s*=\s*(.+)$", item.strip(), flags=re.S)
            if not pm:
                raise ValueError(f"cannot read the parameter '{item.strip()}'")
            params[pm.group(1)] = eval_expr(pm.group(2), params)
        pos = p_close + 1
    rest = src[pos:]
    if not rest.lstrip().startswith("("):
        if rest.lstrip().startswith(";"):
            return {"name": name, "params": params, "ports": [], "text": src[m.start():pos + rest.index(";") + 1]}
        raise ValueError("the port list '( ... );' must follow the module name")
    o = pos + rest.index("(")
    c = _balanced(src, o)
    ports, last = [], {"dir": None, "signed": False, "range": None}
    for item in _split_top(src[o + 1:c]):
        item = re.sub(r"\s+", " ", item.strip())
        pm = _PORT.match(item)
        if not pm:
            raise ValueError(f"cannot read the port '{item}' (use ANSI style: 'input [7:0] a')")
        d, _typ, sg, rng, pname = pm.groups()
        if d:
            last = {"dir": d, "signed": bool(sg), "range": rng}
        elif last["dir"] is None:
            raise ValueError(f"port '{pname}' has no direction: write the header in ANSI style "
                             "(module m(input a, output [7:0] y);)")
        else:
            if sg:
                last = dict(last, signed=True)
            if rng:
                last = dict(last, range=rng)
        ports.append({"name": pname, "dir": last["dir"], "signed": last["signed"], "range": last["range"],
                      "width": width_of(last["range"], params)})
    end = src.find(";", c)
    return {"name": name, "params": params, "ports": ports, "text": src[m.start():(end + 1) if end >= 0 else c + 1]}


def port_diff(expected: dict, actual: dict) -> list:
    """Differences between two parsed headers (name, ports, directions, widths, signedness)."""
    issues = []
    if expected["name"] != actual["name"]:
        issues.append(f"module name is '{actual['name']}', expected '{expected['name']}'")
    exp = {p["name"]: p for p in expected["ports"]}
    act = {p["name"]: p for p in actual["ports"]}
    for n in exp:
        if n not in act:
            issues.append(f"port '{n}' is missing")
    for n in act:
        if n not in exp:
            issues.append(f"port '{n}' is not in the contract")
    for n in exp:
        if n in act:
            e, a = exp[n], act[n]
            if e["dir"] != a["dir"]:
                issues.append(f"port '{n}' is {a['dir']}, expected {e['dir']}")
            if e["width"] is not None and a["width"] is not None and e["width"] != a["width"]:
                issues.append(f"port '{n}' has {a['width']} bits, expected {e['width']}")
            if e["signed"] != a["signed"]:
                issues.append(f"port '{n}' is {'signed' if a['signed'] else 'unsigned'}, "
                              f"expected {'signed' if e['signed'] else 'unsigned'}")
    return issues


def has_clock(header: dict) -> bool:
    return any(p["dir"] == "input" and re.fullmatch(r"(clk|clock|i_clk|clk_i)", p["name"], re.I)
               for p in header["ports"])


# ----------------------------------------------------------------------------- the plan
def instances_in(code: str, names) -> list:
    """Names (from 'names') of the modules instantiated in a piece of Verilog."""
    src = strip_comments(code or "")
    found = []
    for n in names:
        if re.search(rf"(?<![\w$.]){re.escape(n)}\s*(#\s*\([^;]*?\))?\s+[A-Za-z_]\w*\s*\(", src, flags=re.S):
            found.append(n)
    return found


def check_plan(raw: dict, top: dict, max_modules: int = 8, top_rtl: str = None, models: str = "") -> tuple:
    """Check the planner's answer. Returns (plan, issues).

    plan = {"decompose": bool, "summary": str, "modules": [contract...], "top_rtl": str or "", "order": [...]}
    A contract: {"name", "header", "function", "latency_cycles", "examples", "children", "parsed"}.
    'top' is the parsed module_signature of the spec.
    """
    issues = []
    if not isinstance(raw, dict):
        return None, ["the plan must be a JSON object"]
    decompose = bool(raw.get("decompose", True))
    modules = raw.get("modules") or []
    if not isinstance(modules, list):
        return None, ["'modules' must be a list"]
    top_name = top["name"]

    plan = {"decompose": decompose, "summary": str(raw.get("summary", "")).strip(),
            "modules": [], "top_rtl": "", "order": [], "models": ""}

    if not decompose:
        # One module: the top itself, written by a module generator from the spec
        plan["modules"] = [{"name": top_name, "header": top["text"], "function": "the whole specification",
                            "latency_cycles": raw.get("latency_cycles"), "examples": [], "children": [],
                            "parsed": top}]
        plan["order"] = [top_name]
        return plan, []

    if not modules:
        issues.append("decompose is true but 'modules' is empty (set decompose to false for a single module)")
    if len(modules) > max_modules:
        issues.append(f"{len(modules)} modules: use at most {max_modules}")

    names = []
    for k, m in enumerate(modules, 1):
        if not isinstance(m, dict):
            issues.append(f"module #{k} is not an object")
            continue
        name = str(m.get("name", "")).strip()
        where = f"module '{name or '#' + str(k)}'"
        if not re.fullmatch(r"[A-Za-z_]\w*", name):
            issues.append(f"{where}: invalid name")
            continue
        if name in VERILOG_KEYWORDS:
            issues.append(f"{where}: the name is a Verilog keyword")
        if name == top_name:
            issues.append(f"{where}: do not list the top module '{top_name}' in 'modules' (it is 'top_rtl')")
        if name in names:
            issues.append(f"{where}: the name is used twice")
        names.append(name)
        header = str(m.get("header", "")).strip()
        try:
            parsed = parse_header(header + ("" if header.rstrip().endswith(";") else ";"))
            if parsed["name"] != name:
                issues.append(f"{where}: its header declares module '{parsed['name']}'")
            if not parsed["ports"]:
                issues.append(f"{where}: the header has no ports")
            if any(p["width"] is None for p in parsed["ports"]):
                issues.append(f"{where}: give every port a width with numbers (or parameters with defaults)")
        except ValueError as e:
            issues.append(f"{where}: header: {e}")
            parsed = None
        lat = m.get("latency_cycles")
        if lat is not None and (not isinstance(lat, int) or lat < 0):
            issues.append(f"{where}: latency_cycles must be an integer >= 0")
        ex = m.get("examples") or []
        if not isinstance(ex, list):
            issues.append(f"{where}: 'examples' must be a list")
            ex = []
        plan["modules"].append({"name": name, "header": header, "function": str(m.get("function", "")).strip(),
                                "latency_cycles": lat, "examples": ex,
                                "children": [c for c in (m.get("children") or []) if isinstance(c, str)],
                                "parsed": parsed})

    top_rtl = str(top_rtl if top_rtl is not None else raw.get("top_rtl", "")).strip()
    plan["top_rtl"] = top_rtl
    if not top_rtl:
        issues.append("'top_rtl' is missing: write the top module that instantiates and wires the modules")
    else:
        blocks = module_blocks(strip_fences(top_rtl))
        if top_name not in blocks:
            issues.append(f"'top_rtl' must contain 'module {top_name} ... endmodule'")
        else:
            plan["top_rtl"] = blocks[top_name]
            extra = [b for b in blocks if b != top_name]
            if extra:
                issues.append(f"'top_rtl' must contain only the top module (found also: {', '.join(extra)}); "
                              "every other module goes into 'modules'")
            try:
                issues += [f"top module header: {d}" for d in port_diff(top, parse_header(blocks[top_name]))]
            except ValueError as e:
                issues.append(f"top module header: {e}")

    # Hierarchy: who instantiates whom (from the code of the top, and 'children' of the modules)
    known = set(names)
    used = set(instances_in(plan["top_rtl"], names)) if plan["top_rtl"] else set()
    for m in plan["modules"]:
        bad = [c for c in m["children"] if c not in known or c == m["name"]]
        if bad:
            issues.append(f"module '{m['name']}': unknown children {bad}")
        used.update(c for c in m["children"] if c in known)
    for n in names:
        if n not in used:
            issues.append(f"module '{n}' is never instantiated (not in top_rtl nor in any 'children')")
    # Python models of the modules (optional): must be valid Python, one function per module name
    models = strip_fences(models or "")
    if models and not re.fullmatch(r"(?is)\s*(none|n/?a|-)?\s*", models):
        import ast as _ast
        try:
            _ast.parse(models)
            plan["models"] = models
            defined = {n.name for n in _ast.parse(models).body if isinstance(n, _ast.FunctionDef)}
            unknown = [d for d in defined if d not in known and not d.startswith("_")]
            if unknown:
                issues.append(f"module_models: functions {unknown} do not match any planned module name "
                              "(name each function exactly like its module; helpers start with '_')")
        except SyntaxError as e:
            issues.append(f"module_models is not valid Python: {e}")
    order, cyc = _order(plan["modules"])
    if cyc:
        issues.append("the hierarchy has a cycle: " + " -> ".join(cyc))
    plan["order"] = order
    return plan, issues


def _order(modules: list) -> tuple:
    """Children before parents. Returns (order, cycle or [])."""
    by = {m["name"]: m for m in modules}
    order, state = [], {}

    def visit(n, path):
        if state.get(n) == 1:
            return path[path.index(n):] + [n]
        if state.get(n) == 2:
            return []
        state[n] = 1
        for c in by[n]["children"]:
            if c in by:
                cyc = visit(c, path + [n])
                if cyc:
                    return cyc
        state[n] = 2
        order.append(n)
        return []

    for m in modules:
        cyc = visit(m["name"], [])
        if cyc:
            return order, cyc
    return order, []


def contract_key(m: dict) -> str:
    """What must stay the same for a module's code to be kept after a replan."""
    return json.dumps([re.sub(r"\s+", " ", m["header"]).strip(), m["function"], m["latency_cycles"]])


def plan_for_prompt(plan: dict) -> str:
    """The plan for the prompts: contracts (JSON), the top module and the Python module models."""
    text = json.dumps({"decompose": plan["decompose"], "summary": plan["summary"],
                       "modules": [{k: m[k] for k in ("name", "header", "function", "latency_cycles", "children")}
                                   for m in plan["modules"]]}, indent=2)
    if plan["top_rtl"]:
        text += "\n\ntop_rtl:\n" + plan["top_rtl"]
    if plan.get("models"):
        text += "\n\nmodule_models:\n" + plan["models"]
    return text


def model_source(models: str, name: str) -> str:
    """Source of the Python function <name> in the planner's module_models (empty if none)."""
    import ast as _ast
    try:
        tree = _ast.parse(models or "")
    except SyntaxError:
        return ""
    for n in tree.body:
        if isinstance(n, _ast.FunctionDef) and n.name == name:
            return _ast.get_source_segment(models, n) or ""
    return ""


def contract_for_prompt(plan: dict, name: str) -> str:
    m = next(x for x in plan["modules"] if x["name"] == name)
    children = [x for x in plan["modules"] if x["name"] in m["children"]]
    text = json.dumps({"name": m["name"], "header": m["header"], "function": m["function"],
                       "latency_cycles": m["latency_cycles"],
                       "children_headers": {c["name"]: c["header"] for c in children}}, indent=2)
    src = model_source(plan.get("models", ""), name)
    if src:
        text += "\n\nPython model of this module (the unit test compares your module with it on random inputs):\n" + src
    return text


# ----------------------------------------------------------------------------- Verilog files
def stub_module(header: str) -> str:
    h = header.strip()
    if not h.endswith(";"):
        h += ";"
    return f"{h}\n  // stub: the real module is written by a module generator\nendmodule\n"


def design_file(plan: dict, code: dict, top_name: str) -> tuple:
    """The integrated design (children first, top last) and the line range of every module in it."""
    parts = [(n, code[n]) for n in plan["order"] if n in code]
    if plan["decompose"]:
        parts.append((top_name, plan["top_rtl"]))
    lines, ranges = [TIMESCALE, ""], {}
    for name, c in parts:
        start = len(lines) + 1
        body = c.strip().splitlines()
        lines += body + [""]
        ranges[name] = (start, start + len(body) - 1)
    return "\n".join(lines) + "\n", ranges


# ----------------------------------------------------------------------------- tools
def run(cmd, cwd=None, timeout=120) -> tuple:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except subprocess.TimeoutExpired:
        return 124, f"{cmd[0]} timed out after {timeout} s"


def iverilog_compile(files: list, top: str = None) -> tuple:
    """Compile with Icarus Verilog (-g2005 -Wall). Returns (ok, output)."""
    with tempfile.TemporaryDirectory() as d:
        cmd = ["iverilog", "-g2005", "-Wall", "-Wno-timescale", "-o", str(Path(d) / "a.out")]
        if top:
            cmd += ["-s", top]
        rc, out = run(cmd + [str(f) for f in files])
    return rc == 0, out.strip()


def yosys_check(files: list, top: str, blackbox: list = ()) -> tuple:
    """Elaborate and lint with Yosys. Blackbox files are read as empty cells (stubs of other modules).
    Returns (ok, issues text): ok is False on errors, latches, multiple drivers, loops, width mismatches, ..."""
    script = "".join(f"read_verilog -lib {Path(f).as_posix()}; " for f in blackbox)
    script += "".join(f"read_verilog {Path(f).as_posix()}; " for f in files)
    script += f"hierarchy -check -top {top}; proc; opt_clean; check"
    rc, out = run(["yosys", "-p", script])
    issues = []
    for line in out.splitlines():
        s = line.strip()
        if re.search(r"\bERROR\b", s) or "Latch inferred" in s or s.startswith("Warning:"):
            if not any(re.search(b, s) for b in BENIGN_YOSYS):
                issues.append(s)
    issues = list(dict.fromkeys(issues))           # unique, in order
    return rc == 0 and not issues, "\n".join(issues) if issues else ("" if rc == 0 else tail(out, 3000))


def _literal(value, width: int, signed: bool):
    """A sized Verilog literal from an int or a Verilog literal string, or None."""
    if isinstance(value, bool):
        value = int(value)
    if isinstance(value, int):
        if value < 0:
            return f"-{width}'sd{-value}" if signed else f"{width}'d{value & ((1 << width) - 1)}"
        return f"{width}'d{value}"
    if isinstance(value, str):
        v = value.strip().replace(" ", "")
        if re.fullmatch(r"-?\d+", v):
            return _literal(int(v), width, signed)
        if re.fullmatch(r"\d*'[sS]?[bBoOdDhH][0-9a-fA-FxXzZ_]+", v):
            return v
    return None


def unit_testbench(m: dict) -> tuple:
    """A testbench from the planner's examples, for a COMBINATIONAL module (latency 0, no clock).
    Returns (code, n_examples) or (None, reason)."""
    h = m.get("parsed")
    if not h:
        return None, "no parsed header"
    if has_clock(h) or (m.get("latency_cycles") or 0) != 0:
        return None, "sequential module: only compile and lint checks"
    ex = [e for e in (m.get("examples") or []) if isinstance(e, dict)]
    if not ex:
        return None, "no examples in the plan"
    ins = [p for p in h["ports"] if p["dir"] == "input"]
    outs = [p for p in h["ports"] if p["dir"] == "output"]
    decl = []
    for p in ins:
        decl.append(f"  reg {'signed ' if p['signed'] else ''}[{p['width'] - 1}:0] {p['name']};")
    for p in outs:
        decl.append(f"  wire {'signed ' if p['signed'] else ''}[{p['width'] - 1}:0] {p['name']};")
    conn = ", ".join(f".{p['name']}({p['name']})" for p in h["ports"] if p["dir"] in ("input", "output"))
    body, n = [], 0
    for k, e in enumerate(ex, 1):
        e_in, e_out = e.get("inputs") or {}, e.get("outputs") or {}
        sets, checks, ok = [], [], True
        for p in ins:
            lit = _literal(e_in.get(p["name"], 0), p["width"], p["signed"])
            if lit is None:
                ok = False
                break
            sets.append(f"{p['name']} = {lit};")
        for name, val in e_out.items():
            p = next((q for q in outs if q["name"] == name), None)
            lit = _literal(val, p["width"], p["signed"]) if p else None
            if lit is None:
                ok = False
                break
            checks.append(f"    if ({name} !== {lit}) begin $display(\"UNIT FAIL example {k}: {name} = %0d (0x%0h), "
                          f"expected %0d (0x%0h)\", {name}, {name}, {lit}, {lit}); errors = errors + 1; end")
        if not ok or not checks:
            continue
        n += 1
        body.append(f"    {' '.join(sets)} #1;")
        body += checks
    if not n:
        return None, "no usable examples (inputs/outputs must be numbers or sized Verilog literals)"
    code = "\n".join([TIMESCALE, "module unit_tb;"] + decl + [f"  {h['name']} dut ({conn});", "  integer errors;",
                      "  initial begin", "    errors = 0;"] + body +
                     ["    if (errors == 0) $display(\"UNIT PASS\"); else $display(\"UNIT FAIL: %0d examples\", errors);",
                      "    $finish;", "  end", "endmodule", ""])
    return code, n


def run_unit_testbench(module_file: Path, tb_code: str, child_stubs: list = ()) -> tuple:
    with tempfile.TemporaryDirectory() as d:
        tb = Path(d) / "unit_tb.v"
        tb.write_text(tb_code)
        exe = Path(d) / "u.out"
        rc, out = run(["iverilog", "-g2005", "-Wno-timescale", "-o", str(exe), str(module_file), *map(str, child_stubs), str(tb)])
        if rc != 0:
            return False, "unit testbench compilation failed:\n" + out
        rc, out = run(["vvp", str(exe)], timeout=20)
    return ("UNIT PASS" in out and "UNIT FAIL" not in out), out.strip()


# ----------------------------------------------------------------------------- feedback routing
def owners_of(text: str, ranges: dict, design_name: str, names) -> set:
    """Modules an error message points to: by file:line in the integrated design file, or by module name
    as Yosys and Icarus print it ("\\mod.\\sig", "module `\\mod'", "in module mod")."""
    found = set()
    for ln in re.findall(rf"{re.escape(design_name)}:(\d+)", text or ""):
        ln = int(ln)
        for n, (a, b) in ranges.items():
            if a <= ln <= b:
                found.add(n)
    names = set(names)
    for n in re.findall(r"\\([A-Za-z_]\w*)\.\\?", text or ""):
        if n in names:
            found.add(n)
    for n in re.findall(r"module\s+[`'\"]?\\?([A-Za-z_]\w*)", text or ""):
        if n in names:
            found.add(n)
    return found
