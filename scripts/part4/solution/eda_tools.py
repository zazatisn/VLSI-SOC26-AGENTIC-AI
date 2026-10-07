########################################################################
# EDA tools of the Part 4 orchestrated flow.                           #
#                                                                      #
# The same checks as Parts 2 and 3 (Icarus Verilog, Yosys, ORFS and    #
# the PPA evaluation), written as plain functions so the orchestrator  #
# can call them for any subtask. Every check returns (ok, report).     #
########################################################################

import re
import shutil
import subprocess
import tempfile
import threading
import time
from pathlib import Path

ANSI = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")

# --- Cleaning the LM outputs ---

def strip_fences(raw: str) -> str:
    """Remove a markdown code fence around the LM output."""

    raw = re.sub(r"^```\w*\n", "", (raw or "").strip())
    return re.sub(r"\n```$", "", raw.strip()).strip()

def clean_verilog(raw: str, fix_rtl: bool = False) -> str:
    """Extract module...endmodule, remove stray backticks and set the timescale."""

    raw = strip_fences(raw)
    m = re.search(r"(module\s+\w+.*?endmodule)", raw, re.DOTALL)
    code = m.group(1).strip() if m else raw.strip()

    # Stray backticks (` // comment) -> // comment. Keep the real directives.
    code = re.sub(r"`(?!(define|include|timescale|ifdef|ifndef|endif|else|undef)\b)", "", code)

    if fix_rtl:
        # Module names cannot start with a digit
        code = re.sub(r"\bmodule\s+(\d\S*)", lambda mm: f"module top_{mm.group(1)}", code)
        # Signals driven by 'assign' must be wires
        for name in re.findall(r"\bassign\s+(\w+)", code):
            code = re.sub(rf"\breg\b(\s+(?:\[[\w\s:]+\]\s+)?){re.escape(name)}\b", rf"wire\1{name}", code)
            code = re.sub(rf"\boutput\s+reg\b(\s+(?:\[[\w\s:]+\]\s+)?){re.escape(name)}\b",
                          rf"output wire\1{name}", code)

    code = re.sub(r"`timescale\s+.*?\n", "", code).strip()
    return "`timescale 1ns/1ps\n\n" + code

def save_file(directory: Path, filename: str, content: str) -> Path:
    Path(directory).mkdir(parents=True, exist_ok=True)
    path = Path(directory) / filename
    path.write_text(content)
    return path

# --- Testbench ---

def check_testbench(tb_path: Path, module_signature: str) -> tuple[bool, str]:
    """Compile the testbench with an empty stub of the DUT, and check it prints PASS/FAIL."""

    with tempfile.TemporaryDirectory() as tmp:
        stub = Path(tmp) / "stub.v"
        stub.write_text(f"`timescale 1ns/1ps\n{module_signature}\nendmodule")
        proc = subprocess.run(["iverilog", "-Wall", "-g2005", "-o", str(Path(tmp) / "tb.out"), str(tb_path), str(stub)],
                              capture_output=True, text=True)
    output = (proc.stdout + proc.stderr).strip()
    if proc.returncode != 0 or output:
        return False, f"Testbench compilation errors/warnings (iverilog):\n{output}"
    if "PASS" not in Path(tb_path).read_text():
        return False, ("The testbench compiles, but it never prints PASS. Every check must print "
                       "PASS or FAIL: the flow decides the result from these words.")
    return True, "Testbench compiles with the DUT signature and prints PASS/FAIL."

def sim_passed(log: str) -> bool:
    upper = log.upper()
    return "PASS" in upper and "FAIL" not in upper and "TIMED OUT" not in upper

def run_simulation(tb_path: Path, design_path: Path, mode: str = "rtl", pdk_path: Path = None, timeout: int = 10) -> str:
    """RTL ('rtl') or gate-level ('post_synth') simulation with iverilog + vvp. Returns the log."""

    with tempfile.TemporaryDirectory() as tmp:
        exe = str(Path(tmp) / f"sim_{mode}.out")
        if mode == "rtl":
            cmd = ["iverilog", "-Wall", "-g2005", "-o", exe, str(design_path), str(tb_path)]
        else:
            cells = sorted(Path(pdk_path).glob("*.v"))
            cmd = ["iverilog", "-Wall", "-Wno-timescale", "-g2005", "-o", exe, *map(str, cells), str(design_path), str(tb_path)]

        comp = subprocess.run(cmd, capture_output=True, text=True)
        out = comp.stdout + comp.stderr
        if comp.returncode != 0:
            return f"{mode.upper()} compilation failed:\n{out}"
        logs = [f"Compilation succeeded with warnings:\n{out}\n" if out.strip() else "Compilation succeeded.\n"]

        proc = subprocess.Popen(["vvp", exe], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)

        def reader():
            for line in iter(proc.stdout.readline, ""):
                logs.append(line)
            proc.stdout.close()

        t = threading.Thread(target=reader, daemon=True)
        t.start()
        t.join(timeout=timeout)
        if t.is_alive():
            proc.kill(); proc.wait(); t.join()
            logs.append(f"Simulation timed out after {timeout} seconds.\n")
        else:
            proc.wait()
    return "".join(logs)

# --- SDC ---

def verify_sdc_structure(template: str, generated: str) -> list[str]:
    """Lines of the template that are missing/modified, and extra lines not in the template."""

    static = [l.strip() for l in re.sub(r"<[^>]+>", "", template).splitlines() if l.strip()]
    lines = [l.strip() for l in generated.splitlines() if l.strip()]
    issues = [f"Missing or modified template line: '{t}'" for t in static if not any(t in g for g in lines)]
    for g in lines:
        covered = any(t in g or g in t for t in static)
        if not covered:
            for raw in template.splitlines():
                prefix = re.split(r"<[^>]+>", raw.strip())[0].strip()
                if raw.strip() and prefix and g.startswith(prefix):
                    covered = True
                    break
        if not covered:
            issues.append(f"Extra line not in template: '{g}'")
    return issues

def check_sdc(sdc: str, seq_template: str, comb_template: str) -> tuple[bool, str]:
    template = seq_template if "create_clock" in sdc else comb_template
    issues = verify_sdc_structure(template, sdc)
    placeholders = re.findall(r"<[A-Z_]+>", sdc)
    if placeholders:
        issues.append(f"Unfilled placeholders: {placeholders}")
    if issues:
        return False, "SDC check failed:\n" + "\n".join(issues)
    return True, f"SDC matches the {'sequential' if template is seq_template else 'combinational'} template."

# --- Synthesis ---

def run_yosys(orfs_dir: Path, design_config: Path) -> tuple[str, int]:
    proc = subprocess.run(["make", "synth", f"DESIGN_CONFIG={design_config}"], cwd=Path(orfs_dir) / "flow",
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return proc.stdout, proc.returncode

def extract_yosys_issues(log: str) -> str:
    issues = []
    if re.search(r"Number of cells:\s+0\b", log):
        issues += ["--- ZERO CELLS INFERRED ---",
                   "Yosys removed the whole design (0 cells): usually a multi-driver conflict "
                   "(the same signal assigned in several always blocks / assign statements)."]
    for title, pat in [("INFERRED LATCHES", r"Latch inferred for signal.*"),
                       ("MULTI-DRIVER CONFLICTS", r"Warning: Driver-driver conflict.*"),
                       ("NON-SYNTHESIZABLE CONSTRUCTS", r"Warning: Ignoring call.*"),
                       ("FATAL SYNTAX/PARSING ERRORS", r".*ERROR:.*")]:
        found = re.findall(pat, log)
        if found:
            issues += [f"--- {title} ---", *[f.strip() for f in found]]
    return "\n".join(issues)

# --- OpenROAD ---

def run_openroad_flow(orfs_dir: Path, design_config: Path) -> tuple[str, int]:
    flow_dir = Path(orfs_dir) / "flow"
    subprocess.run(["make", "clean_all", f"DESIGN_CONFIG={design_config}"], cwd=flow_dir,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    start = time.time()
    proc = subprocess.run(["make", f"DESIGN_CONFIG={design_config}"], cwd=flow_dir,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(f"⏱️  OpenROAD flow execution time: {time.time() - start:.2f} seconds")
    return proc.stdout, proc.returncode

def extract_orfs_issues(log: str, context: int = 3) -> str:
    lines = log.splitlines()
    picked, issues = set(), []
    idx = [i for i, l in enumerate(lines) if re.search(r"error", l, re.I) and "***" not in l]
    title = "--- LOGGED ERRORS ---"
    if not idx:
        idx = [i for i, l in enumerate(lines) if "***" in l]
        title = "--- MAKEFILE / FATAL ERRORS ---"
    if idx:
        issues.append(title)
        for i in idx:
            for j in range(max(0, i - context), min(len(lines), i + context + 1)):
                if j not in picked:
                    issues.append(lines[j].strip()); picked.add(j)
        for l in lines:
            m = re.search(r"(Design area\s+[\d\.]+\s+u\^2)", l, re.I)
            if m:
                issues += ["--- DESIGN AREA ---", m.group(1)]
                break
    return "\n".join(issues)

def run_evaluation(evaluation_dir: Path, results_dir: Path, orfs_dir: Path, problem_number: str) -> tuple[str, int]:
    cmd = ["python3", "-u", str(Path(evaluation_dir) / "evaluate_openroad.py"),
           "--odb", str(Path(results_dir) / "6_final.odb"), "--sdc", str(Path(results_dir) / "6_final.sdc"),
           "--flow_root", str(orfs_dir), "--problem", problem_number]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return proc.stdout, proc.returncode

def parse_score(eval_log: str) -> tuple[float, float]:
    """(score, wns). wns is None when not reported."""

    s = re.search(r"Final Score: ([\d\.]+)", eval_log)
    w = re.search(r"wns max\s+(-?[\d\.]+)", eval_log)
    return (float(s.group(1)) if s else 0.0), (float(w.group(1)) if w else None)

def generate_orfs_project(module_id: str, orfs_dir: Path, platform: str, config_template: Path) -> tuple[Path, Path, Path]:
    """Create the ORFS design folders and a default config.mk (used for synthesis)."""

    root = Path(orfs_dir) / "flow"
    design_dir = root / "designs" / platform / module_id
    src_dir = root / "designs" / "src" / module_id
    results_dir = root / "results" / platform / module_id
    design_dir.mkdir(parents=True, exist_ok=True)
    src_dir.mkdir(parents=True, exist_ok=True)
    results_dir.parent.mkdir(parents=True, exist_ok=True)

    defaults = {"<DESIGN_NAME>": module_id, "<PLATFORM>": platform, "<UTILIZATION_PERCENTAGE>": "50",
                "<ASPECT_RATIO_FLOAT>": "1.0", "<CORE_MARGIN_FLOAT>": "1.0", "<PLACEMENT_DENSITY_FLOAT>": "0.6",
                "<ROUTING_LAYER_ADJUSTMENT_FLOAT>": "0.5", "<ABC_AREA_0_OR_1>": "0",
                "<RESYNTH_TIMING_RECOVER_0_OR_1>": "0", "<RECOVER_POWER_PERCENTAGE>": "0"}
    text = Path(config_template).read_text()
    for tag, value in defaults.items():
        text = text.replace(tag, value)
    (design_dir / "config.mk").write_text(text)
    return design_dir, src_dir, results_dir / "base"

def strip_ansi(text: str) -> str:
    return ANSI.sub("", text)

def which_missing(tools=("iverilog", "vvp", "yosys", "openroad")) -> list[str]:
    return [t for t in tools if shutil.which(t) is None]
