#!/usr/bin/env python3
"""
Record "rescue" runs before the tutorial: if a live run fails on the day (Wi-Fi, API quota, a slow
laptop), you show the recorded one instead - or replay it on the console as if it were live.

Each run is executed from the part's solution/ folder (the golden prompts), its console output is
recorded line by line WITH timing, and its results are copied to rescue/runs/<id>/:
    console.log      the console output (colours kept)
    console.timing   seconds since the start, one line per console line (for show_rescue.py replay)
    meta.json        command, date, duration, exit code, status, score, tokens
    files/           the outputs of the run (log, token_usage.json, final RTL/TB/SDC/config.mk, layout)

  python3 make_rescue.py --preset tutorial                       # everything in presets.yaml: tutorial
  python3 make_rescue.py --preset quick
  python3 make_rescue.py --part 2 --run 2b_multi_agent --design p1.yaml
  python3 make_rescue.py --part 1 --task google_iterative --design enc_bin2gray
  python3 make_rescue.py --list                                  # presets and recorded runs

Run it in the Docker container (or a local install) with your API keys loaded, from scripts/rescue/.
Previous results of the same run+design are removed first (they are regenerated); --no-clean keeps them.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
SCRIPTS = HERE.parent
RUNS = HERE / "runs"
G, RD, Y, B, C, R = "\033[92m", "\033[91m", "\033[93m", "\033[1m", "\033[96m", "\033[0m"
ANSI = re.compile(r"\x1b\[[0-9;]*m")

PART1 = {
    "sentiment":        ("part1/sentiment_analysis", ["python3", "main.py"]),
    "google_single":    ("part1/google_verification", ["python3", "single_pass.py"]),
    "google_iterative": ("part1/google_verification", ["python3", "iterative.py"]),
}
FLOW = {2: "asic_autonomous_flow.py", 3: "asic_autonomous_flow.py", 4: "asic_orchestrated_flow.py"}


def die(msg):
    print(f"{RD}Error: {msg}{R}")
    sys.exit(2)


def entry_id(e):
    if e["part"] == 1:
        return "part1-" + e["task"] + (f"-{e['design']}" if e.get("design") else "")
    return f"part{e['part']}-{e['run']}-{Path(e['design']).stem}" + ("-problem" if e.get("variant") == "problem" else "")


def plan(e):
    """(cwd, command, list of (source, destination name) to collect after the run, paths to clean before)."""
    variant = e.get("variant", "solution")
    if e["part"] == 1:
        if e["task"] not in PART1:
            die(f"unknown part 1 task {e['task']} (use {', '.join(PART1)})")
        folder, cmd = PART1[e["task"]]
        cwd = SCRIPTS / folder / variant
        cmd = cmd + ([e["design"]] if e.get("design") else [])
        collect = []
        if e.get("design"):
            collect.append((cwd / e["design"] / "golden.tb", "golden.tb"))
        return cwd, cmd, collect, []

    part, run, design = e["part"], e["run"], e["design"]
    cwd = SCRIPTS / f"part{part}" / variant
    cfg_file = cwd / "run_configs" / f"{run}.yaml"
    if not cfg_file.exists():
        die(f"{cfg_file} not found")
    cfg = yaml.safe_load(cfg_file.read_text())
    paths = cfg.get("paths", {})
    stem = Path(design).stem
    cmd = ["python3", FLOW[part], "--config", f"run_configs/{run}.yaml", "--design", design] + e.get("extra_args", [])
    if part in (2, 3):
        log = cwd / paths["log_file"]
        res = cwd / paths["results_dir"] / stem
        sol = cwd / paths["solutions_dir"] / stem
        collect = [(log, log.name), (log.parent / "token_usage.json", "token_usage.json"), (res, "results"), (sol, "solution")]
        clean = [res, sol]
    else:
        rd = cwd / paths["run_dir"] / stem
        collect = [(rd, "run")]
        clean = [rd]
    return cwd, cmd, collect, clean


def record(cmd, cwd, out_dir):
    env = dict(os.environ, PYTHONUNBUFFERED="1")
    t0 = time.time()
    with open(out_dir / "console.log", "w") as log, open(out_dir / "console.timing", "w") as tim:
        p = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                             bufsize=1, env=env, errors="replace")
        for line in p.stdout:
            sys.stdout.write(line)
            log.write(line)
            tim.write(f"{time.time() - t0:.3f}\n")
        p.wait()
    return p.returncode, time.time() - t0


def summarize(console):
    text = ANSI.sub("", console)
    info = {}
    scores = re.findall(r"Final Score: ([\d.]+)", text)
    if scores:
        info["score"] = float(scores[-1])
    acc = re.findall(r"DSPy Compiled Accuracy:\s+([\d.]+)%", text)
    if acc:
        info["compiled_accuracy"] = float(acc[-1])
    m = re.findall(r"Mutants Passed:\s+(\d+)|Exactly 1 mutant isolated in (\d+)", text)
    if m:
        info["mutant_result"] = [x for x in m[-1] if x][0]
    tot = re.findall(r"^TOTAL\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)", text, re.M)
    if tot:
        info["tokens_total"] = int(tot[-1][3])
    st = re.findall(r"SCRIPT TOTAL:\s+(\d+) tokens", text)
    if st:
        info["tokens_total"] = int(st[-1])
    # final verdict lines of the flows (intermediate "Success!" lines of single steps do not count)
    if re.search(r"❌ Failure!", text):
        info["status"] = "failed"
    elif re.search(r"Agentic flow completed successfully|The team reached a scored layout|"
                   r"SUCCESS! Exactly 1 mutant isolated", text):
        info["status"] = "success"
    return info


def git_commit():
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=SCRIPTS, capture_output=True, text=True).stdout.strip()
    except OSError:
        return ""


def do_entry(e, a):
    rid = entry_id(e)
    cwd, cmd, collect, clean = plan(e)
    out = RUNS / rid
    print(f"\n{B}{C}=== Recording {rid} ==={R}\n{B}cd {cwd.relative_to(SCRIPTS.parent)} && {' '.join(cmd)}{R}\n")
    if out.exists():
        shutil.rmtree(out)
    (out / "files").mkdir(parents=True)
    if not a.no_clean:
        for c in clean:
            if c.exists():
                shutil.rmtree(c)
    rc, secs = record(cmd, cwd, out)
    for src, name in collect:
        if src.is_dir():
            shutil.copytree(src, out / "files" / name, dirs_exist_ok=True)
        elif src.exists():
            shutil.copy(src, out / "files" / name)
    meta = {"id": rid, "entry": e, "cwd": str(cwd.relative_to(SCRIPTS)), "command": cmd,
            "recorded": datetime.now().isoformat(timespec="seconds"), "duration_s": round(secs, 1),
            "exit_code": rc, "git_commit": git_commit()}
    meta.update(summarize((out / "console.log").read_text(errors="replace")))
    (out / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    col = G if rc == 0 else RD
    print(f"\n{col}{B}Recorded {rid}: exit {rc}, {secs:.0f}s{R}  -> rescue/runs/{rid}/")
    return meta


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--preset", help="record every entry of this preset (presets.yaml)")
    ap.add_argument("--part", type=int, choices=[1, 2, 3, 4])
    ap.add_argument("--run", help="parts 2-4: run config name, e.g. 2b_multi_agent")
    ap.add_argument("--task", help="part 1: sentiment | google_single | google_iterative")
    ap.add_argument("--design", help="parts 2-4: pN.yaml; part 1 Google: the design folder")
    ap.add_argument("--variant", choices=["solution", "problem"], default="solution")
    ap.add_argument("--no-clean", action="store_true", help="keep previous results of the same run and design")
    ap.add_argument("--list", action="store_true", help="show the presets and the recorded runs")
    ap.add_argument("--skip-existing", action="store_true", help="with --preset: do not re-record runs already recorded")
    a = ap.parse_args()

    presets = yaml.safe_load((HERE / "presets.yaml").read_text())
    if a.list:
        for name, entries in presets.items():
            print(f"{B}{name}{R}: " + ", ".join(entry_id(e) for e in entries))
        rec = sorted(p.name for p in RUNS.glob("*") if (p / "meta.json").exists()) if RUNS.exists() else []
        print(f"\n{B}Recorded:{R} " + (", ".join(rec) if rec else "none yet"))
        return

    if a.preset:
        if a.preset not in presets:
            die(f"no preset '{a.preset}' in presets.yaml ({', '.join(presets)})")
        entries = presets[a.preset]
    elif a.part:
        e = {"part": a.part, "variant": a.variant}
        if a.part == 1:
            if not a.task:
                die("--part 1 needs --task")
            e["task"] = a.task
            if a.design:
                e["design"] = a.design
        else:
            if not (a.run and a.design):
                die("parts 2-4 need --run and --design")
            e.update(run=a.run, design=a.design)
        entries = [e]
    else:
        ap.print_help()
        return

    results = []
    for e in entries:
        if a.skip_existing and (RUNS / entry_id(e) / "meta.json").exists():
            print(f"{Y}{entry_id(e)}: already recorded, skipped{R}")
            continue
        try:
            results.append(do_entry(e, a))
        except KeyboardInterrupt:
            print(f"\n{Y}Interrupted: {entry_id(e)} is incomplete.{R}")
            break

    if results:
        print(f"\n{B}{'run':55} {'exit':>4} {'time':>7}  status / score{R}")
        for m in results:
            extra = " ".join(f"{k}={m[k]}" for k in ("status", "score", "compiled_accuracy", "mutant_result", "tokens_total") if k in m)
            print(f"{m['id']:55} {m['exit_code']:>4} {m['duration_s']:>6.0f}s  {extra}")
        print(f"\nShow or replay them with:  python3 show_rescue.py list")


if __name__ == "__main__":
    main()
