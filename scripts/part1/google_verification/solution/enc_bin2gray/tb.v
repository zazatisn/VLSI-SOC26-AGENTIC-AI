`timescale 1ns/1ps

module tb_enc_bin2gray();

    reg [9:0] bin;
    wire [9:0] gray;
    integer i;
    reg [9:0] expected;

    enc_bin2gray uut (
        .bin(bin),
        .gray(gray)
    );

    initial begin
        // Test set: boundary values and some patterns
        bin = 10'b0000000000; #10;
        expected = bin ^ (bin >> 1);
        if (gray !== expected) begin
            $display("TEST FAILED");
            $finish;
        end

        bin = 10'b1111111111; #10;
        expected = bin ^ (bin >> 1);
        if (gray !== expected) begin
            $display("TEST FAILED");
            $finish;
        end

        bin = 10'b1010101010; #10;
        expected = bin ^ (bin >> 1);
        if (gray !== expected) begin
            $display("TEST FAILED");
            $finish;
        end

        // Exhaustive verification of patterns is exhaustive for 10 bits, 
        // but for simulation efficiency in a testbench, we check a sequence.
        for (i = 0; i < 1024; i = i + 1) begin
            bin = i[9:0];
            #10;
            expected = bin ^ (bin >> 1);
            if (gray !== expected) begin
                $display("TEST FAILED");
                $finish;
            end
        end

        $display("TEST PASSED");
        $finish;
    end

endmodule