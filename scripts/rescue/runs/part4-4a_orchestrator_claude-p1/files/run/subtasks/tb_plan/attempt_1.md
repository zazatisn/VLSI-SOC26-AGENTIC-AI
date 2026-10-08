TEST PLAN FOR seq_detector_0011 TESTBENCH

CLOCK AND RESET SEQUENCE:
1. Clock starts at 0, toggles every 0.55 ns (period 1.1 ns)
2. Reset held high (reset=1) from time 0
3. data_in held at 1 from time 0
4. Wait for 2 rising edges with reset=1
5. On the next falling edge: release reset (reset=0) AND begin step i=0

TESTBENCH EXECUTION PATTERN (on every falling edge):
- FIRST: check detected == expected_out[i]
- THEN: drive data_in = in[i]
- Never check at a rising edge or immediately after it

VECTOR 1: 16 bits
in  = 0001100110110010
out = 0000010001000000

Index | Input Bit | Expected Output | Reason
------|-----------|-----------------|-------
  0   |     0     |        0        | Initial state, no pattern yet
  1   |     0     |        0        | Bits so far: 0
  2   |     0     |        0        | Bits so far: 00
  3   |     1     |        0        | Bits so far: 001
  4   |     1     |        0        | Bits so far: 0011 (first "0011" complete, detected goes high next)
  5   |     0     |        1        | DETECTED: "0011" was completed at i=4
  6   |     0     |        0        | Bits so far: 00
  7   |     1     |        0        | Bits so far: 001
  8   |     1     |        0        | Bits so far: 0011 (second "0011" complete, detected goes high next)
  9   |     0     |        1        | DETECTED: "0011" was completed at i=8
 10   |     1     |        0        | Bits so far: 01
 11   |     1     |        0        | Bits so far: 011
 12   |     0     |        0        | Bits so far: 110
 13   |     0     |        0        | Bits so far: 100
 14   |     1     |        0        | Bits so far: 001
 15   |     0     |        0        | Bits so far: 0010

VECTOR 2: 15 bits (applied immediately after Vector 1, no reset)
in  = 001100110000011
out = 000010001000001

Index | Input Bit | Expected Output | Reason
------|-----------|-----------------|-------
  0   |     0     |        0        | Bits from end of V1: ...10, now 100
  1   |     0     |        0        | Bits so far: 00
  2   |     1     |        0        | Bits so far: 001
  3   |     1     |        0        | Bits so far: 0011 (third "0011" complete, detected goes high next)
  4   |     0     |        1        | DETECTED: "0011" was completed at i=3
  5   |     0     |        0        | Bits so far: 00
  6   |     1     |        0        | Bits so far: 001
  7   |     1     |        0        | Bits so far: 0011 (fourth "0011" complete, detected goes high next)
  8   |     0     |        1        | DETECTED: "0011" was completed at i=7
  9   |     0     |        0        | Bits so far: 00
 10   |     0     |        0        | Bits so far: 00
 11   |     0     |        0        | Bits so far: 00
 12   |     0     |        0        | Bits so far: 00
 13   |     1     |        0        | Bits so far: 001
 14   |     1     |        1        | Bits so far: 0011 (fifth "0011" complete, detected goes high next cycle)

BOUNDARY ANALYSIS (Vector 1 to Vector 2):
- Last 3 bits of Vector 1: 010
- First 4 bits of Vector 2: 0011
- Combined sequence: 0100011
- No "0011" pattern spans the boundary (would need 0011 exactly)
- No spurious detection occurs at the transition

FINAL CHECK:
- After Vector 2 index 14, perform one additional falling edge
- Check: detected == 0 (no detection pending)
- Then execute $finish

TESTBENCH CODING GUIDELINES:
1. Use reg [0:15] in_v1 = 16'b0001100110110010; (bit 0 is leftmost)
2. Use reg [0:14] in_v2 = 15'b001100110000011;
3. Use reg [0:15] out_v1 = 16'b0000010001000000;
4. Use reg [0:14] out_v2 = 15'b000010001000001;
5. Use for-loops with fixed iteration counts (no wait loops)
6. Print one line per check: TEST: PASS | Inputs: <bits> | Expected: <bit> | Output: <bit>
7. Or: TEST: FAIL | Inputs: <bits> | Expected: <bit> | Output: <bit>
8. The words PASS and FAIL must appear ONLY in uppercase in the output format
9. Use exactly one $finish at the end of the testbench
10. No timeout mechanisms needed (fixed iteration counts)