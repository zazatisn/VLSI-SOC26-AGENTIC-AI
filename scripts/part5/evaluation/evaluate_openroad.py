import argparse
import subprocess
import tempfile
from pathlib import Path
import sys
import json
import os
import re

def evaluate(submission, reference):
    score = 0

    # Scoring breakdown (baseline 75, up to +25 bonus for improvements)
    baseline_wns = 30  # out of 40
    baseline_tns = 15  # out of 20
    baseline_power = 15  # out of 20
    baseline_area = 15  # out of 20

    # Extract values
    wns = submission["timing__setup__ws"]
    tns = submission["timing__setup__tns"]
    ref_power = reference["power__total"]
    sub_power = submission["power__total"]
    ref_area = reference["design__instance__area"]
    sub_area = submission["design__instance__area"]

    # Scoring breakdown (baseline 75, up to +25 bonus for improvements)
    baseline_wns = 30  # out of 40
    baseline_tns = 15  # out of 20
    baseline_power = 15  # out of 20
    baseline_area = 15  # out of 20

    # 1. WNS (40 pts total, 30 baseline)
    ref_wns = reference["timing__setup__ws"]
    if wns >= ref_wns:
        wns_bonus = min(10, 40 * (wns - ref_wns))
    else:
        wns_bonus = -min(10, 40 * (ref_wns - wns))
    wns_score = baseline_wns + wns_bonus
    score += wns_score  # 10 pts lost per -0.025ns
   
    # 2. TNS (20 pts total, 15 baseline)
    ref_tns = reference["timing__setup__tns"]
    if tns >= ref_tns:
        tns_bonus = 5 * ((tns - ref_tns) / abs(ref_tns)) if ref_tns != 0 else 5
    else:
        tns_bonus = -5 * ((ref_tns - tns) / abs(ref_tns)) if ref_tns != 0 else -5
    tns_score = baseline_tns + tns_bonus
    score += max(0, min(tns_score, baseline_tns + 5))  # 1 point lost per 1ns TNS

    # 3. Power (20 pts)
    ref_power = reference["power__total"]
    sub_power = submission["power__total"]
    power_ratio = ref_power / sub_power
    if power_ratio >= 1:
        power_score = baseline_power + min(5, 20 * (power_ratio - 1))
    else:
        power_score = baseline_power - min(5, 20 * (1 - power_ratio))
    score += power_score

    # 4. Area (20 pts)
    ref_area = reference["design__instance__area"]
    sub_area = submission["design__instance__area"]
    area_ratio = ref_area / sub_area
    if area_ratio >= 1:
        area_score = baseline_area + min(5, 20 * (area_ratio - 1))
    else:
        area_score = baseline_area - min(5, 20 * (1 - area_ratio))
    score += area_score
    print(f"WNS Score: {wns_score:.2f}/40")
    print(f"TNS Score: {tns_score:.2f}/20")
    print(f"Power Score: {power_score:.2f}/20")
    print(f"Area Score: {area_score:.2f}/20")
    return min(score, 100)

def main():
    parser = argparse.ArgumentParser(description="Run OpenROAD timing evaluation.")
    parser.add_argument("--hidden", action="store_true", help="Use hidden reference instead of visible")
    parser.add_argument("--odb", type=Path, required=True, help="Path to .odb file")
    parser.add_argument("--sdc", type=Path, required=True, help="Path to .sdc file")
    parser.add_argument("--flow_root", type=Path, required=True, help="Path to openroad-flow-scripts directory")
    parser.add_argument("--problem", type=int, required=True, help="Problem number for metrics file naming")

    args = parser.parse_args()

    odb_path = args.odb.resolve()
    sdc_path = args.sdc.resolve()
    flow_root = args.flow_root.resolve()
    problem_number = args.problem

    script_dir = Path(__file__).resolve().parent
    ref_dir = "hidden" if args.hidden else "visible"
    reference_path = script_dir / f"{ref_dir}/p{problem_number}/p{problem_number}.json"
    evaluate_tcl = script_dir / "report_metrics.tcl"
    if not evaluate_tcl.exists():
        print(f"Error: report_metrics.tcl not found at {evaluate_tcl}")
        sys.exit(1)

    # Use OPENROAD_EXE environment variable if set; otherwise, use default path
    openroad_env = os.getenv("OPENROAD_EXE")
    openroad_bin = Path(openroad_env) if openroad_env else flow_root / "tools" / "install" / "OpenROAD" / "bin" / "openroad"

    if not openroad_bin.exists():
        print(f"Error: OpenROAD binary not found at {openroad_bin}")
        sys.exit(1)

    metrics_path = Path(f"p{problem_number}.json")

    # Create a temporary TCL script
    with tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False) as tcl_file:
        tcl_file.write(f"""
set odb_path "{odb_path}"
set sdc_path "{sdc_path}"
set flow_root "{flow_root}"
source "{evaluate_tcl}"
""")
        tcl_path = tcl_file.name

    try:
        subprocess.run([str(openroad_bin), "-metrics", metrics_path, "-exit", tcl_path], check=True)
        print(f"Metrics written to {metrics_path}")
        with open(metrics_path) as f:
            submission = json.load(f)

        with open(reference_path) as f:
            reference = json.load(f)

        score = evaluate(submission, reference)
        print(f"Final Score: {score}/100")

    except subprocess.CalledProcessError as e:
        print(f"OpenROAD execution failed: {e}")
    finally:
        Path(tcl_path).unlink(missing_ok=True)

if __name__ == "__main__":
    main()

