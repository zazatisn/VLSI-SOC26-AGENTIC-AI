import os
import time
import dspy
from lm_loader import load_configured_lm
import sys
from utility_func import (
    load_agent_instructions,
    get_file_content,
    run_evaluator,
    get_token_stats,
    compute_throughput,
    save_as_golden_tb,
)

# --- 1. CONFIGURATION & DSPY SETUP ---
DEFAULT_DESIGN_SUBFOLDER = "enc_bin2onehot"
DESIGN_SUBFOLDER = sys.argv[1] if len(sys.argv) > 1 and os.path.exists(sys.argv[1]) else DEFAULT_DESIGN_SUBFOLDER

lm = load_configured_lm("config.yaml")
dspy.configure(lm=lm)

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
MUTANT_DIR = os.path.join(ROOT_DIR, DESIGN_SUBFOLDER)
agent_rules = load_agent_instructions(os.path.join(ROOT_DIR, "AGENT.md"))


# --- 2. DSPY SIGNATURE ---
class VerilogCoder(dspy.Signature):
    """Generate a Verilog-2001 testbench based on design specification and rules."""
    specification = dspy.InputField(desc="Hardware specification for the design.")
    mutant_signature = dspy.InputField(desc="Structural reference for module port signature.")
    simulation_rules = dspy.InputField(desc="Mandatory rules for testbench structure.")
    testbench_code = dspy.OutputField(desc="Complete Verilog-2001 testbench code.")


VerilogCoder.__doc__ = f"Generate a Verilog-2001 testbench based on rules:\n{agent_rules}"


# --- 3. MAIN FLOW ---
def main():
    
    # check if goldet.tb already exists #
    golden_saved_path = os.path.join(MUTANT_DIR, "golden.tb")
    if os.path.exists(golden_saved_path):
        print("INFO: Golden TB already exists, skipping regeneration ...")
        exit()
    
    spec = get_file_content(os.path.join(MUTANT_DIR, "specification.md"))
    m0 = get_file_content(os.path.join(MUTANT_DIR, "mutant_0.v"))

    lines = m0.strip().splitlines()
    signature = next((l for l in lines if "module" in l), lines[0] if lines else "")

    coder = dspy.ChainOfThought(VerilogCoder)

    print(f"Generating Testbench via DSPy for '{DESIGN_SUBFOLDER}'...")

    start_history_idx = len(lm.history)
    start_time = time.perf_counter()

    prediction = coder(
        specification=spec,
        mutant_signature=signature,
        simulation_rules=agent_rules,
    )

    duration = time.perf_counter() - start_time
    tokens = get_token_stats(lm, start_history_idx)
    tps, tpm = compute_throughput(tokens["total_tokens"], duration)

    pass_count, stdout_feedback = run_evaluator(prediction.testbench_code, MUTANT_DIR, ROOT_DIR)

    # --- SAVE GOLDEN TB IF EXACTLY 1 MUTANT PASSED ---
    golden_saved_path = None
    if pass_count == 1:
        golden_saved_path = save_as_golden_tb(prediction.testbench_code, MUTANT_DIR)

    print("\n================ EVALUATION & PERFORMANCE SUMMARY ================")
    print(f"Design Folder:   {DESIGN_SUBFOLDER}")
    print(f"Mutants Passed:  {pass_count}")
    if golden_saved_path:
        print(f"Golden TB Saved: {golden_saved_path}")
    print(f"Generation Time: {duration:.2f} seconds")
    print(
        f"Token Usage:     Prompt: {tokens['prompt_tokens']} | "
        f"Completion: {tokens['completion_tokens']} | "
        f"Total: {tokens['total_tokens']}"
    )
    print(f"Throughput:      {tpm:,.1f} TPM ({tps:.2f} TPS)")
    print("==================================================================")
    print("\n--- EVALUATION LOG OUTPUT ---")
    print(stdout_feedback)


if __name__ == "__main__":
    main()