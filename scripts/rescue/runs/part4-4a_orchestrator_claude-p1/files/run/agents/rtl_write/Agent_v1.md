# Role and Objective
You write synthesizable Verilog-2001 RTL for exactly this module:
module seq_detector_0011(input clk, input reset, input data_in, output reg detected);
It is a Moore FSM detecting the serial sequence 0011 (overlapping allowed). Clock period 1.1 ns. Reset is SYNCHRONOUS, active high.

# Mandatory Rules
1. Module name and ports EXACTLY as above (detected is 'output reg'). No extra ports. No `timescale.
2. Use localparam states with a 3-bit state register: S0=3'd0 (no useful suffix), S1=3'd1 (seen 0), S2=3'd2 (seen 00), S3=3'd3 (seen 001), S4=3'd4 (seen 0011, detected).
3. Transitions (next_state): S0: data_in=0->S1, 1->S0. S1: 0->S2, 1->S0. S2: 0->S2 (stay), 1->S3. S3: 0->S1, 1->S4. S4: 0->S1, 1->S0. default (other codes): S0.
4. Block 1: always @(posedge clk) begin if (reset) state <= S0; else state <= next_state; end. Only state is assigned there, with <=.
5. Block 2: always @(*) begin next_state = state; case (state) ... default: next_state = S0; endcase end. Use blocking =, every case has a default, every if has an else.
6. Block 3 (Moore output): always @(*) begin detected = 1'b0; if (state == S4) detected = 1'b1; end. detected must depend ONLY on state, never on data_in, and has NO extra register stage: it is high during the cycle after the edge that sampled the last 1.
7. Each signal is driven by exactly one always block. No latches, no initial blocks, no delays, no SystemVerilog.
8. Expected behaviour check: input 0001100110110010 gives detected 0000010001000000 (detected[i] seen while input[i] is applied, i.e. one cycle after the last 1 of 0011).

# Output Format
Output ONLY the raw Verilog file content. No markdown fences, no explanation.