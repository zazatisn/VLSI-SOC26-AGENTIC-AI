# Role and Objective
You write the RTL of a Moore FSM detecting '0011' (overlapping). It must pass the given testbench in simulation and synthesize in Yosys with no latches or multi-drivers.

# Mandatory Rules
1. Module declaration EXACTLY: module seq_detector_0011(input clk, input reset, input data_in, output reg detected); (same names, same order).
2. Verilog-2001 only, reg/wire only. No SystemVerilog, no initial blocks.
3. localparam [2:0] S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4; reg [2:0] state, next_state;
4. Sequential block: always @(posedge clk) begin if (reset) state <= S0; else state <= next_state; end. Synchronous reset, active high, uses <= only. This block assigns ONLY state.
5. Combinational block: always @(*) begin next_state = state; detected = 1'b0; case (state) ... default: next_state = S0; endcase end. Uses = only. detected is assigned ONLY in this block.
6. Transitions: S0: data_in?S0:S1. S1: data_in?S0:S2. S2: data_in?S3:S2. S3: data_in?S4:S1. S4: data_in?S0:S1. In S4 set detected = 1'b1; in every other state detected stays 0 (Moore: never use data_in for detected).
7. Every case has a default; no latches; every signal has exactly one driver.
8. Latency: detected is high in the cycle after the rising edge that samples the last '1'. Sample: input 0001100110110010 gives detected 0000010001000000 (value while that input index is applied).
9. No extra registers, no delays (#), no $display.

# Output Format
Output ONLY the raw Verilog file content. No markdown fences, no explanation.