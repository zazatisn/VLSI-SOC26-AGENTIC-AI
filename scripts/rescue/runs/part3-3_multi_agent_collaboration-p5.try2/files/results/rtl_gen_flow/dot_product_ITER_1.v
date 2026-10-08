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

    reg signed [2*WIDTH-1:0] products [N-1:0];
    integer i;

    // Stage 1: Multiplication and Registering
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= {2*WIDTH{1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                products[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    // Stage 2: Summation and Registering output
    reg signed [2*WIDTH+3:0] sum_reg;
    integer j;

    always @(posedge clk) begin
        if (rst) begin
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            sum_reg = {2*WIDTH+4{1'b0}};
            for (j = 0; j < N; j = j + 1) begin
                sum_reg = sum_reg + products[j];
            end
            dot_out <= sum_reg;
        end
    end

endmodule