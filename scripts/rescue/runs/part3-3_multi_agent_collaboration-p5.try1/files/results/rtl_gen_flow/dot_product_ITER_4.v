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
    reg signed [2*WIDTH+3:0] sum_acc;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= {(2*WIDTH){1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                products_reg[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            dot_out <= {(2*WIDTH+4){1'b0}};
        end else begin
            sum_acc = 0;
            for (i = 0; i < N; i = i + 1) begin
                sum_acc = sum_acc + products_reg[i];
            end
            dot_out <= sum_acc;
        end
    end

endmodule