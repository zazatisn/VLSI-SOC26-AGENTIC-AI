`timescale 1ns/1ps

module tb_enc_bin2onehot();

reg clk;
reg rst;
reg in_valid;
reg [3:0] in;
wire [14:0] out;
integer i;
reg [14:0] expected;

enc_bin2onehot uut (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .in(in),
    .out(out)
);

initial begin
    // Initialize signals
    clk = 0;
    rst = 0;
    in_valid = 0;
    in = 0;

    // Test Case 1: in_valid low
    in_valid = 0;
    in = 4'd5;
    #10;
    if (out !== 15'b0) begin
        $display("TEST FAILED");
        $finish;
    end

    // Test Case 2: Iterate through all valid inputs (0-14)
    for (i = 0; i <= 14; i = i + 1) begin
        in_valid = 1;
        in = i[3:0];
        expected = (1 << i);
        #10;
        if (out !== expected) begin
            $display("TEST FAILED");
            $finish;
        end
    end

    // Test Case 3: Verify de-assertion again
    in_valid = 0;
    in = 4'd10;
    #10;
    if (out !== 15'b0) begin
        $display("TEST FAILED");
        $finish;
    end

    $display("TEST PASSED");
    $finish;
end

endmodule