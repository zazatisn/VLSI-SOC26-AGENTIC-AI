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

    reg signed [2*WIDTH-1:0] stage1_prods [0:N-1];
    integer i;
    reg signed [2*WIDTH+3:0] sum_temp;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                stage1_prods[i] <= 0;
            end
            dot_out <= 0;
        end else begin
            // Stage 1: Pipeline the products
            for (i = 0; i < N; i = i + 1) begin
                stage1_prods[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
            
            // Stage 2: Sum the registered products
            sum_temp = 0;
            for (i = 0; i < N; i = i + 1) begin
                sum_temp = sum_temp + stage1_prods[i];
            end
            dot_out <= sum_temp;
        end
    end

endmodule