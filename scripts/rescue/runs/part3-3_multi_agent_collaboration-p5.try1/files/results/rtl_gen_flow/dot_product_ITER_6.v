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

    reg signed [2*WIDTH-1:0] prod_stage [0:N-1];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                prod_stage[i] <= 0;
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                prod_stage[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            dot_out <= 0;
        end else begin
            dot_out <= 0;
            for (i = 0; i < N; i = i + 1) begin
                dot_out <= dot_out + prod_stage[i];
            end
        end
    end

endmodule