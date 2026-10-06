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
    save_as_golden_tb
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
class IterativeVerilogCoder(dspy.Signature):
    """Generate and refine Verilog-2001 testbenches based on compilation and simulation feedback."""
    specification = dspy.InputField(desc="Hardware specification.")
    mutant_signature = dspy.InputField(desc="Module signature.")
    simulation_rules = dspy.InputField(desc="Mandatory rules for testbench structure.")
    previous_code = dspy.InputField(desc="Code from the previous iteration.")
    feedback = dspy.InputField(desc="Simulation errors, pass counts, or mutant survival info.")
    testbench_code = dspy.OutputField(desc="Corrected Verilog-2001 testbench code.")


IterativeVerilogCoder.__doc__ = f"Generate and refine Verilog-2001 testbenches based on:\n{agent_rules}"


# --- 3. MAIN ITERATIVE LOOP ---
def main():
    
    # check if goldet.tb already exists #
    golden_saved_path = os.path.join(MUTANT_DIR, "golden.tb")
    if os.path.exists(golden_saved_path):
        print(f"INFO: Golden TB already exists, skipping regeneration ...")
        exit()

    spec = get_file_content(os.path.join(MUTANT_DIR, "specification.md"))
    m0 = get_file_content(os.path.join(MUTANT_DIR, "mutant_0.v"))
    signature = next((l for l in m0.splitlines() if "module" in l), "")

    coder = dspy.ChainOfThought(IterativeVerilogCoder)

    tb_code = "None (First Attempt)"
    feedback = "Initial attempt. Construct a strict testbench to isolate exactly 1 correct mutant."
    max_iterations = 10

    loop_start_history_idx = len(lm.history)
    loop_start_time = time.perf_counter()

    for iteration in range(1, max_iterations + 1):
        print(f"\n================ Iteration {iteration}/{max_iterations} ================")

        iter_start_idx = len(lm.history)
        iter_start_time = time.perf_counter()

        prediction = coder(
            specification=spec,
            mutant_signature=signature,
            simulation_rules=agent_rules,
            previous_code=tb_code,
            feedback=feedback,
        )

        iter_duration = time.perf_counter() - iter_start_time
        iter_tokens = get_token_stats(lm, iter_start_idx)
        iter_tps, iter_tpm = compute_throughput(iter_tokens["total_tokens"], iter_duration)

        tb_code = prediction.testbench_code
        pass_count, eval_feedback = run_evaluator(tb_code, MUTANT_DIR, ROOT_DIR)
        
         # --- SAVE GOLDEN TB IF EXACTLY 1 MUTANT PASSED ---
        golden_saved_path = None
        if pass_count == 1:
            golden_saved_path = save_as_golden_tb(prediction.testbench_code, MUTANT_DIR)

        print(f"Outcome:         {pass_count} mutant(s) passed.")
        print(f"Iteration Time:  {iter_duration:.2f}s")
        print(
            f"Tokens Used:     Prompt: {iter_tokens['prompt_tokens']} | "
            f"Completion: {iter_tokens['completion_tokens']} | "
            f"Total: {iter_tokens['total_tokens']}"
        )
        print(f"Throughput:      {iter_tpm:,.1f} TPM ({iter_tps:.2f} TPS)")

        # --- FEEDBACK FORMULATION ---
        if "COMPILATION ERROR" in eval_feedback.upper():
            feedback = f"Compilation Error encountered. Fix the syntax:\n{eval_feedback}"
        elif pass_count == 1:
            print(f"\nSUCCESS! Exactly 1 mutant isolated in {iteration} iteration(s).")
            break
        elif pass_count > 1:
            feedback = (
                f"Weak testbench: {pass_count} mutants passed. "
                f"Add edge-case checks to disqualify invalid mutants.\n{eval_feedback}"
            )
        else:  # pass_count == 0
            feedback = "Overly strict testbench: 0 mutants passed. Verify golden logic and checks."

    # --- CUMULATIVE AGENT METRICS SUMMARY ---
    total_duration = time.perf_counter() - loop_start_time
    total_tokens = get_token_stats(lm, loop_start_history_idx)
    total_tps, total_tpm = compute_throughput(total_tokens["total_tokens"], total_duration)

    print("\n================ CUMULATIVE ITERATIVE RUN SUMMARY ================")
    print(f"Target Design:    {DESIGN_SUBFOLDER}")
    print(f"Total Duration:   {total_duration:.2f} seconds")
    print(
        f"Total Tokens:     Prompt: {total_tokens['prompt_tokens']} | "
        f"Completion: {total_tokens['completion_tokens']} | "
        f"Total: {total_tokens['total_tokens']}"
    )
    print(f"Avg Throughput:   {total_tpm:,.1f} TPM ({total_tps:.2f} TPS)")
    print("==================================================================")


if __name__ == "__main__":
    main()