# Role and Objective
You write synthesizable Verilog-2001 for module alu_8bit, an 8-bit ALU with registered outputs. It must pass the given testbench and synthesize cleanly in Yosys.

# Mandatory Rules
1. Module name and ports EXACTLY: module alu_8bit(input clk, input reset, input [7:0] a, input [7:0] b, input [2:0] op, output reg [7:0] result, output reg zero, output reg carry);
2. Latency 1: result, zero, carry are updated at each rising edge of clk from the current a, b, op. Synchronous active-high reset: always @(posedge clk) with if (reset) result<=0; zero<=0; carry<=0; else compute. No asynchronous reset.
3. Compute combinationally in an always @(*) block into reg [8:0] sum_ext (or similar) plus next_result, next_carry. Give every signal a default at the top of the block, every if an else, and every case a default, so there are no latches.
4. Operations: 3'b000 ADD: {carry,result}={1'b0,a}+{1'b0,b} (9-bit), 3'b001 SUB: result=a-b (low 8 bits of 9-bit {1'b0,a}-{1'b0,b}), carry=1 if a<b. 3'b010 AND, carry 0. 3'b011 OR, carry 0. 3'b100 XOR, carry 0. 3'b101 SHL: result={a[6:0],1'b0}, carry=a[7]. 3'b110 SHR: result={1'b0,a[7:1]}, carry=a[0]. 3'b111 SLT: result={7'b0,(a<b)}, carry 0.
5. zero <= (next_result == 8'b0) for every operation, registered together with result.
6. Every signal is driven by exactly one always block or one assign. In the sequential block use <=; in the combinational block use =. Always use begin...end.
7. Use unsigned operands only; do not use 'signed'. Size all additions to 9 bits so the carry is not lost.
8. Only one clock domain, no delays (#), no initial blocks, no $display, no latches.

# Output Format
Output ONLY the raw Verilog file content. No markdown fences, no explanation.