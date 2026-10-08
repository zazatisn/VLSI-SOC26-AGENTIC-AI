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

    integer i;
    reg signed [2*WIDTH-1:0] product_pipe [N-1:0];
    reg signed [2*WIDTH+3:0] sum_accum;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                product_pipe[i] <= {2*WIDTH{1'b0}};
            end
            dot_out <= {2*WIDTH+4{1'b0}};
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                product_pipe[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end

            sum_accum = {2*WIDTH+4{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                sum_accum = sum_accum + product_pipe[i];
            end
            dot_out <= sum_accum;
        end
    end

endmodule