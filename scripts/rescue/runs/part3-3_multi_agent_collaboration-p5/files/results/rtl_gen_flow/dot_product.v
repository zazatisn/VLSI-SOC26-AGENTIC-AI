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
    
    // Stage 1 registers for individual products
    reg signed [2*WIDTH-1:0] prod_stage [0:N-1];
    
    // Stage 2: Combinational sum of Stage 1 products, 
    // then registered into dot_out
    reg signed [2*WIDTH+3:0] sum_reg;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                prod_stage[i] <= 0;
            end
            sum_reg <= 0;
            dot_out <= 0;
        end else begin
            // Stage 1: Pipeline multiplication
            for (i = 0; i < N; i = i + 1) begin
                prod_stage[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
            
            // Stage 2: Pipeline summation
            sum_reg <= prod_stage[0] + prod_stage[1] + prod_stage[2] + prod_stage[3] + 
                       prod_stage[4] + prod_stage[5] + prod_stage[6] + prod_stage[7];
                       
            dot_out <= sum_reg;
        end
    end

endmodule