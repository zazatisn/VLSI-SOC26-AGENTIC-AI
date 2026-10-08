`timescale 1ns/1ps

module alu_8bit(
    input            clk,
    input            reset,
    input      [7:0] a,
    input      [7:0] b,
    input      [2:0] op,
    output reg [7:0] result,
    output reg       zero,
    output reg       carry
);

    reg [7:0] next_result;
    reg next_carry;

    // Combinational logic to compute next_result and next_carry
    always @(*) begin
        next_result = 8'b0;
        next_carry = 1'b0;

        case (op)
            3'b000: begin  // ADD
                {next_carry, next_result} = {1'b0, a} + {1'b0, b};
            end
            3'b001: begin  // SUB
                next_result = a - b;
                next_carry = (a < b) ? 1'b1 : 1'b0;
            end
            3'b010: begin  // AND
                next_result = a & b;
                next_carry = 1'b0;
            end
            3'b011: begin  // OR
                next_result = a | b;
                next_carry = 1'b0;
            end
            3'b100: begin  // XOR
                next_result = a ^ b;
                next_carry = 1'b0;
            end
            3'b101: begin  // SHL
                next_result = {a[6:0], 1'b0};
                next_carry = a[7];
            end
            3'b110: begin  // SHR
                next_result = {1'b0, a[7:1]};
                next_carry = a[0];
            end
            3'b111: begin  // SLT
                next_result = (a < b) ? 8'b1 : 8'b0;
                next_carry = 1'b0;
            end
            default: begin
                next_result = 8'b0;
                next_carry = 1'b0;
            end
        endcase
    end

    // Sequential logic to register result, zero, and carry
    always @(posedge clk) begin
        if (reset) begin
            result <= 8'b0;
            zero <= 1'b0;
            carry <= 1'b0;
        end else begin
            result <= next_result;
            zero <= (next_result == 8'b0) ? 1'b1 : 1'b0;
            carry <= next_carry;
        end
    end

endmodule