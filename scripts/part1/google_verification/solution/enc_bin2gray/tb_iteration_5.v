`timescale 1ns/1ps

module enc_bin2gray(uut);

reg [9:0] bin;
wire [9:0] gray;
reg [9:0] gray_temp;
integer i;

initial begin
    bin = 10'b0000000000; // Gray code 0000000000
    gray_temp = 10'b0000000000;
    #1 
    for (i = 0; i < 1024; i = i + 1) begin
        bin = i;
        gray = bin ^ (bin >> 1);
        #1 
        if (gray !== gray_temp) begin
            $display("TEST FAILED");
            $finish;
        end
    end
    #1 
    if (gray !== gray_temp) begin
        $display("TEST FAILED");
        $finish;
    end
    #1 
    $display("TEST PASSED");
    $finish;
endmodule