ARCHITECTURE NOTES: seq_detector_0011 Moore FSM

STATE DEFINITION (3-bit encoding, localparam):
  S0 = 3'd0  (initial, no progress toward "0011")
  S1 = 3'd1  (seen "0", first bit of pattern)
  S2 = 3'd2  (seen "00", first two bits)
  S3 = 3'd3  (seen "001", first three bits)
  S4 = 3'd4  (seen "0011", pattern complete, detected=1)
  Unused: 3'd5, 3'd6, 3'd7 (default to S0)

STATE REGISTER:
  reg [2:0] state;
  Updated synchronously on posedge clk
  Reset: if (reset) state <= S0; (synchronous, active high)

TRANSITION TABLE (state, data_in -> next_state):
  S0: data_in=0 -> S1  (start pattern)
         data_in=1 -> S0  (stay, no progress)
  S1: data_in=0 -> S2  (continue pattern)
         data_in=1 -> S0  (mismatch: "0" + "1" ≠ "0011" prefix; fallback to S0)
  S2: data_in=0 -> S2  (mismatch: "00" + "0" ≠ "0011" prefix; "00" is longest suffix of "00" that is prefix of "0011", so stay in S2)
         data_in=1 -> S3  (continue pattern)
  S3: data_in=0 -> S1  (mismatch: "001" + "0" ≠ "0011"; longest suffix "0" is prefix of "0011", go to S1)
         data_in=1 -> S4  (pattern complete)
  S4: data_in=0 -> S1  (overlap: "0011" + "0" starts new pattern "0", go to S1)
         data_in=1 -> S0  (mismatch: "0011" + "1" ≠ "0011" prefix; fallback to S0)
  Default (5,6,7): -> S0

SUFFIX-PREFIX FALLBACK LOGIC:
  On input mismatch, transition to the state representing the longest suffix of the current sequence that is also a prefix of "0011":
  - S1 + "1": suffix "" (empty) -> S0
  - S2 + "0": suffix "00" is prefix of "0011" -> stay S2
  - S3 + "0": suffix "0" is prefix of "0011" -> S1
  - S4 + "0": suffix "0" is prefix of "0011" -> S1 (enables overlap)
  - S4 + "1": suffix "" -> S0

OUTPUT LOGIC (Moore, combinational):
  detected = 1 only when state == S4
  detected = 0 in all other states
  No dependence on data_in

TIMING & LATENCY:
  - detected is high during the clock cycle AFTER the rising edge that samples the last '1' of "0011"
  - Example: indices 2,3,4,5 sample "0,0,1,1"; detected is high at index 5 (after the edge that sampled the '1' at index 5)
  - Overlap: after S4 with data_in=0, FSM goes to S1, allowing immediate detection of the next "0011"

LOGIC DEPTH (SkyWater 130HD optimization):
  - State update: mux tree (3-bit state, 5 active codes) = ~2 levels of logic
  - Next-state decode: case statement with 5 branches = ~2 levels
  - Output: simple equality check (state == S4) = 1 level
  - Total: ~3-4 levels, acceptable for 1.1ns with proper gate sizing

TEST PLAN CONFIRMATION:
  Sample input:  0001100110110010
  Sample output: 0000010001000000
  - Indices 2,3,4,5 = "0011" -> detected at index 5 ✓
  - Indices 6,7,8,9 = "0011" -> detected at index 9 ✓
  - All other indices: detected = 0 ✓

IMPLEMENTATION STRUCTURE:
  Block 1 (clocked, posedge clk):
    - Update state register
    - Apply synchronous reset
  Block 2 (combinational, always @(*)):
    - Default: next_state = state, detected = 1'b0
    - case(state) with 5 branches + default
    - Assign detected = (state == S4)