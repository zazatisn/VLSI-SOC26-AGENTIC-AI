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

    // Stage 1 registers for products
    reg signed [2*WIDTH-1:0] prods_reg [0:N-1];
    
    integer i;
    
    // Stage 1 Logic: Multiplication
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                prods_reg[i] <= {(2*WIDTH){1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                prods_reg[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    // Stage 2 Logic: Summation and Output register
    reg signed [2*WIDTH+3:0] sum_tmp;
    integer k;
    
    always @(posedge clk) begin
        if (rst) begin
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            sum_tmp = {(2*WIDTH+4){1'b0}};
            for (k = 0; k < N; k = k + 1) begin
                sum_tmp = sum_tmp + prods_reg[k];
            end
            dot_out <= sum_tmp;
        end
    end

endmodule