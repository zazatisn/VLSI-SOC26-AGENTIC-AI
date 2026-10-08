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

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= 0;
            end
            dot_out <= 0;
        end else begin
            // Stage 1: Register products
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end

            // Stage 2: Sum products and register output
            begin
                reg signed [2*WIDTH+3:0] sum_temp;
                sum_temp = 0;
                for (i = 0; i < N; i = i + 1) begin
                    sum_temp = sum_temp + products[i];
                end
                dot_out <= sum_temp;
            end
        end
    end

endmodule