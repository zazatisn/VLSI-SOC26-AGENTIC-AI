#!/usr/bin/env python3
"""
Generate the PPA reference results (evaluation/visible/pN/pN.json) from the golden designs.

For each design it runs the golden RTL + SDC + config.mk through OpenROAD-flow-scripts exactly like
the flows do, then measures the final layout with evaluation/report_metrics.tcl (the same script the
PPA score uses) and writes pN.json into evaluation/visible/pN of Parts 2, 3 and 4. With the reference
in place the flows score that design (the golden layout itself scores 75-80/100).

If the flow fails with the golden config.mk (small designs often hit PDN/placement errors), it retries
with a few safer floorplans and saves the one that worked as reference/pN/config.mk.

Run inside the Docker image (or a local install): needs openroad, yosys, make and ORFS.

  python3 make_reference.py                 # every design that has no pN.json yet (p11 ... p16)
  python3 make_reference.py -d p14 -d p15   # only these
  python3 make_reference.py --force -d p1   # overwrite an existing reference (careful: changes the scores)
  python3 make_reference.py --keep-layout   # also keep 6_final.odb/.sdc/.gds in reference/pN/layout/

The golden layouts (--keep-layout) are also a good rescue: a known-good GDS to show if a live run fails.
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
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
SCRIPTS = HERE.parent
PARTS = ["part2", "part3", "part4"]
PLATFORM = "sky130hd"
G, RD, Y, B, R = "\033[92m", "\033[91m", "\033[93m", "\033[1m", "\033[0m"

# Floorplans tried in order when the golden config.mk fails (utilization %, core margin, place density)
FALLBACKS = [(30, 3.0, 0.55), (20, 4.0, 0.5), (10, 4.0, 0.45), (5, 5.0, 0.4)]


def die(msg):
    print(f"{RD}Error: {msg}{R}")
    sys.exit(2)


def find_orfs(arg):
    for c in [arg, os.environ.get("ORFS_DIR"), "/home/OpenROAD-flow-scripts"]:
        if c and (Path(c) / "flow" / "Makefile").exists():
            return Path(c).resolve()
    if shutil.which("openroad"):
        for p in Path(shutil.which("openroad")).resolve().parents:
            if (p / "flow" / "Makefile").exists():
                return p
    die("OpenROAD-flow-scripts not found: pass --orfs-dir or set ORFS_DIR")


def openroad_bin(orfs):
    exe = os.environ.get("OPENROAD_EXE") or shutil.which("openroad")
    if exe and Path(exe).exists():
        return exe
    alt = orfs / "tools/install/OpenROAD/bin/openroad"
    if alt.exists():
        return str(alt)
    die("openroad not found: set OPENROAD_EXE")


def set_floorplan(config_text, util, margin, density):
    config_text = re.sub(r"(CORE_UTILIZATION\s*=\s*)\S+", rf"\g<1>{util}", config_text)
    config_text = re.sub(r"(CORE_MARGIN\s*=\s*)\S+", rf"\g<1>{margin}", config_text)
    return re.sub(r"(PLACE_DENSITY\s*=\s*)\S+", rf"\g<1>{density}", config_text)


def run_flow(orfs, module, golden_rtl, sdc, config_text, log_path):
    flow = orfs / "flow"
    design_dir = flow / "designs" / PLATFORM / module
    src_dir = flow / "designs" / "src" / module
    for d in (design_dir, src_dir):
        shutil.rmtree(d, ignore_errors=True)
        d.mkdir(parents=True)
    for f in golden_rtl:
        shutil.copy(f, src_dir / f.name)
    shutil.copy(sdc, design_dir / "constraint.sdc")
    (design_dir / "config.mk").write_text(config_text)
    cfg = design_dir / "config.mk"
    subprocess.run(["make", "clean_all", f"DESIGN_CONFIG={cfg}"], cwd=flow, capture_output=True)
    t0 = time.time()
    with open(log_path, "w") as log:
        rc = subprocess.run(["make", f"DESIGN_CONFIG={cfg}"], cwd=flow, stdout=log, stderr=subprocess.STDOUT).returncode
    results = flow / "results" / PLATFORM / module / "base"
    ok = rc == 0 and (results / "6_final.odb").exists()
    return ok, results, time.time() - t0


def measure(orfs, results, metrics_path):
    tcl = SCRIPTS / "part2" / "evaluation" / "report_metrics.tcl"
    with tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False) as f:
        f.write(f'set odb_path "{results / "6_final.odb"}"\nset sdc_path "{results / "6_final.sdc"}"\n'
                f'set flow_root "{orfs}"\nsource "{tcl}"\n')
        tcl_run = f.name
    try:
        p = subprocess.run([openroad_bin(orfs), "-metrics", str(metrics_path), "-exit", tcl_run],
                           capture_output=True, text=True)
        if p.returncode or not metrics_path.exists():
            print(p.stdout[-1500:], p.stderr[-800:])
            return None
        return json.loads(metrics_path.read_text())
    finally:
        Path(tcl_run).unlink(missing_ok=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-d", "--design", action="append", help="pN (repeatable)")
    ap.add_argument("--force", action="store_true", help="overwrite existing pN.json references")
    ap.add_argument("--keep-layout", action="store_true", help="copy the golden layout to reference/pN/layout/")
    ap.add_argument("--orfs-dir", default=None)
    a = ap.parse_args()

    orfs = find_orfs(a.orfs_dir)
    for t in ("make", "yosys"):
        if not shutil.which(t):
            die(f"{t} not found in PATH")
    openroad_bin(orfs)

    all_pids = sorted((p.name for p in HERE.glob("p*") if p.is_dir()), key=lambda s: int(s[1:]))
    pids = a.design or [p for p in all_pids
                        if not (SCRIPTS / "part2/evaluation/visible" / p / f"{p}.json").exists()]
    if not pids:
        print("Every design already has a reference (use -d pN --force to regenerate one).")
        return
    print(f"{B}ORFS: {orfs}{R}\nDesigns: {', '.join(pids)}\n")

    summary = []
    for pid in pids:
        ref_json = SCRIPTS / "part2/evaluation/visible" / pid / f"{pid}.json"
        if ref_json.exists() and not a.force:
            print(f"{Y}{pid}: reference exists, skipped (use --force){R}")
            continue
        spec = yaml.safe_load((SCRIPTS / "part2/designs" / f"{pid}.yaml").read_text())
        module = list(spec)[0]
        golden = sorted((HERE / pid).glob("*.v"))
        sdc = HERE / pid / "constraint.sdc"
        base_cfg = (HERE / pid / "config.mk").read_text()
        work = HERE / pid / "build"
        work.mkdir(exist_ok=True)

        tries = [None] + FALLBACKS
        ok = False
        for k, fp in enumerate(tries):
            cfg = base_cfg if fp is None else set_floorplan(base_cfg, *fp)
            label = "golden config.mk" if fp is None else f"fallback util={fp[0]} margin={fp[1]} density={fp[2]}"
            print(f"{pid} {module}: OpenROAD flow with {label} ...", flush=True)
            ok, results, secs = run_flow(orfs, module, golden, sdc, cfg, work / f"orfs_try{k}.log")
            if ok:
                print(f"   {G}flow OK in {secs:.0f}s{R}")
                if fp is not None:
                    (HERE / pid / "config.mk").write_text(cfg)
                    print(f"   saved the working floorplan to reference/{pid}/config.mk")
                break
            tail = (work / f"orfs_try{k}.log").read_text(errors="replace").splitlines()[-6:]
            print(f"   {RD}flow failed{R} (see reference/{pid}/build/orfs_try{k}.log):\n      " + "\n      ".join(tail))
        if not ok:
            summary.append((pid, module, "FLOW FAILED", None))
            continue

        metrics = measure(orfs, results, work / f"{pid}.json")
        if not metrics:
            summary.append((pid, module, "METRICS FAILED", None))
            continue
        for part in PARTS:
            dst = SCRIPTS / part / "evaluation/visible" / pid
            if dst.exists():
                (dst / f"{pid}.json").write_text(json.dumps(metrics, indent=1) + "\n")
        if a.keep_layout:
            lay = HERE / pid / "layout"
            lay.mkdir(exist_ok=True)
            for f in ("6_final.odb", "6_final.sdc", "6_final.gds", "6_final.v"):
                if (results / f).exists():
                    shutil.copy(results / f, lay / f)
        summary.append((pid, module, "OK", metrics))

    print(f"\n{B}{'design':6} {'module':26} {'status':15} {'area um^2':>10} {'WNS ns':>8} {'power W':>10}{R}")
    for pid, module, st, m in summary:
        if m:
            print(f"{pid:6} {module:26} {G}{st:15}{R} {m['design__instance__area']:10.1f} "
                  f"{m['timing__setup__ws']:8.3f} {m['power__total']:10.3e}")
        else:
            print(f"{pid:6} {module:26} {RD}{st}{R}")
    bad_wns = [pid for pid, _, _, m in summary if m and m["timing__setup__ws"] < 0]
    if bad_wns:
        print(f"\n{Y}Golden designs with negative WNS: {', '.join(bad_wns)}. The reference is still valid, but consider "
              f"a longer clock_period in the spec for a fairer target.{R}")
    print("\nReferences written to evaluation/visible/pN/pN.json in " + ", ".join(PARTS) +
          ". Commit them so attendees get scored results.")


if __name__ == "__main__":
    main()
