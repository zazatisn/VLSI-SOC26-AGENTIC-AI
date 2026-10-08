# Role and Objective
You write a self-checking Verilog-2001 testbench for module seq_detector_0011(input clk, input reset, input data_in, output reg detected). Clock period 1.1 ns, reset is synchronous and active high.

# Mandatory Rules
1. Verilog-2001 only: reg, wire, integer, initial, always. No SystemVerilog, no assert, no `timescale line, no string types.
2. Module name seq_detector_0011_tb with no ports. Declare reg clk, reset, data_in; wire detected. Instantiate the DUT BY PORT NAME: seq_detector_0011 dut(.clk(clk), .reset(reset), .data_in(data_in), .detected(detected));
3. Clock: initial clk = 0; always #0.55 clk = ~clk;
4. Initialize at time 0: reset = 1; data_in = 1; integer error counter = 0.
5. Wait for 2 rising edges (repeat(2) @(posedge clk);). Then wait @(negedge clk) and in THAT SAME falling edge do step i=0 and set reset = 0.
6. Step i on every falling edge (@(negedge clk)): FIRST compare detected with the expected bit, THEN assign data_in = in[i]. Never check at posedge or after #delay following it. Use blocking assignments for driving.
7. Store vectors as reg [0:15] v1_in = 16'b0001100110110010; reg [0:15] v1_exp = 16'b0000010001000000; reg [0:14] v2_in = 15'b001100110000011; reg [0:14] v2_exp = 15'b000010001000001; bit [i] is the i-th sample (left-most first). Run vector 1 (i=0..15) then vector 2 (i=0..14) with for-loops, no reset in between.
8. After the last bit: @(negedge clk); check detected == 0; then $finish exactly once. The loops are bounded so no timeout is needed.
9. Every check prints exactly one line: if (detected === exp) $display("TEST: PASS | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", ...); else $display("TEST: FAIL | Inputs: ... | Expected: %b | Output: %b", ...) and error counter increments. Use === so x values fail.
10. The words PASS and FAIL (any case) must appear ONLY in those check lines. Do NOT print summaries like '0 failures' or 'all tests passed'. Use 'DONE' for the end message.
11. It must compile with iverilog -Wall without any warning: declare all signals, size every constant, no unused-name tricks, use begin...end.

# Output Format
Output ONLY the raw Verilog file content. No markdown fences, no explanation.