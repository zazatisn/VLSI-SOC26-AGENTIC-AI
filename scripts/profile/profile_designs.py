#!/usr/bin/env python3
"""
Profile the designs: how long every design takes, where the time goes (LLM vs EDA tools),
how many tokens it costs and how often it succeeds. Results go to scripts/profile/results/.

Three measurements, run them inside the Docker container (or a local install) from scripts/profile/:

  1. EDA only - no LLM, no API cost. The golden design of every pN through the same tools the flows use:
     reference simulation (check_designs.py), the full OpenROAD flow with the golden config.mk, and the
     PPA measurement. Gives the pure tool time per design (a lower bound for every agent run).

       python3 profile_designs.py eda                     # every design, 3 repeats
       python3 profile_designs.py eda -d p11 -d p8 -r 5

  2. Agent runs - the real flows (solution prompts), every run config x design x repeat, each with a
     fresh DSPy cache so every answer really comes from the model. Resumable: finished runs are skipped.

       python3 profile_designs.py agent --runs 2b_multi_agent -d p11 -r 3
       python3 profile_designs.py agent --runs 2a_single_agent,2b_multi_agent,3_multi_agent_collaboration,4a_orchestrator_claude -r 5
       python3 profile_designs.py agent ... --dry-run     # show the plan and the time estimate only

  3. Report - mean / median / std per design and run, LLM vs EDA split, success rate, tokens,
     and an estimate of how long a full experiment matrix takes.

       python3 profile_designs.py report
       python3 profile_designs.py harvest                # also import the runs already in the repo
                                                         # (rescue recordings, runs/ folders)

Run configs: 2a_single_agent 2b_multi_agent 2c_multi_agent_mixed_models 2d_multi_agent_mixed_models_validators
(Part 2), 3_multi_agent_collaboration (Part 3), 4a_orchestrator_claude 4b_orchestrator_gemini (Part 4).
Do not run two runs of the SAME design at the same time: they share the ORFS design folder.
"""
import argparse
import csv
import json
import os
import re
import shutil
import statistics as st
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPTS = HERE.parent
OUT = HERE / "results"
EDA_CSV = OUT / "eda_runs.csv"
AGENT_CSV = OUT / "agent_runs.csv"
G, RD, Y, B, C, R = "\033[92m", "\033[91m", "\033[93m", "\033[1m", "\033[96m", "\033[0m"
ANSI = re.compile(r"\x1b\[[0-9;]*m")

sys.path.insert(0, str(SCRIPTS / "rescue"))
sys.path.insert(0, str(SCRIPTS / "reference"))

DESIGN_ORDER = ["p11", "p12", "p1", "p15", "p13", "p14", "p16", "p5", "p7", "p9", "p8"]
EDA_FIELDS = ["date", "design", "module", "repeat", "cells", "sim_s", "sim_ok", "orfs_s", "orfs_steps_s",
              "orfs_ok", "metrics_s", "total_s", "orfs_stage_s"]
AGENT_FIELDS = ["date", "source", "run", "part", "design", "repeat", "status", "exit_code", "wall_s", "llm_s",
                "eda_s", "orfs_s", "orfs_runs", "orfs_full_runs", "rtl_iters", "tokens", "prompt_tokens",
                "completion_tokens", "llm_calls", "cached_calls", "score", "models", "per_agent_tokens", "out_dir"]


# ----------------------------------------------------------------------------- helpers
def designs_all():
    found = sorted(p.stem for p in (SCRIPTS / "part2" / "designs").glob("p*.yaml"))
    return [d for d in DESIGN_ORDER if d in found] + [d for d in found if d not in DESIGN_ORDER]


def norm_design(d):
    return Path(d).stem


def part_of(run):
    if not run[:1].isdigit() or run[0] not in "234":
        sys.exit(f"{RD}unknown run config {run}: it must start with 2, 3 or 4{R}")
    return int(run[0])


def elapsed_s(text):
    """Sum of the 'Elapsed time' lines ORFS prints after every step, and the number of steps."""
    tot, n = 0.0, 0
    for h, m, s in re.findall(r"Elapsed time: (?:(\d+):)?(\d+):(\d+(?:\.\d+)?)\[h:\]min:sec", text):
        tot += int(h or 0) * 3600 + int(m) * 60 + float(s)
        n += 1
    return tot, n


def orfs_stages(text):
    """Seconds per ORFS stage (synth, floorplan, place, cts, route, finish) from the step logs."""
    stages = {}
    cur = "other"
    for line in text.splitlines():
        m = re.search(r"\b([1-6])_(\d+)?_?([a-z_]+)\b", line)
        if m and ("Running" in line or line.lstrip().startswith(("(", "[")) or "log" in line):
            cur = {"1": "synth", "2": "floorplan", "3": "place", "4": "cts", "5": "route", "6": "finish"}[m.group(1)]
        e = re.search(r"Elapsed time: (?:(\d+):)?(\d+):(\d+(?:\.\d+)?)\[h:\]min:sec", line)
        if e:
            h, mi, s = e.groups()
            stages[cur] = round(stages.get(cur, 0) + int(h or 0) * 3600 + int(mi) * 60 + float(s), 2)
    return stages


def read_csv(path):
    if not path.exists():
        return []
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def append_csv(path, fields, row):
    OUT.mkdir(parents=True, exist_ok=True)
    new = not path.exists()
    with open(path, "a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        if new:
            w.writeheader()
        w.writerow({k: row.get(k, "") for k in fields})


def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def fmt_s(x):
    if x is None:
        return "-"
    return f"{x:.0f}s" if x < 120 else f"{x / 60:.1f}m"


def stats(vals):
    v = [x for x in vals if x is not None]
    if not v:
        return None, None, None, 0
    return st.mean(v), st.median(v), (st.stdev(v) if len(v) > 1 else 0.0), len(v)


# ----------------------------------------------------------------------------- 1. EDA only
def cmd_eda(a):
    import yaml
    import make_reference as mr

    orfs = mr.find_orfs(a.orfs_dir)
    for t in ("make", "yosys", "iverilog"):
        if not shutil.which(t):
            sys.exit(f"{RD}{t} not found in PATH: run inside the container{R}")
    designs = a.design or designs_all()
    print(f"{B}EDA profile: {', '.join(designs)} x {a.repeats} repeats  (ORFS {orfs}){R}\n")
    for pid in designs:
        ref = SCRIPTS / "reference" / pid
        spec = yaml.safe_load((SCRIPTS / "part2/designs" / f"{pid}.yaml").read_text())
        module = list(spec)[0]
        golden = sorted(ref.glob("*.v"))
        cells = ""
        ref_json = SCRIPTS / "part2/evaluation/visible" / pid / f"{pid}.json"
        if ref_json.exists():
            cells = json.loads(ref_json.read_text()).get("design__instance__count__stdcell", "")
        for k in range(1, a.repeats + 1):
            work = Path(tempfile.mkdtemp(prefix=f"prof_{pid}_"))
            t0 = time.time()
            p = subprocess.run([sys.executable, "check_designs.py", "-d", pid], cwd=SCRIPTS / "reference",
                               capture_output=True, text=True)
            sim_s = time.time() - t0
            sim_ok = p.returncode == 0
            ok, results, orfs_s = mr.run_flow(orfs, module, golden, ref / "constraint.sdc",
                                              (ref / "config.mk").read_text(), work / "orfs.log")
            text = (work / "orfs.log").read_text(errors="replace")
            steps_s, _ = elapsed_s(text)
            t1 = time.time()
            metrics = mr.measure(orfs, results, work / f"{pid}.json") if ok else None
            metrics_s = time.time() - t1
            row = dict(date=datetime.now().isoformat(timespec="seconds"), design=pid, module=module, repeat=k,
                       cells=cells, sim_s=round(sim_s, 1), sim_ok=sim_ok, orfs_s=round(orfs_s, 1),
                       orfs_steps_s=round(steps_s, 1), orfs_ok=ok, metrics_s=round(metrics_s, 1),
                       total_s=round(sim_s + orfs_s + metrics_s, 1), orfs_stage_s=json.dumps(orfs_stages(text)))
            append_csv(EDA_CSV, EDA_FIELDS, row)
            col = G if ok and sim_ok else RD
            print(f"{col}{pid:4} #{k}  sim {sim_s:5.1f}s  OpenROAD {orfs_s:6.1f}s  metrics {metrics_s:4.1f}s"
                  f"  {'OK' if ok and sim_ok else 'FAILED'}{R}")
            shutil.rmtree(work, ignore_errors=True)
    print(f"\nSaved to {EDA_CSV.relative_to(SCRIPTS.parent)}. Next: python3 profile_designs.py report")


# ----------------------------------------------------------------------------- 2. agent runs
def collect_metrics(out_dir, console_text):
    """Everything we measure from one finished run folder (rescue layout: console.log + files/)."""
    import make_rescue as mk
    info = mk.summarize(console_text)
    row = {"status": info.get("status", "unknown"), "score": info.get("score", "")}
    tu = next(iter(sorted(out_dir.rglob("token_usage.json"))), None)
    if tu:
        d = json.loads(tu.read_text())
        t = d.get("total", {})
        calls = d.get("calls", [])
        row.update(llm_s=round(t.get("duration_s", 0), 1), tokens=t.get("total_tokens", ""),
                   prompt_tokens=t.get("prompt_tokens", ""), completion_tokens=t.get("completion_tokens", ""),
                   llm_calls=t.get("calls", ""), cached_calls=sum(1 for c in calls if c.get("cached")),
                   models=";".join(sorted({str(c.get("model", "")).split("/")[-1] for c in calls})),
                   per_agent_tokens=json.dumps({k: v.get("total_tokens") for k, v in d.get("per_agent", {}).items()}))
        if d.get("wall_time_s") and not row.get("wall_s"):
            row["wall_s"] = d["wall_time_s"]
    orfs_s, runs, full = 0.0, 0, 0
    orfs_logs = list(out_dir.rglob("*ORFS_ITER_*.log")) + list(out_dir.rglob("attempt_*_orfs.log"))   # parts 2-3, part 4
    for f in orfs_logs:
        s, n = elapsed_s(f.read_text(errors="replace"))
        orfs_s += s
        runs += 1
        full += n >= 19
    row.update(orfs_s=round(orfs_s, 1), orfs_runs=runs, orfs_full_runs=full,
               rtl_iters=len(list(out_dir.rglob("*_sim_ITER_*.log"))) + len(list(out_dir.rglob("attempt_*_sim.log"))))
    return row


def cmd_agent(a):
    import make_rescue as mk
    runs = [r.strip() for r in a.runs.split(",") if r.strip()]
    designs = [norm_design(d) for d in (a.design or designs_all())]
    done = {(r["run"], r["design"], r["repeat"]) for r in read_csv(AGENT_CSV)
            if r.get("source") == "profile" and r.get("status") not in ("", "aborted")}
    todo = [(run, d, k) for d in designs for run in runs for k in range(1, a.repeats + 1)
            if (run, d, str(k)) not in done]

    est = estimate(todo)
    print(f"{B}Agent profile: {len(todo)} runs to do ({len(runs)} run configs x {len(designs)} designs x "
          f"{a.repeats} repeats, {len(runs) * len(designs) * a.repeats - len(todo)} already done){R}")
    print(f"Estimated time (sequential): {fmt_s(est)}  - based on {'your measurements' if read_csv(AGENT_CSV) else 'defaults'}\n")
    if a.dry_run:
        for run, d, k in todo:
            print(f"  {run:42} {d:4} #{k}")
        return

    for n, (run, d, k) in enumerate(todo, 1):
        e = {"part": part_of(run), "run": run, "design": f"{d}.yaml"}
        if a.variant == "problem":
            e["variant"] = "problem"
        if a.extra_args:
            e["extra_args"] = a.extra_args.split()
        cwd, cmd, collect, clean, _ = mk.plan(e)
        out = OUT / "runs" / f"{run}-{d}-r{k}"
        if out.exists():
            shutil.rmtree(out)
        (out / "files").mkdir(parents=True)
        for c in clean:
            if c.exists():
                shutil.rmtree(c)
        print(f"{B}{C}[{n}/{len(todo)}] {run} {d} #{k}{R}  ({' '.join(cmd)})", flush=True)
        if a.timeout:
            cmd = ["timeout", str(a.timeout)] + cmd
        quiet = not a.verbose
        rc, secs = record_quiet(cmd, cwd, out, quiet)
        for src, name in collect:
            if src.is_dir():
                shutil.copytree(src, out / "files" / name, dirs_exist_ok=True)
            elif src.exists():
                shutil.copy(src, out / "files" / name)
        if not a.keep_layouts:   # layouts are big; the logs and metrics are enough for profiling
            for f in list((out / "files").rglob("*.odb")) + list((out / "files").rglob("*.gds")):
                f.unlink()
        console = (out / "console.log").read_text(errors="replace")
        row = dict(date=datetime.now().isoformat(timespec="seconds"), source="profile", run=run, part=e["part"],
                   design=d, repeat=k, exit_code=rc, wall_s=round(secs, 1), out_dir=str(out.relative_to(HERE)))
        row.update(collect_metrics(out, console))
        row["wall_s"] = round(secs, 1)
        if rc == 124:
            row["status"] = "timeout"
        llm = fnum(row.get("llm_s"))
        row["eda_s"] = round(secs - llm, 1) if llm is not None else ""
        append_csv(AGENT_CSV, AGENT_FIELDS, row)
        col = G if row["status"] == "success" else RD
        print(f"   {col}{row['status']}{R}  wall {fmt_s(secs)}  LLM {fmt_s(llm)}  OpenROAD {fmt_s(fnum(row.get('orfs_s')))}"
              f" ({row.get('orfs_runs', 0)} runs)  tokens {row.get('tokens', '?')}  score {row.get('score') or '-'}\n")
        if a.pause:
            time.sleep(a.pause)
    print(f"Saved to {AGENT_CSV.relative_to(SCRIPTS.parent)}. Next: python3 profile_designs.py report")


def record_quiet(cmd, cwd, out_dir, quiet):
    env = dict(os.environ, PYTHONUNBUFFERED="1")
    cache_dir = tempfile.mkdtemp(prefix="dspy_cache_profile_")
    env["DSPY_CACHEDIR"] = cache_dir           # fresh cache: real answers, real tokens, real latency
    t0 = time.time()
    with open(out_dir / "console.log", "w") as log:
        p = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                             bufsize=1, env=env, errors="replace")
        for line in p.stdout:
            if not quiet:
                sys.stdout.write(line)
            log.write(line)
        p.wait()
    shutil.rmtree(cache_dir, ignore_errors=True)
    return p.returncode, time.time() - t0


# defaults (seconds per run) used before you have measurements; from the runs in the repo, Oct 2026
DEFAULT_S = {2: 120, 3: 300, 4: 240}
HARD = {"p8": 2.5, "p9": 1.8, "p7": 1.6, "p5": 1.5}


def estimate(todo):
    rows = [r for r in read_csv(AGENT_CSV) if fnum(r.get("wall_s"))]
    tot = 0.0
    for run, d, _ in todo:
        same = [fnum(r["wall_s"]) for r in rows if r["run"] == run and r["design"] == d]
        run_only = [fnum(r["wall_s"]) for r in rows if r["run"] == run]
        if same:
            tot += st.mean(same)
        elif run_only:
            tot += st.mean(run_only) * HARD.get(d, 1.0)
        else:
            tot += DEFAULT_S[part_of(run)] * HARD.get(d, 1.0)
    return tot


# ----------------------------------------------------------------------------- 3. harvest existing runs
def cmd_harvest(a):
    """Import the runs that already exist in the repo (rescue recordings and runs/ folders)."""
    known = {r["out_dir"] for r in read_csv(AGENT_CSV)}
    n = 0
    for meta_f in sorted((SCRIPTS / "rescue" / "runs").glob("*/meta.json")):
        m = json.loads(meta_f.read_text())
        e = m.get("entry", {})
        if e.get("part") not in (2, 3, 4):
            continue
        rid = str(meta_f.parent.relative_to(SCRIPTS))
        if rid in known:
            continue
        console = (meta_f.parent / "console.log").read_text(errors="replace") if (meta_f.parent / "console.log").exists() else ""
        row = dict(date=m.get("recorded", ""), source="rescue", run=e["run"], part=e["part"],
                   design=norm_design(e["design"]), repeat=meta_f.parent.name.split(".try")[-1] if ".try" in meta_f.parent.name else "0",
                   exit_code=m.get("exit_code", ""), out_dir=rid)
        row.update(collect_metrics(meta_f.parent, console))
        row["wall_s"] = m.get("duration_s", row.get("wall_s"))
        if m.get("status"):
            row["status"] = m["status"]
        llm = fnum(row.get("llm_s"))
        row["eda_s"] = round(fnum(row["wall_s"]) - llm, 1) if llm is not None and fnum(row["wall_s"]) else ""
        append_csv(AGENT_CSV, AGENT_FIELDS, row)
        n += 1
    # golden OpenROAD runs made by make_reference.py
    eda_known = {(r["design"], r["repeat"]) for r in read_csv(EDA_CSV)}
    for log in sorted((SCRIPTS / "reference").glob("p*/build/orfs_try*.log")):
        pid = log.parent.parent.name
        if (pid, "ref") in eda_known:
            continue
        text = log.read_text(errors="replace")
        s, steps = elapsed_s(text)
        ref_json = SCRIPTS / "part2/evaluation/visible" / pid / f"{pid}.json"
        cells = json.loads(ref_json.read_text()).get("design__instance__count__stdcell", "") if ref_json.exists() else ""
        append_csv(EDA_CSV, EDA_FIELDS, dict(date="", design=pid, module="", repeat="ref", cells=cells,
                                             orfs_steps_s=round(s, 1), orfs_ok=steps >= 19,
                                             orfs_stage_s=json.dumps(orfs_stages(text))))
        n += 1
    print(f"Imported {n} existing runs into {OUT.relative_to(SCRIPTS.parent)}/")


# ----------------------------------------------------------------------------- 4. report
def cmd_report(a):
    eda, agent = read_csv(EDA_CSV), read_csv(AGENT_CSV)
    if not eda and not agent:
        sys.exit("No measurements yet: run  eda, agent  or  harvest  first.")
    lines = [f"# Design profile ({datetime.now():%Y-%m-%d %H:%M})", ""]
    order = {d: i for i, d in enumerate(DESIGN_ORDER)}
    if eda:
        lines += ["## EDA only (golden design, no LLM)", "",
                  "| design | cells | n | sim | OpenROAD flow (wall) | OpenROAD steps (sum) | metrics | total |",
                  "|---|---|---|---|---|---|---|---|"]
        for d in sorted({r["design"] for r in eda}, key=lambda x: order.get(x, 99)):
            rs = [r for r in eda if r["design"] == d]
            cells = next((r["cells"] for r in rs if r["cells"]), "")
            c = lambda k: stats([fnum(r.get(k)) for r in rs])
            sim, orfs, steps, met, tot = c("sim_s"), c("orfs_s"), c("orfs_steps_s"), c("metrics_s"), c("total_s")
            ms = lambda s: f"{fmt_s(s[0])} ± {s[2]:.0f}s" if s[0] is not None else "-"
            lines.append(f"| {d} | {cells} | {len(rs)} | {ms(sim)} | {ms(orfs)} | {ms(steps)} | {ms(met)} | {ms(tot)} |")
        lines.append("")
    if agent:
        lines += ["## Agent runs", "",
                  "| run | design | n | success | wall mean ± sd | median | LLM | EDA | OpenROAD runs | tokens mean | score |",
                  "|---|---|---|---|---|---|---|---|---|---|---|"]
        keys = sorted({(r["run"], r["design"]) for r in agent}, key=lambda k: (k[0], order.get(k[1], 99)))
        for run, d in keys:
            rs = [r for r in agent if r["run"] == run and r["design"] == d]
            w = stats([fnum(r["wall_s"]) for r in rs])
            llm = stats([fnum(r.get("llm_s")) for r in rs])
            eda_s = stats([fnum(r.get("eda_s")) for r in rs])
            ok = sum(r["status"] == "success" for r in rs)
            tok = stats([fnum(r.get("tokens")) for r in rs])
            orr = stats([fnum(r.get("orfs_runs")) for r in rs])
            sc = stats([fnum(r.get("score")) for r in rs])
            lines.append(f"| {run} | {d} | {len(rs)} | {ok}/{len(rs)} | {fmt_s(w[0])} ± {fmt_s(w[2])} | {fmt_s(w[1])} | "
                         f"{fmt_s(llm[0])} | {fmt_s(eda_s[0])} | {orr[0] or 0:.1f} | "
                         f"{(tok[0] or 0) / 1000:.0f}k | {('%.1f' % sc[0]) if sc[0] is not None else '-'} |")
        lines.append("")
        by_run = {}
        for r in agent:
            if fnum(r["wall_s"]):
                by_run.setdefault(r["run"], []).append(fnum(r["wall_s"]))
        lines += ["## Average per run config", "", "| run | runs | mean | median | max |", "|---|---|---|---|---|"]
        for run, v in sorted(by_run.items()):
            lines.append(f"| {run} | {len(v)} | {fmt_s(st.mean(v))} | {fmt_s(st.median(v))} | {fmt_s(max(v))} |")
        lines.append("")
    rep = OUT / "profile_report.md"
    OUT.mkdir(parents=True, exist_ok=True)
    rep.write_text("\n".join(lines) + "\n")
    print("\n".join(lines))
    print(f"\nSaved to {rep.relative_to(SCRIPTS.parent)}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("eda", help="golden designs through the tools only (no LLM)")
    e.add_argument("-d", "--design", action="append", help="pN (repeatable, default: all)")
    e.add_argument("-r", "--repeats", type=int, default=3)
    e.add_argument("--orfs-dir", default=None)
    g = sub.add_parser("agent", help="run the agent flows and measure them")
    g.add_argument("--runs", default="2b_multi_agent", help="comma separated run configs")
    g.add_argument("-d", "--design", action="append", help="pN (repeatable, default: all)")
    g.add_argument("-r", "--repeats", type=int, default=3)
    g.add_argument("--timeout", type=int, default=3600, help="seconds per run (0 = none)")
    g.add_argument("--variant", choices=["solution", "problem"], default="solution")
    g.add_argument("--extra-args", default="", help='passed to the flow, e.g. "--profile ollama-llama3.1"')
    g.add_argument("--pause", type=int, default=0, help="seconds between runs (API rate limits)")
    g.add_argument("--keep-layouts", action="store_true")
    g.add_argument("--verbose", action="store_true", help="show the flow output")
    g.add_argument("--dry-run", action="store_true")
    sub.add_parser("harvest", help="import runs already in the repo")
    sub.add_parser("report", help="tables from the measurements")
    a = ap.parse_args()
    {"eda": cmd_eda, "agent": cmd_agent, "harvest": cmd_harvest, "report": cmd_report}[a.cmd](a)


if __name__ == "__main__":
    main()
