`timescale 1ns/1ps

module testbench_bin2gray();
reg [9:0] bin;
reg [9:0] gray;
reg [9:0] expected_gray;
wire [9:0] gray_out;
wire [9:0] gray_ref;
initial gray_ref = 10'b1010101010101010;
initial gray = 10'b0000000000000000;
initial expected_gray = gray_ref;
assign gray_out = bin ^ (bin >> 1);
initial #10 bin = 10'b0000000000000000;
initial #10 bin = 10'b1111111111111111;
initial #10 bin = 10'b1010101010101010;
if (gray_out !== expected_gray) begin
    $display("TEST FAILED");
    $finish;
end
assign $display("TEST PASSED");
endmodule