#####################################################################
# Author: Monastiriotis Theodoros                                   #
#                                                                   #
# Description:                                                      #
# An automated simulation runner for Verilog mutant testing.        #
# This script compiles mutants using iverilog and executes them     #
# via vvp. Also, it prints compilation errors to the console.       #
#####################################################################

import subprocess
import os

def run_simulation():
    # ANSI Color Codes
    RED = "\033[91m"
    GREEN = "\033[92m"
    RESET = "\033[0m"
    
    # Configuration
    tb_file = "tb.v"
    pass_string = "TEST PASSED"
    
    captured_compile_error = None  # To store compile error

    # Header
    print(f"{'Mutant':<16} | {'Status':<10}")
    print("-" * 30)

    # Loop through mutants 0 to 30
    for i in range(31):
        mutant_name = f"mutant_{i}"
        mutant_file = f"{mutant_name}.v"
        
        if not os.path.exists(mutant_file):
            continue

        # Compile with iverilog
        comp_cmd = ["iverilog", "-g2012", "-o", "sim_out", tb_file, mutant_file]
        comp_result = subprocess.run(comp_cmd, capture_output=True, text=True)

        if comp_result.returncode != 0:
            # Print status to terminal
            print(f"{mutant_name:<16} | {RED}COMPILE ERROR{RESET}")
            
            # Capture the error once
            if captured_compile_error is None:
                captured_compile_error = comp_result.stderr
            continue

        # Run simulation with vvp
        run_result = subprocess.run(["vvp", "sim_out"], capture_output=True, text=True)

        # Check for the PASS string
        if pass_string in run_result.stdout:
            # Use GREEN to highlight PASSED mutants 
            print(f"mutant_{i:<9} | {GREEN}PASSED{RESET}")
        else:
            print(f"mutant_{i:<9} | FAILED")

    # Print the actual error message
    if captured_compile_error is not None:
        print(f"\n{RED}Error Output:{RESET}\n{comp_result.stderr}")
        print("!!! Process Finished with Errors !!!")

    # Cleanup
    if os.path.exists("sim_out"):
        os.remove("sim_out")

if __name__ == "__main__":
    run_simulation()