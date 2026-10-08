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

    reg signed [2*WIDTH-1:0] products_reg [N-1:0];
    integer i;
    reg signed [2*WIDTH+3:0] sum_temp;

    // Stage 1: Multiplication - Registered
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= {(2*WIDTH){1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    // Stage 2: Summation - Registered
    always @(posedge clk) begin
        if (rst) begin
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            sum_temp = 0;
            for (i = 0; i < N; i = i + 1) begin
                sum_temp = sum_temp + products_reg[i];
            end
            dot_out <= sum_temp;
        end
    end

endmodule