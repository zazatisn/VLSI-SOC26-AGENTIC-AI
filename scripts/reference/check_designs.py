#!/usr/bin/env python3
"""
Check the tutorial designs, sign off an RTL, or grade a testbench.

Every design pN has:
  <designs_dir>/pN.yaml                         the specification given to the agents
  <evaluation_dir>/visible/pN/*_tb.v            the reference (sign-off) testbench
  reference/pN/<module>.v                       a golden RTL written from the specification
  reference/pN/mutants.yaml                     bugs injected into the golden RTL

Modes
  python3 check_designs.py                      check every design: spec <-> golden RTL <-> reference TB
  python3 check_designs.py -d p8                one design
  python3 check_designs.py -d p8 --rtl FILE.v   SIGN-OFF: run the reference TB on your RTL (e.g. the agent's final RTL)
  python3 check_designs.py -d p8 --tb FILE.v    GRADE A TESTBENCH: it must pass the golden RTL and fail on every mutant
  python3 check_designs.py --mutants            also prove that each reference TB catches every mutant
  python3 check_designs.py --synth [--gls]      also synthesize the golden RTL with Yosys (+ gate-level simulation)

A testbench passes when it prints PASS and never prints FAIL or ERROR (the convention of the flows).
Needs iverilog/vvp (and yosys for the port check, --synth and --gls). Run it from scripts/reference/.
"""
import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
G, RD, Y, C, B, R = "\033[92m", "\033[91m", "\033[93m", "\033[96m", "\033[1m", "\033[0m"


def die(msg):
    print(f"{RD}Error: {msg}{R}")
    sys.exit(2)


# ----------------------------------------------------------------------------------------------- helpers
def run(cmd, cwd=None, timeout=300):
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired:
        return 124, "TIMEOUT"


def sim(sources, workdir, timeout=120):
    """Compile + run with Icarus (-g2005 like the flows). Returns (status, log). status: PASS/FAIL/COMPILE/TIMEOUT."""
    out = Path(workdir) / "sim.out"
    rc, log = run(["iverilog", "-g2005", "-o", str(out), *map(str, sources)])
    if rc:
        return "COMPILE", log
    rc, log = run(["vvp", "-n", str(out)], timeout=timeout)
    if rc == 124:
        return "TIMEOUT", log
    if re.search(r"FAIL|ERROR", log, re.I) or not re.search(r"PASS", log, re.I):
        return "FAIL", log
    return "PASS", log


def spec_of(designs_dir, pid):
    f = designs_dir / f"{pid}.yaml"
    if not f.exists():
        die(f"{f} not found")
    data = yaml.safe_load(f.read_text())
    module = list(data)[0]
    return module, data[module]


def tb_of(eval_dir, pid):
    tbs = sorted((eval_dir / "visible" / pid).glob("*_tb.v"))
    return tbs[0] if tbs else None


def golden_of(pid):
    files = sorted((HERE / pid).glob("*.v"))
    return files


def ports_of(verilog_files, top, workdir):
    """{name: (direction, width)} with default parameters, via Yosys."""
    js = Path(workdir) / f"{top}_ports.json"
    script = f"read_verilog -sv {' '.join(map(str, verilog_files))}; hierarchy -top {top}; proc; write_json {js}"
    rc, log = run(["yosys", "-q", "-p", script])
    if rc:
        return None, log
    import json
    mod = json.loads(js.read_text())["modules"]
    m = mod.get(top) or next(v for k, v in mod.items() if k.endswith(top))
    return {n: (p["direction"], len(p["bits"])) for n, p in m["ports"].items()}, ""


def apply_mutant(text, m):
    for f, r in ((m["find"], m["replace"]), (m.get("also_find"), m.get("also_replace"))):
        if f:
            if f not in text:
                return None
            text = text.replace(f, r, 1)
    return text


def mutants_of(pid):
    f = HERE / pid / "mutants.yaml"
    return yaml.safe_load(f.read_text()) if f.exists() else []


def strip_param_overrides(tb_text):
    """A synthesized netlist has no parameters: drop '#(...)' from the DUT instance for gate-level simulation."""
    return re.sub(r"(\n\s*\w+)\s*#\s*\((?:[^()]|\([^()]*\))*\)\s*(\w+\s*\()", r"\1 \2", tb_text)


# ----------------------------------------------------------------------------------------------- checks
def check_design(pid, a, work):
    module, spec = spec_of(a.designs_dir, pid)
    tb = tb_of(a.evaluation_dir, pid)
    golden = golden_of(pid)
    issues, notes = [], []

    for key in ("description", "clock_period", "ports", "module_signature", "timing"):
        if key not in spec:
            issues.append(f"spec has no '{key}'")
    if not tb:
        issues.append("no reference testbench in evaluation/visible/" + pid)
    if not golden:
        issues.append("no golden RTL in reference/" + pid)
    if issues:
        return False, issues, notes

    # 1. The reference TB compiles against the bare module signature (what the flows check for agent TBs)
    stub = work / f"{pid}_stub.v"
    stub.write_text("`timescale 1ns/1ps\n" + spec["module_signature"] + "\nendmodule\n")
    rc, log = run(["iverilog", "-g2005", "-o", str(work / "stub.out"), str(stub), str(tb)])
    if rc:
        issues.append("reference TB does not compile against the spec's module_signature:\n" + log.strip()[:600])

    # 2. The golden RTL has exactly the ports of the signature (names, directions, widths)
    if shutil.which("yosys"):
        sig_ports, l1 = ports_of([stub], module, work)
        gold_ports, l2 = ports_of(golden, module, work)
        if sig_ports is None or gold_ports is None:
            issues.append("Yosys could not read the signature or the golden RTL:\n" + (l1 or l2)[:400])
        elif sig_ports != gold_ports:
            issues.append(f"golden RTL ports {gold_ports} differ from the spec signature {sig_ports}")
        # spec 'ports' list names = signature names
        listed = {p["name"] for p in spec["ports"]}
        if sig_ports and listed != set(sig_ports):
            issues.append(f"spec 'ports' {sorted(listed)} differ from module_signature {sorted(sig_ports)}")
    else:
        notes.append("yosys not found: port check skipped")

    # 3. The golden RTL passes the reference TB
    status, log = sim([*golden, tb], work)
    if status != "PASS":
        issues.append(f"golden RTL does not pass the reference TB ({status}):\n" + log.strip()[-600:])

    # 4. The reference TB catches every mutant
    if a.mutants:
        muts = mutants_of(pid)
        base = golden[0].read_text()
        missed = []
        for m in muts:
            text = apply_mutant(base, m)
            if text is None:
                issues.append(f"mutant '{m['name']}' does not apply to the golden RTL"); continue
            mf = work / f"mut_{golden[0].name}"
            mf.write_text(text)
            st, _ = sim([mf, *golden[1:], tb], work)
            if st == "PASS":
                missed.append(m["name"])
        if missed:
            issues.append("reference TB misses mutants: " + ", ".join(missed))
        else:
            notes.append(f"reference TB catches {len(muts)}/{len(muts)} mutants")

    # 5. Synthesis (+ gate-level simulation) of the golden RTL
    if a.synth or a.gls:
        lib = find_liberty(a)
        if not lib:
            notes.append("sky130hd liberty not found (set ORFS_DIR): synthesis skipped")
        else:
            net = work / f"{pid}_net.v"
            script = (f"read_verilog -sv {' '.join(map(str, golden))}; synth -top {module} -flatten; check -assert; "
                      f"dfflibmap -liberty {lib}; abc -liberty {lib}; opt_clean; stat -liberty {lib}; write_verilog -noattr {net}")
            rc, log = run(["yosys", "-p", script])
            if rc:
                issues.append("Yosys synthesis failed:\n" + log.strip()[-500:])
            else:
                area = re.findall(r"Chip area for (?:top )?module.*?:\s*([\d.]+)", log)
                latches = len(re.findall(r"sky130_fd_sc_hd__dl[a-z]+_\d", net.read_text()))
                notes.append(f"synthesis: {float(area[-1]):.0f} um^2 of cells, {latches} latches" if area else "synthesis ok")
                if latches:
                    issues.append(f"{latches} latches in the golden netlist")
                if a.gls:
                    pdk = find_pdk_models(a)
                    gtb = work / f"{pid}_gls_tb.v"
                    gtb.write_text(strip_param_overrides(tb.read_text()))
                    rc, log = run(["iverilog", "-g2005", "-DFUNCTIONAL", "-DUNIT_DELAY=#0", "-o", str(work / "gls.out"),
                                   str(net), str(pdk), str(gtb)])
                    if rc:
                        issues.append("gate-level compile failed:\n" + log[:400])
                    else:
                        rc, log = run(["vvp", "-n", str(work / "gls.out")])
                        ok = re.search(r"PASS", log) and not re.search(r"FAIL|ERROR", log)
                        if ok:
                            notes.append("gate-level simulation passes")
                        else:
                            issues.append("gate-level simulation fails:\n" + log[-400:])
    return not issues, issues, notes


def find_liberty(a):
    for root in filter(None, [a.orfs_dir, Path("/home/OpenROAD-flow-scripts")]):
        f = Path(root) / "flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
        if f.exists():
            return f
    return None


def find_pdk_models(a):
    for f in [HERE.parent / "part2/solution/PDK_files/sky130hd.v", HERE.parent / "part2/problem/PDK_files/sky130hd.v"]:
        if f.exists():
            return f
    die("PDK_files/sky130hd.v not found")


def signoff(pid, rtl_files, a, work):
    module, _ = spec_of(a.designs_dir, pid)
    tb = tb_of(a.evaluation_dir, pid)
    if not tb:
        die(f"no reference testbench for {pid}")
    status, log = sim([*rtl_files, tb], work)
    lines = log.strip().splitlines()
    bad = [l for l in lines if re.search(r"FAIL|ERROR", l, re.I)]
    if status == "COMPILE" or not bad:
        print("\n".join(lines[-40:]))
    else:
        print("\n".join(bad[:15]))
        if len(bad) > 15:
            print(f"... {len(bad) - 15} more failing lines")
    col = G if status == "PASS" else RD
    n = re.findall(r"(\d+) errors? found", log)
    count = (f" ({n[-1]} failing checks)" if n else f" ({len(bad)} failing lines)") if bad and status == "FAIL" else ""
    print(f"\n{B}Sign-off of {', '.join(map(str, rtl_files))} with {tb.name}: {col}{status}{R}{count}")
    return status == "PASS"


def grade_tb(pid, tb_file, a, work):
    golden = golden_of(pid)
    if not golden:
        die(f"no golden RTL for {pid}")
    status, log = sim([*golden, tb_file], work)
    print(f"{B}Golden RTL{R}: {G if status == 'PASS' else RD}{status}{R}  (a correct design must PASS)")
    if status != "PASS":
        print(log.strip()[-1500:])
        print(f"{RD}The testbench rejects a correct design: fix it before grading.{R}")
        return False
    caught = 0
    muts = mutants_of(pid)
    base = golden[0].read_text()
    for m in muts:
        text = apply_mutant(base, m)
        mf = work / f"mut_{golden[0].name}"
        mf.write_text(text)
        st, _ = sim([mf, *golden[1:], tb_file], work)
        hit = st != "PASS"
        caught += hit
        print(f"  {'caught' if hit else 'MISSED':6}  {m['name']}" if hit else f"  {Y}MISSED{R}  {m['name']}")
    pct = 100 * caught / len(muts) if muts else 0
    col = G if caught == len(muts) else (Y if caught else RD)
    print(f"\n{B}Testbench strength for {pid}: {col}{caught}/{len(muts)} bugs caught ({pct:.0f}%){R}")
    return caught == len(muts)


# ----------------------------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-d", "--design", action="append", help="pN (repeatable). Default: every design with a golden RTL")
    ap.add_argument("--rtl", nargs="+", type=Path, help="sign off these RTL files with the reference TB")
    ap.add_argument("--tb", type=Path, help="grade this testbench against the golden RTL and its mutants")
    ap.add_argument("--mutants", action="store_true", help="check that every reference TB catches every mutant")
    ap.add_argument("--synth", action="store_true", help="synthesize the golden RTL (Yosys + sky130hd liberty)")
    ap.add_argument("--gls", action="store_true", help="gate-level simulation of the synthesized golden RTL")
    ap.add_argument("--designs-dir", type=Path, default=HERE.parent / "part2/designs")
    ap.add_argument("--evaluation-dir", type=Path, default=HERE.parent / "part2/evaluation")
    ap.add_argument("--orfs-dir", type=Path, default=None, help="OpenROAD-flow-scripts (for the liberty). Default: $ORFS_DIR")
    a = ap.parse_args()
    import os
    a.orfs_dir = a.orfs_dir or (Path(os.environ["ORFS_DIR"]) if os.environ.get("ORFS_DIR") else None)
    for t in ("iverilog", "vvp"):
        if not shutil.which(t):
            die(f"{t} not found in PATH")

    work = Path(tempfile.mkdtemp(prefix="check_designs_"))
    try:
        if a.rtl or a.tb:
            if not a.design or len(a.design) != 1:
                die("--rtl and --tb need exactly one --design pN")
            pid = a.design[0]
            ok = signoff(pid, a.rtl, a, work) if a.rtl else grade_tb(pid, a.tb, a, work)
            sys.exit(0 if ok else 1)

        pids = a.design or sorted((p.name for p in HERE.glob("p*") if p.is_dir()), key=lambda s: int(s[1:]))
        all_ok = True
        print(f"{B}{'design':6} {'module':26} result{R}")
        for pid in pids:
            module, _ = spec_of(a.designs_dir, pid)
            ok, issues, notes = check_design(pid, a, work)
            all_ok &= ok
            print(f"{pid:6} {module:26} {G + 'OK' if ok else RD + 'PROBLEM'}{R}  {'; '.join(notes)}")
            for i in issues:
                print(f"       {RD}- {i}{R}")
        print(f"\n{G + 'All designs consistent.' if all_ok else RD + 'Some designs have problems.'}{R}")
        sys.exit(0 if all_ok else 1)
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
