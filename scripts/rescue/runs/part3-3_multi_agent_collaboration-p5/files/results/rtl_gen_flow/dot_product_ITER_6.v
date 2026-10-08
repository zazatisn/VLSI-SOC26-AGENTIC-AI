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

    reg signed [2*WIDTH-1:0] mult_regs [N-1:0];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                mult_regs[i] <= {(2*WIDTH){1'b0}};
            end
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            // Stage 1: Products
            for (i = 0; i < N; i = i + 1) begin
                mult_regs[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end

            // Stage 2: Summation
            begin
                reg signed [2*WIDTH+3:0] sum_acc;
                sum_acc = {(2*WIDTH+4){1'b0}};
                for (i = 0; i < N; i = i + 1) begin
                    sum_acc = sum_acc + mult_regs[i];
                end
                dot_out <= sum_acc;
            end
        end
    end

endmodule