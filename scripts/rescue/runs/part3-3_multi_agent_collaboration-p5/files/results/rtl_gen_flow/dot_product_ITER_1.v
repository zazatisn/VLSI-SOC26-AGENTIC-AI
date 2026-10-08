`timescale 1ns/1ps

module dot_product #(
    parameter N = 8,
    parameter WIDTH = 8
) (
    input                           clk,
    input                           rst,
    input      signed [N*WIDTH-1:0] A,
    input      signed [N*WIDTH-1:0] B,
    output reg signed [2*WIDTH+3:0] dot_out
);

    integer i;

    // Intermediate registers for pipeline stages
    reg signed [2*WIDTH-1:0] products [N-1:0];
    reg signed [2*WIDTH+3:0] sum_reg;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= {2*WIDTH{1'b0}};
            end
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            // Stage 1: Multiply and store in pipeline registers
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
            
            // Stage 2: Sum products and update output
            dot_out <= sum_reg;
        end
    end

    // Combinatorial summation logic for Stage 2
    always @(*) begin
        sum_reg = {(2*WIDTH+4){1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            sum_reg = sum_reg + products[i];
        end
    end

endmodule