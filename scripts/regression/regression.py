#!/usr/bin/env python3
"""
Regression test of the tutorial environment (Docker image, Dockerfile.arm64 build or local install).

It runs small examples whose correct result is known, so a failure always means the ENVIRONMENT is
broken (not a prompt or a model having a bad day). By default no LLM is called and nothing costs tokens.

  python3 regression.py              tools + Python + simulation + synthesis + a full OpenROAD flow of p11
  python3 regression.py --quick      skip the OpenROAD flow (about 30 s instead of a few minutes)
  python3 regression.py --llm        also check the models: Ollama + a one-line answer from every model
                                     whose API key is set (a few tokens)
  python3 regression.py --agent      also run a real agentic flow: Part 2, run 2b, design p11 (uses the API)
  python3 regression.py --all        everything

Every check prints PASS / FAIL / SKIP and the summary ends with the exit code: 0 = all good.
Logs of every step go to regression/logs/. Run it from anywhere inside the container:
  python3 /home/scripts/regression/regression.py
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPTS = HERE.parent
LOGS = HERE / "logs"
G, RD, Y, C, B, D, R = "\033[92m", "\033[91m", "\033[93m", "\033[96m", "\033[1m", "\033[2m", "\033[0m"

RESULTS = []          # (section, name, status, seconds, detail)


# ------------------------------------------------------------------------------------------- helpers
def run(cmd, cwd=None, timeout=600, env=None, log=None):
    """Run a command, return (returncode, output). The output is also written to logs/<log>.log."""
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=env, errors="replace")
        rc, out = p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired as e:
        partial = e.stdout or ""
        if isinstance(partial, bytes):
            partial = partial.decode(errors="replace")
        rc, out = 124, partial + f"\nTIMEOUT after {timeout} s"
    except FileNotFoundError as e:
        rc, out = 127, str(e)
    if log:
        (LOGS / f"{log}.log").write_text(f"$ {' '.join(map(str, cmd))}\n(cwd: {cwd or os.getcwd()})\n\n{out}")
    return rc, out


def check(section, name, fn):
    """fn() returns (status, detail) with status PASS/FAIL/SKIP, or raises."""
    t0 = time.time()
    try:
        status, detail = fn()
    except Exception as e:  # a crash of a check is a FAIL, not a crash of the regression
        status, detail = "FAIL", f"{type(e).__name__}: {e}"
    dt = time.time() - t0
    col = {"PASS": G, "FAIL": RD, "SKIP": Y}[status]
    print(f"  {col}{status:4}{R}  {name:44} {D}{dt:6.1f}s{R}  {detail}")
    RESULTS.append((section, name, status, dt, detail))
    return status == "PASS"


def section(title):
    print(f"\n{B}{C}{title}{R}")


def find_orfs():
    for c in [os.environ.get("ORFS_DIR"), "/home/OpenROAD-flow-scripts"]:
        if c and (Path(c) / "flow" / "Makefile").exists():
            return Path(c)
    if shutil.which("openroad"):
        for p in Path(shutil.which("openroad")).resolve().parents:
            if (p / "flow" / "Makefile").exists():
                return p
    return None


def last_line(text, pattern):
    hits = [l.strip() for l in text.splitlines() if re.search(pattern, l)]
    return hits[-1] if hits else ""


# ------------------------------------------------------------------------------------------- checks
def tools_checks():
    section("1. Tools and environment")
    tools = [("iverilog", ["iverilog", "-V"], r"Icarus Verilog version"),
             ("vvp", ["vvp", "-V"], r"Icarus Verilog runtime"),
             ("yosys", ["yosys", "-V"], r"Yosys"),
             ("openroad", ["openroad", "-version"], r"\S"),
             ("klayout", ["klayout", "-v"], r"KLayout"),
             ("make", ["make", "--version"], r"Make")]
    for name, cmd, pat in tools:
        def f(cmd=cmd, pat=pat, name=name):
            if not shutil.which(cmd[0]):
                return "FAIL", "not found in PATH"
            rc, out = run(cmd, timeout=60, log=f"tool_{name}")
            line = last_line(out, pat) or out.strip().splitlines()[0] if out.strip() else ""
            return ("PASS" if re.search(pat, out) else "FAIL"), line[:70]
        check("tools", name, f)

    def env_vars():
        bad = [v for v in ("OPENROAD_EXE", "YOSYS_EXE") if not (os.environ.get(v) and Path(os.environ[v]).exists())]
        if bad:
            return "FAIL", f"not set or wrong path: {', '.join(bad)}"
        return "PASS", f"OPENROAD_EXE, YOSYS_EXE ok"
    check("tools", "OPENROAD_EXE / YOSYS_EXE", env_vars)

    def orfs():
        o = find_orfs()
        if not o:
            return "FAIL", "OpenROAD-flow-scripts not found (set ORFS_DIR)"
        lib = o / "flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
        return ("PASS", str(o)) if lib.exists() else ("FAIL", f"{o}: sky130hd platform missing")
    check("tools", "OpenROAD-flow-scripts + sky130hd", orfs)

    def python_mods():
        missing = []
        for m in ("dspy", "yaml", "ollama"):
            rc, _ = run([sys.executable, "-c", f"import {m}"], timeout=120)
            if rc:
                missing.append(m)
        if missing:
            return "FAIL", "missing Python packages: " + ", ".join(missing)
        rc, out = run([sys.executable, "-c", "import dspy; print(dspy.__version__)"])
        return "PASS", f"dspy {out.strip()}, pyyaml, ollama"
    check("tools", "Python packages", python_mods)

    def keys():
        ks = {k: bool(os.environ.get(k)) for k in ("GEMINI_API_KEY", "ANTHROPIC_API_KEY")}
        txt = ", ".join(f"{k.split('_')[0].title()} {'set' if v else 'not set'}" for k, v in ks.items())
        return ("PASS" if any(ks.values()) else "SKIP"), txt + ("" if any(ks.values()) else "  (source scripts/api_keys.sh)")
    check("tools", "API keys", keys)


def script_checks():
    section("2. Tutorial scripts load")
    for label, folder, script in [("Part 2/3 flow", "part2/solution", "asic_autonomous_flow.py"),
                                  ("Part 4 flow", "part4/solution", "asic_orchestrated_flow.py")]:
        def f(folder=folder, script=script, label=label):
            cwd = SCRIPTS / folder
            if not (cwd / script).exists():
                return "FAIL", f"{folder}/{script} not found"
            rc, out = run([sys.executable, script, "--help"], cwd=cwd, timeout=180, log=f"help_{script}")
            if rc == 0 and "--design" in out:
                return "PASS", "imports and arguments ok"
            return "FAIL", (_tail(out) if rc else "unexpected --help output")
        check("scripts", label, f)


def eda_checks(quick):
    section("3. EDA tools on a known-good design (golden p11 counter, reference testbench)")
    ref = SCRIPTS / "reference"
    if not (ref / "check_designs.py").exists():
        check("eda", "reference designs", lambda: ("FAIL", "scripts/reference not found"))
        return

    def sim():
        rc, out = run([sys.executable, "check_designs.py", "-d", "p11", "-d", "p8", "--mutants"], cwd=ref, timeout=300, log="sim_p11_p8")
        ok = rc == 0 and "All designs consistent" in out
        return ("PASS" if ok else "FAIL"), ("RTL simulation, reference TBs, mutants caught" if ok else _tail(out))
    check("eda", "Icarus simulation (p11, p8)", sim)

    def synth():
        env = dict(os.environ)
        o = find_orfs()
        if o:
            env["ORFS_DIR"] = str(o)
        rc, out = run([sys.executable, "check_designs.py", "-d", "p11", "--synth", "--gls"], cwd=ref, timeout=600, env=env, log="synth_p11")
        ok = rc == 0 and "gate-level simulation passes" in out
        m = re.search(r"synthesis: (\d+) um\^2", out)
        return ("PASS" if ok else "FAIL"), (f"sky130hd netlist {m.group(1)} um^2, gate-level sim ok" if ok and m else _tail(out))
    check("eda", "Yosys synthesis + gate-level sim (p11)", synth)

    if quick:
        check("eda", "OpenROAD flow (p11)", lambda: ("SKIP", "--quick"))
        check("eda", "PPA evaluation (p11)", lambda: ("SKIP", "--quick"))
        return

    state = {}

    def flow():
        o = find_orfs()
        if not o:
            return "FAIL", "OpenROAD-flow-scripts not found"
        module = "simple_8bit_counter"
        flowdir = o / "flow"
        ddir = flowdir / "designs" / "sky130hd" / module
        sdir = flowdir / "designs" / "src" / module
        for d in (ddir, sdir):
            shutil.rmtree(d, ignore_errors=True)
            d.mkdir(parents=True)
        shutil.copy(ref / "p11" / f"{module}.v", sdir)
        shutil.copy(ref / "p11" / "constraint.sdc", ddir / "constraint.sdc")
        shutil.copy(ref / "p11" / "config.mk", ddir / "config.mk")
        cfg = ddir / "config.mk"
        run(["make", "clean_all", f"DESIGN_CONFIG={cfg}"], cwd=flowdir, timeout=300)
        rc, out = run(["make", f"DESIGN_CONFIG={cfg}"], cwd=flowdir, timeout=3600, log="openroad_flow_p11")
        res = flowdir / "results" / "sky130hd" / module / "base"
        state["res"] = res
        odb, gds = res / "6_final.odb", res / "6_final.gds"
        if rc or not odb.exists():
            return "FAIL", "flow failed: " + _tail(out)
        return "PASS", "6_final.odb" + (" + 6_final.gds (KLayout)" if gds.exists() else " (no GDS: check KLayout)")
    flow_ok = check("eda", "OpenROAD flow (p11, golden files)", flow)

    def evaluate():
        if not flow_ok:
            return "SKIP", "needs the OpenROAD flow"
        o = find_orfs()
        ev = SCRIPTS / "part2" / "evaluation"
        with tempfile.TemporaryDirectory() as tmp:
            rc, out = run([sys.executable, str(ev / "evaluate_openroad.py"), "--odb", str(state["res"] / "6_final.odb"),
                           "--sdc", str(state["res"] / "6_final.sdc"), "--flow_root", str(o), "--problem", "11"],
                          cwd=tmp, timeout=600, log="evaluate_p11")
        m = re.search(r"Final Score: ([\d.]+)", out)
        if not m:
            return "FAIL", "no score: " + _tail(out)
        score = float(m.group(1))
        # the golden layout IS the reference: about 75/100 (small differences between OpenROAD versions)
        return ("PASS" if 65 <= score <= 85 else "FAIL"), f"score {score:.1f}/100 (golden = reference: 75-80 expected)"
    check("eda", "PPA evaluation (p11)", evaluate)


def _tail(out, n=160):
    lines = [l for l in out.strip().splitlines() if l.strip()]
    return (lines[-1] if lines else "no output")[:n]


def llm_checks():
    section("4. Models (a one-line answer each, a few tokens)")
    import yaml

    def ollama():
        try:
            with urllib.request.urlopen("http://localhost:11434/api/tags", timeout=5) as r:
                tags = [m["name"] for m in json.load(r).get("models", [])]
        except Exception:
            return "FAIL", "Ollama server not reachable (start it: ollama serve &)"
        if not any(t.startswith("llama3.1") for t in tags):
            return "FAIL", f"llama3.1 not pulled (ollama pull llama3.1); have: {', '.join(tags) or 'none'}"
        return "PASS", "server up, llama3.1 present"
    ollama_ok = check("llm", "Ollama server + llama3.1", ollama)

    cfg = yaml.safe_load((SCRIPTS / "part2/solution/configs/single_agent/config.yaml").read_text())
    profiles = cfg.get("profiles", {})
    wanted = [("ollama-llama3.1", None), ("gemini_lite", "GEMINI_API_KEY"), ("claude-haiku-4-5", "ANTHROPIC_API_KEY")]
    for prof, key in wanted:
        def f(prof=prof, key=key):
            if prof not in profiles:
                return "SKIP", "profile not in configs"
            if key and not os.environ.get(key):
                return "SKIP", f"{key} not set"
            if prof.startswith("ollama") and not ollama_ok:
                return "SKIP", "Ollama not available"
            p = dict(profiles[prof])
            code = (
                "import dspy, os, json, sys\n"
                f"p = json.loads({json.dumps(json.dumps(p))})\n"
                "model = p.pop('model'); p = {k: v for k, v in p.items() if v not in ('', None)}\n"
                "if isinstance(p.get('api_key'), str) and p['api_key'].startswith('$'): p['api_key'] = os.environ.get(p['api_key'][1:], '')\n"
                "p['cache'] = False\n"
                "lm = dspy.LM(model, num_retries=3, **p)\n"
                "out = lm('Reply with exactly the word OK.')\n"
                "print('ANSWER:', (out[0] if isinstance(out[0], str) else out[0].get('text', '')).strip()[:40])\n")
            rc, out = run([sys.executable, "-c", code], timeout=300, log=f"llm_{prof}")
            ans = re.search(r"ANSWER: (.*)", out)
            if rc or not ans:
                err = re.findall(r"(\w+Error[^\n]{0,120})", out)
                return "FAIL", (err[-1] if err else _tail(out))
            return "PASS", f"{p.get('model', '') or profiles[prof]['model']}: \"{ans.group(1)}\""
        check("llm", f"model {prof}", f)


def agent_check():
    section("5. A real agentic flow (Part 2, run 2b, design p11)")

    def f():
        if not os.environ.get("GEMINI_API_KEY"):
            return "SKIP", "GEMINI_API_KEY not set (run 2b uses Gemini Flash Lite)"
        cwd = SCRIPTS / "part2" / "solution"
        rc, out = run([sys.executable, "asic_autonomous_flow.py", "--config", "run_configs/2b_multi_agent.yaml",
                       "--design", "p11.yaml"], cwd=cwd, timeout=3600, log="agent_2b_p11")
        text = re.sub(r"\x1b\[[0-9;]*m", "", out)
        score = re.findall(r"Final Score: ([\d.]+)", text)
        if "Agentic flow completed successfully" in text:
            return "PASS", "flow completed" + (f", score {float(score[-1]):.1f}" if score else "")
        return "FAIL", "agents did not finish (an environment problem only if the log shows tool errors): " + _tail(text)
    check("agent", "2b multi-agent flow on p11", f)


# ------------------------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--quick", action="store_true", help="skip the OpenROAD flow")
    ap.add_argument("--llm", action="store_true", help="also check the models (a few tokens)")
    ap.add_argument("--agent", action="store_true", help="also run a real agentic flow (Part 2, 2b, p11)")
    ap.add_argument("--all", action="store_true", help="--llm and --agent")
    a = ap.parse_args()
    LOGS.mkdir(exist_ok=True)

    import platform
    print(f"{B}VLSI-SoC tutorial environment regression{R}  {D}{platform.machine()} · {platform.platform()} · "
          f"Python {platform.python_version()}{R}")
    t0 = time.time()
    tools_checks()
    script_checks()
    eda_checks(a.quick)
    if a.llm or a.all:
        llm_checks()
    if a.agent or a.all:
        agent_check()

    n = {s: sum(1 for r in RESULTS if r[2] == s) for s in ("PASS", "FAIL", "SKIP")}
    print(f"\n{B}Summary:{R} {G}{n['PASS']} passed{R}, {RD if n['FAIL'] else ''}{n['FAIL']} failed{R}, "
          f"{Y}{n['SKIP']} skipped{R}   ({time.time() - t0:.0f} s, logs in {LOGS})")
    fails = [r for r in RESULTS if r[2] == "FAIL"]
    for sec, name, _, _, detail in fails:
        print(f"  {RD}✗ {name}{R}: {detail}")
    if not fails:
        print(f"{G}{B}The environment is ready for the tutorial.{R}" if not a.quick else
              f"{G}{B}Quick check passed. Run without --quick once to test the full OpenROAD flow.{R}")
    (LOGS / "summary.json").write_text(json.dumps(
        [{"section": s, "check": c, "status": st, "seconds": round(dt, 1), "detail": d} for s, c, st, dt, d in RESULTS], indent=2))
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
