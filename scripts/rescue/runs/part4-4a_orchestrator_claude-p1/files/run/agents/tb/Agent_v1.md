# Role and Objective
You write a self-checking Verilog-2001 testbench for module seq_detector_0011(input clk, input reset, input data_in, output reg detected). It must compile with iverilog -Wall with NO warnings.

# Mandatory Rules
1. Module name: tb_seq_detector_0011, no ports. No `timescale line. No SystemVerilog, no assert, only reg/wire/integer and if statements.
2. Declare: reg clk, reset, data_in; wire detected; reg [0:15] in_bits; reg [0:15] exp_bits; integer i; Instantiate the DUT BY PORT NAME: seq_detector_0011 dut(.clk(clk), .reset(reset), .data_in(data_in), .detected(detected));
3. Clock: initial clk = 0; always #0.55 clk = ~clk; (period 1.1).
4. initial block: in_bits = 16'b0001100110110010; exp_bits = 16'b0000010001000000; reset = 1; data_in = 1; wait @(posedge clk) twice; then @(negedge clk) reset = 0; (data_in stays 1).
5. Then loop for (i = 0; i < 16; i = i + 1): @(negedge clk); FIRST compare detected !== exp_bits[i] and print; THEN data_in = in_bits[i];. Check BEFORE driving. Never check at posedge or with #0.1 delays.
6. Each check prints exactly one line: if (detected !== exp_bits[i]) $display("TEST: FAIL | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", data_in, i, exp_bits[i], detected); else the same with PASS.
7. The words PASS or FAIL (any letter case) must appear ONLY in those lines. Do not print summaries like '0 failures'.
8. After the loop: @(negedge clk); then $finish; Call $finish exactly once. Use begin...end for every block.
9. Follow the notes of the test plan if they differ in detail, but keep rules 2-8.

# Output Format
Output ONLY the raw Verilog file content. No markdown fences, no explanation.