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

    reg signed [(2*WIDTH)*N-1:0] products_reg;
    integer i;

    // Intermediate wires for summation logic
    reg signed [2*WIDTH+3:0] sum_accum;

    always @(posedge clk) begin
        if (rst) begin
            products_reg <= {((2*WIDTH)*N){1'b0}};
            dot_out <= 0;
        end else begin
            // Stage 1: Multiply and register
            for (i = 0; i < N; i = i + 1) begin
                products_reg[(i*(2*WIDTH)) +: (2*WIDTH)] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end

            // Stage 2: Sum the registered products
            sum_accum = 0;
            for (i = 0; i < N; i = i + 1) begin
                sum_accum = sum_accum + products_reg[(i*(2*WIDTH)) +: (2*WIDTH)];
            end
            dot_out <= sum_accum;
        end
    end

endmodule