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

    reg signed [2*WIDTH-1:0] products_reg [0:N-1];
    integer i;

    // Intermediate sum signal for pipeline stage transition
    reg signed [2*WIDTH+3:0] sum_staged;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= 0;
            end
            sum_staged <= 0;
            dot_out <= 0;
        end else begin
            // Stage 1: Multiplication
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end

            // Stage 2: Summation
            // Explicitly calculate sum in sequential block for clean 2-cycle pipeline
            sum_staged = 0;
            for (i = 0; i < N; i = i + 1) begin
                sum_staged = sum_staged + products_reg[i];
            end
            dot_out <= sum_staged;
        end
    end

endmodule