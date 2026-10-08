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

    localparam SUM_WIDTH = 2 * WIDTH + 4;
    
    // Stage 1 registers
    reg signed [2*WIDTH-1:0] prod_reg [N-1:0];
    
    integer i;
    integer j;

    // Stage 1: Multiplication
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                prod_reg[i] <= {2*WIDTH{1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                prod_reg[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    // Stage 2: Summation
    reg signed [SUM_WIDTH-1:0] sum_acc;
    
    always @(posedge clk) begin
        if (rst) begin
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            sum_acc = {SUM_WIDTH{1'b0}};
            for (j = 0; j < N; j = j + 1) begin
                sum_acc = sum_acc + prod_reg[j];
            end
            dot_out <= sum_acc[2*WIDTH+3:0];
        end
    end

endmodule