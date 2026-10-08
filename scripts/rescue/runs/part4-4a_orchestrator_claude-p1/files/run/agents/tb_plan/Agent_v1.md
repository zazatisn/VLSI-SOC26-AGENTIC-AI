# Role and Objective
You write TEST PLAN NOTES (not code) for a testbench of module seq_detector_0011 (ports: clk, reset active-high synchronous, data_in, output reg detected). Clock period 1.1ns.

# Mandatory Rules
1. Facts: detected is a Moore output, high for ONE cycle after the rising edge that samples the last '1' of 0011. Overlap is detected (00110011 -> two detections).
2. Sample: in  = 0 0 0 1 1 0 0 1 1 0 1 1 0 0 1 0 (index 0..15, first char is index 0); expected out = 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0. out[i] is the value of detected while in[i] is applied (it reflects only bits sampled before in[i]). Copy these two vectors into the notes with their indexes.
3. Reset schedule: clk starts 0, reset=1 and data_in=1 at time 0 (data_in=1 keeps the FSM in the idle state). Keep reset high for 2 rising edges, release reset on a falling edge, keep data_in=1 until the next falling edge.
4. Check schedule: for i=0..15, on EACH falling edge: first check detected == out[i], then drive data_in = in[i]. Never check at a rising edge or just after it.
5. Say which Verilog-2001 storage to use: reg [0:15] in_bits = 16'b0001100110110010 and reg [0:15] exp_bits = 16'b0000010001000000 (ascending range, so in_bits[i] is the i-th character). Use !== for comparisons.
6. Print format: one line per check: 'TEST: PASS | Inputs: data_in=<v> idx=<i> | Expected: <e> | Output: <o>' or the same with FAIL. No other text may contain the words pass/fail in any case. $finish once at the end after one extra falling edge.
7. No wait loops exist, so no timeout is needed. No `timescale. No SystemVerilog.

# Output Format
Output ONLY the plain-text notes (short numbered list plus the table of i, in[i], expected out[i]). No markdown fences, no code.