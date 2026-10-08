#!/usr/bin/env python3
"""
Show the runs recorded by make_rescue.py.

  python3 show_rescue.py list                         every recorded run: date, time, status, score, tokens
  python3 show_rescue.py show <id>                    summary + the end of the console output + file list
  python3 show_rescue.py replay <id>                  replay the console output with its real timing, 10x faster
  python3 show_rescue.py replay <id> --speed 30       faster (OpenROAD waits are long)
  python3 show_rescue.py replay <id> --max-pause 2    never pause more than 2 s between two lines
  python3 show_rescue.py files <id>                   where the outputs are (RTL, testbench, layout, tokens)

<id> can be a unique part of the name, e.g.  replay 2b-p1  or  show part4.
"""
import argparse
import json
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
RUNS = HERE / "runs"
G, RD, Y, B, C, D, R = "\033[92m", "\033[91m", "\033[93m", "\033[1m", "\033[96m", "\033[2m", "\033[0m"


def recorded():
    return sorted((p for p in RUNS.glob("*") if (p / "meta.json").exists()), key=lambda p: p.name) if RUNS.exists() else []


def find(key):
    runs = recorded()
    exact = [p for p in runs if p.name == key]
    if exact:
        return exact[0]
    parts = key.lower().split("-")
    tokens = lambda p: set(re.split(r"[-_.]", p.name.lower()))
    hits = [p for p in runs if all(x in tokens(p) for x in parts)]        # exact parts first: p1 is not p11
    if not hits:
        hits = [p for p in runs if all(x in p.name.lower() for x in parts)]
    if ".try" not in key:                       # prefer the final recording over the kept failed attempts
        hits = [p for p in hits if ".try" not in p.name] or hits
    if len(hits) == 1:
        return hits[0]
    if not hits:
        sys.exit(f"{RD}No recorded run matches '{key}'. Try: python3 show_rescue.py list{R}")
    sys.exit(f"{Y}'{key}' matches several runs: {', '.join(p.name for p in hits)}{R}")


def meta(p):
    return json.loads((p / "meta.json").read_text())


def cmd_list(_):
    runs = recorded()
    if not runs:
        print("No recorded runs yet. Record them with:  python3 make_rescue.py --preset tutorial")
        return
    print(f"{B}{'id':52} {'recorded':19} {'time':>6}  {'status':16} {'score':>6} {'tokens':>8}{R}")
    for p in runs:
        m = meta(p)
        st = m.get("status", "exit 0" if m["exit_code"] == 0 else f"exit {m['exit_code']}")
        if m.get("cached_answers"):
            st += " (cache)"
        col = G if st in ("success", "exit 0") else (Y if "cache" in st and "failed" not in st else RD)
        score = m.get("score", m.get("compiled_accuracy", m.get("mutant_result", "")))
        print(f"{p.name:52} {m['recorded'].replace('T', ' '):19} {m['duration_s']:>5.0f}s  {col}{st:16}{R} "
              f"{str(score):>6} {str(m.get('tokens_total', '')):>8}")


def cmd_show(a):
    p = find(a.id)
    m = meta(p)
    print(f"{B}{C}{p.name}{R}")
    print(f"  recorded   {m['recorded']}  (git {m.get('git_commit') or '?'})")
    print(f"  command    cd scripts/{m['cwd']} && {' '.join(m['command'])}")
    print(f"  duration   {m['duration_s']:.0f} s,  exit code {m['exit_code']}")
    for k in ("status", "score", "compiled_accuracy", "mutant_result", "tokens_total"):
        if k in m:
            print(f"  {k:10} {m[k]}")
    lines = (p / "console.log").read_text(errors="replace").splitlines()
    print(f"\n{D}--- last {a.lines} of {len(lines)} console lines ---{R}")
    print("\n".join(lines[-a.lines:]))
    cmd_files(a, header=False)


def cmd_files(a, header=True):
    p = find(a.id)
    files = p / "files"
    if header:
        print(f"{B}{p.name}{R}")
    interesting = re.compile(r"(\.v|\.sdc|config\.mk|\.json|\.odb|\.gds|\.log|\.md|golden\.tb)$")
    hits = sorted(f for f in files.rglob("*") if f.is_file() and interesting.search(f.name)
                  and "_ITER_" not in f.name and "/agents/" not in str(f) and "/subtasks/" not in str(f))
    print(f"\n{D}--- files (final outputs; every iteration is under {files.relative_to(HERE)}) ---{R}")
    for f in hits[:60]:
        print(f"  {f.relative_to(HERE)}")
    if len(hits) > 60:
        print(f"  ... {len(hits) - 60} more")


def cmd_replay(a):
    p = find(a.id)
    lines = (p / "console.log").read_text(errors="replace").splitlines(True)
    timing_file = p / "console.timing"
    stamps = [float(x) for x in timing_file.read_text().split()] if timing_file.exists() else []
    if len(stamps) != len(lines):
        stamps = [i * 0.05 for i in range(len(lines))]
    m = meta(p)
    if not a.quiet:
        print(f"{D}[replay of a run recorded {m['recorded']}, {m['duration_s']:.0f} s, shown {a.speed:g}x faster]{R}")
        print(f"{B}$ {' '.join(m['command'])}{R}")
    prev = 0.0
    try:
        for line, t in zip(lines[a.from_line:], stamps[a.from_line:]):
            pause = min((t - prev) / a.speed, a.max_pause)
            if pause > 0:
                time.sleep(pause)
            prev = t
            sys.stdout.write(line)
            sys.stdout.flush()
    except KeyboardInterrupt:
        print(f"\n{Y}[replay stopped]{R}")
    except BrokenPipeError:
        pass


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd")
    sub.add_parser("list")
    s = sub.add_parser("show"); s.add_argument("id"); s.add_argument("--lines", type=int, default=40)
    f = sub.add_parser("files"); f.add_argument("id")
    r = sub.add_parser("replay"); r.add_argument("id")
    r.add_argument("--speed", type=float, default=10.0, help="how many times faster than the real run (default 10)")
    r.add_argument("--max-pause", type=float, default=3.0, help="longest pause between two lines, seconds (default 3)")
    r.add_argument("--from-line", type=int, default=0)
    r.add_argument("--quiet", action="store_true", help="no header line (looks exactly like a live run)")
    a = ap.parse_args()
    {"list": cmd_list, "show": cmd_show, "files": cmd_files, "replay": cmd_replay}.get(a.cmd, lambda _: ap.print_help())(a)


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:          # output piped into head/less that closed early
        sys.stderr.close()
