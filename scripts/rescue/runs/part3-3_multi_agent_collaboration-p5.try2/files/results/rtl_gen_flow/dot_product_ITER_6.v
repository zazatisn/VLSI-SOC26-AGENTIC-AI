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

    reg signed [2*WIDTH-1:0] prods [0:N-1];
    integer i;
    integer j;
    reg signed [2*WIDTH+3:0] sum_next;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                prods[i] <= 0;
            end
            dot_out <= 0;
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                prods[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
            
            sum_next = 0;
            for (j = 0; j < N; j = j + 1) begin
                sum_next = sum_next + prods[j];
            end
            dot_out <= sum_next;
        end
    end

endmodule