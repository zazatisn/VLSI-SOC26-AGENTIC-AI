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
for (integer i = 0; i <= 1023; i++) begin
    bin = i;
    expected_gray = bin ^ (bin >> 1);
    if (gray_out !== expected_gray) begin
        $display("TEST FAILED");
        $finish;
    end else begin
        $display("TEST PASSED");
    end
end
endmodule