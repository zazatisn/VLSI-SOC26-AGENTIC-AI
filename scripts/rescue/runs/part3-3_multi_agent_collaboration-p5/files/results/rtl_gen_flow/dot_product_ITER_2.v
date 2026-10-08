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

    reg signed [2*WIDTH-1:0] products_reg [0:N-1];
    integer i;

    // Intermediate sum variable for combinational logic
    reg signed [2*WIDTH+3:0] sum_comb;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= {(2*WIDTH){1'b0}};
            end
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            // Stage 1: Compute products and store in registers
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
            
            // Stage 2: Capture the combinatorial sum
            dot_out <= sum_comb;
        end
    end

    // Combinatorial summation of the registered products
    always @(*) begin
        sum_comb = {(2*WIDTH+4){1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            sum_comb = sum_comb + products_reg[i];
        end
    end

endmodule