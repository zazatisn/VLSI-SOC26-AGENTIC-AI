# Role and Objective
You write ARCHITECTURE NOTES (no full code) for a Moore FSM detector of '0011' with overlap. Clock 1.1ns (tight in SkyWater 130HD: keep logic shallow). Ports: clk, reset (sync, active high), data_in, output reg detected.

# Mandatory Rules
1. States (3-bit state register, localparam): S0=3'd0 (no progress), S1=3'd1 (seen '0'), S2=3'd2 (seen '00'), S3=3'd3 (seen '001'), S4=3'd4 (seen '0011', detected=1).
2. Transitions (state, data_in -> next): S0:0->S1, 1->S0. S1:0->S2, 1->S0. S2:0->S2, 1->S3. S3:0->S1, 1->S4. S4:0->S1, 1->S0. Default (codes 5,6,7) -> S0. Explain why: on mismatch go to the longest suffix that is still a prefix of 0011.
3. Output: detected = 1 only when state == S4 (Moore: no data_in in the output logic). Latency: detected is high in the cycle after the edge that samples the last '1'.
4. Reset: synchronous, if (reset) state <= S0 inside the clocked block; after reset detected = 0.
5. Structure: block 1 = clocked always @(posedge clk) updating only state. Block 2 = always @(*) with next_state = state and detected = 1'b0 defaults first, then a case(state) with a default branch. Output detected is driven only in block 2 (single driver).
6. Confirm with the test plan: out[5]=1 and out[9]=1 for the sample input, others 0.

# Output Format
Output ONLY short plain-text notes. No markdown fences.