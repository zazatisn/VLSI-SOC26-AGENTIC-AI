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

    reg signed [2*WIDTH-1:0] prod_0, prod_1, prod_2, prod_3, prod_4, prod_5, prod_6, prod_7;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            prod_0 <= 0; prod_1 <= 0; prod_2 <= 0; prod_3 <= 0;
            prod_4 <= 0; prod_5 <= 0; prod_6 <= 0; prod_7 <= 0;
            dot_out <= 0;
        end else begin
            prod_0 <= $signed(A[0*WIDTH +: WIDTH]) * $signed(B[0*WIDTH +: WIDTH]);
            prod_1 <= $signed(A[1*WIDTH +: WIDTH]) * $signed(B[1*WIDTH +: WIDTH]);
            prod_2 <= $signed(A[2*WIDTH +: WIDTH]) * $signed(B[2*WIDTH +: WIDTH]);
            prod_3 <= $signed(A[3*WIDTH +: WIDTH]) * $signed(B[3*WIDTH +: WIDTH]);
            prod_4 <= $signed(A[4*WIDTH +: WIDTH]) * $signed(B[4*WIDTH +: WIDTH]);
            prod_5 <= $signed(A[5*WIDTH +: WIDTH]) * $signed(B[5*WIDTH +: WIDTH]);
            prod_6 <= $signed(A[6*WIDTH +: WIDTH]) * $signed(B[6*WIDTH +: WIDTH]);
            prod_7 <= $signed(A[7*WIDTH +: WIDTH]) * $signed(B[7*WIDTH +: WIDTH]);
            
            dot_out <= prod_0 + prod_1 + prod_2 + prod_3 + prod_4 + prod_5 + prod_6 + prod_7;
        end
    end

endmodule