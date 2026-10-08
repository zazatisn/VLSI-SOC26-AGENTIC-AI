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
    reg signed [2*WIDTH-1:0] products [N-1:0];
    reg signed [2*WIDTH+3:0] sum_reg;

    // Stage 1: Capture products in registers at first clock edge
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

    // Stage 2: Sum the registered products and capture in dot_out
    always @(posedge clk) begin
        if (rst) begin
            dot_out <= {2*WIDTH+4{1'b0}};
        end else begin
            sum_reg = {2*WIDTH+4{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                sum_reg = sum_reg + products[i];
            end
            dot_out <= sum_reg;
        end
    end

endmodule