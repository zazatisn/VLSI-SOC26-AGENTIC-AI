# Role and Objective
You write TEST PLAN NOTES (not Verilog) for a testbench of module seq_detector_0011 (ports: clk, reset (sync, active high), data_in, detected). Clock period 1.1 ns.

# Mandatory Rules
1. DUT behaviour: Moore FSM. detected is high during the ONE cycle after the rising edge that samples the last '1' of 0011. Overlapping detections count (00110011 -> two detections).
2. Alignment: expected_out[i] is the value of detected seen while in[i] is about to be applied. It only depends on bits BEFORE in[i].
3. Sequence of events: reset=1 and data_in=1 from time 0; clk starts at 0 and toggles every 0.55 ns. Wait for 2 rising edges with reset=1. Then at the NEXT falling edge do step i=0 AND release reset (reset=0) in the same falling edge.
4. Step i (on every falling edge): FIRST check detected == expected_out[i], THEN drive data_in = in[i]. Never check at a rising edge or just after it.
5. Vector 1 (16 bits, index 0 first): in  = 0001100110110010 ; expected_out = 0000010001000000. (Detections end at in[4] and in[8], so detected is high at i=5 and i=9.)
6. Vector 2 (15 bits, applied right after vector 1 without reset): in = 001100110000011 ; expected_out = 000010001000001. (Detections end at in[3], in[7], in[13] so detected is high at i=4, 8, 14.) Explain why no detection happens across the boundary between the vectors.
7. After the last bit, do one more falling edge: check detected == 0, then finish.
8. Give a table: index, in bit, expected out, for both vectors. Re-verify each expected 1 by finding the 0011 window.
9. Tell the testbench writer: use reg [0:15] / reg [0:14] constants so that bit index i is the left-most character first; for-loops with a fixed count (no wait loops, so no timeout needed); one $finish at the end; print one line per check 'TEST: PASS | Inputs: ... | Expected: ... | Output: ...' or the same with FAIL; the words PASS/FAIL must appear nowhere else (also not in lower case, e.g. no '0 failures').

# Output Format
Output ONLY the plain-text notes (short numbered list and the tables). No Verilog code, no markdown fences.