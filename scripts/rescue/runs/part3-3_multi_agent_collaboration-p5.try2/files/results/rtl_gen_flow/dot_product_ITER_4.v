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

    reg signed [2*WIDTH-1:0] prods_reg [0:N-1];
    integer i;

    // Stage 1: Multiplication
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                prods_reg[i] <= {2*WIDTH{1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                prods_reg[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    // Stage 2: Summation
    integer j;
    reg signed [2*WIDTH+3:0] sum_val;

    always @(posedge clk) begin
        if (rst) begin
            dot_out <= 0;
        end else begin
            sum_val = 0;
            for (j = 0; j < N; j = j + 1) begin
                sum_val = sum_val + prods_reg[j];
            end
            dot_out <= sum_val;
        end
    end

endmodule