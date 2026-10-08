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
Every recording uses a FRESH DSPy cache, so the models really answer and the tokens are real
(--use-cache reuses your normal cache instead). A rescue should be a run that works: --tries 3
re-runs a failed entry up to 3 times and keeps the first success (all attempts are kept as <id>.tryN).
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
        collect, aside = [], []
        if e.get("design"):
            collect.append((cwd / e["design"] / "golden.tb", "golden.tb"))
            aside.append(cwd / e["design"] / "golden.tb")   # the scripts skip everything when it exists
        return cwd, cmd, collect, [], aside

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
    return cwd, cmd, collect, clean, []


def record(cmd, cwd, out_dir, use_cache=False):
    env = dict(os.environ, PYTHONUNBUFFERED="1")
    cache_dir = None
    if not use_cache:   # a fresh, empty DSPy cache: every answer comes from the model, tokens are real
        cache_dir = tempfile.mkdtemp(prefix="dspy_cache_rescue_")
        env["DSPY_CACHEDIR"] = cache_dir
    t0 = time.time()
    with open(out_dir / "console.log", "w") as log, open(out_dir / "console.timing", "w") as tim:
        p = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                             bufsize=1, env=env, errors="replace")
        for line in p.stdout:
            sys.stdout.write(line)
            log.write(line)
            tim.write(f"{time.time() - t0:.3f}\n")
        p.wait()
    if cache_dir:
        shutil.rmtree(cache_dir, ignore_errors=True)
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
    if re.search(r"❌ Failure!|Reached max iterations|no orchestrator interventions left|Traceback \(most recent", text):
        info["status"] = "failed"
    elif re.search(r"Agentic flow completed successfully|The team reached a scored layout|"
                   r"SUCCESS! Exactly 1 mutant isolated", text):
        info["status"] = "success"
    if "(cached)" in text:
        info["cached_answers"] = len(re.findall(r"\(cached\)", text))
    return info


def git_commit():
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=SCRIPTS, capture_output=True, text=True).stdout.strip()
    except OSError:
        return ""


def record_once(e, a, out):
    cwd, cmd, collect, clean, aside = plan(e)
    if out.exists():
        shutil.rmtree(out)
    (out / "files").mkdir(parents=True)
    if not a.no_clean:
        for c in clean:
            if c.exists():
                shutil.rmtree(c)
    moved = []
    for f in aside:
        if f.exists():
            bak = f.with_name(f.name + ".rescue_bak")
            f.replace(bak)
            moved.append((f, bak))
    try:
        rc, secs = record(cmd, cwd, out, use_cache=a.use_cache)
    finally:
        for f, bak in moved:          # put the old file back if the run did not write a new one
            if f.exists():
                bak.unlink()
            else:
                bak.replace(f)
    for src, name in collect:
        if src.is_dir():
            shutil.copytree(src, out / "files" / name, dirs_exist_ok=True)
        elif src.exists():
            shutil.copy(src, out / "files" / name)
    meta = {"id": out.name, "entry": e, "cwd": str(cwd.relative_to(SCRIPTS)), "command": cmd,
            "recorded": datetime.now().isoformat(timespec="seconds"), "duration_s": round(secs, 1),
            "exit_code": rc, "git_commit": git_commit(), "fresh_cache": not a.use_cache}
    meta.update(summarize((out / "console.log").read_text(errors="replace")))
    (out / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    return meta


def do_entry(e, a):
    rid = entry_id(e)
    cwd, cmd, *_ = plan(e)
    out = RUNS / rid
    meta = None
    for t in range(1, a.tries + 1):
        tag = f" (try {t}/{a.tries})" if a.tries > 1 else ""
        print(f"\n{B}{C}=== Recording {rid}{tag} ==={R}\n{B}cd {cwd.relative_to(SCRIPTS.parent)} && {' '.join(cmd)}{R}\n")
        meta = record_once(e, a, out)
        ok = meta["exit_code"] == 0 and meta.get("status") != "failed"
        col = G if ok else RD
        print(f"\n{col}{B}Recorded {rid}: exit {meta['exit_code']}, {meta['duration_s']:.0f}s, "
              f"status {meta.get('status', '?')}{R}  -> rescue/runs/{rid}/")
        if meta.get("cached_answers"):
            print(f"{Y}Warning: {meta['cached_answers']} answers came from a cache: the token counts of this recording are not real.{R}")
        if ok or t == a.tries:
            break
        keep = RUNS / f"{rid}.try{t}"          # keep the failed attempt, try again
        if keep.exists():
            shutil.rmtree(keep)
        out.rename(keep)
        print(f"{Y}Failed: kept as rescue/runs/{keep.name}, trying again ...{R}")
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
    ap.add_argument("--tries", type=int, default=1, help="re-run a failed entry up to N times, keep the first success")
    ap.add_argument("--only-failed", action="store_true", help="with --preset: re-record only the runs whose recording failed")
    ap.add_argument("--use-cache", action="store_true", help="use your normal DSPy cache (faster, but cached answers count 0 tokens)")
    a = ap.parse_args()

    presets = yaml.safe_load((HERE / "presets.yaml").read_text())
    if a.list:
        for name, entries in presets.items():
            print(f"{B}{name}{R}: " + ", ".join(entry_id(e) for e in entries))
        rec = sorted(p.name for p in RUNS.glob("*") if (p / "meta.json").exists() and ".try" not in p.name) if RUNS.exists() else []
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
        mf = RUNS / entry_id(e) / "meta.json"
        if a.skip_existing and mf.exists():
            print(f"{Y}{entry_id(e)}: already recorded, skipped{R}")
            continue
        if a.only_failed and mf.exists():
            old = json.loads(mf.read_text())
            con = mf.parent / "console.log"     # re-read the console: older recordings have no status
            old.update(summarize(con.read_text(errors="replace")) if con.exists() else {"status": "failed"})
            if old["exit_code"] == 0 and old.get("status") != "failed" and not old.get("cached_answers"):
                print(f"{Y}{entry_id(e)}: already recorded and OK, skipped{R}")
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
