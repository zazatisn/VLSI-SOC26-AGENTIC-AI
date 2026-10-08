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

    reg signed [2*WIDTH-1:0] products [0:N-1];
    integer i;
    reg signed [2*WIDTH+3:0] sum_tmp;

    // Stage 1: Multiplication
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= 0;
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    // Stage 2: Summation
    always @(posedge clk) begin
        if (rst) begin
            dot_out <= 0;
        end else begin
            sum_tmp = 0;
            for (i = 0; i < N; i = i + 1) begin
                sum_tmp = sum_tmp + products[i];
            end
            dot_out <= sum_tmp;
        end
    end

endmodule