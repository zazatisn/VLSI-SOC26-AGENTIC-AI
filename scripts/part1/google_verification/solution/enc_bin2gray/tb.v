`timescale 1ns/1ps

module testbench_enc_bin2gray;

    reg [9:0] bin;
    wire [9:0] gray;
    reg [9:0] expected_gray;
    integer i, j;
    reg [9:0] test_vectors [0:19];

    // Instantiate the Unit Under Test
    enc_bin2gray uut (
        .bin(bin),
        .gray(gray)
    );

    initial begin
        // Initialize test vectors
        test_vectors[0] = 10'b0000000000;  // 0
        test_vectors[1] = 10'b0000000001;  // 1
        test_vectors[2] = 10'b0000000010;  // 2
        test_vectors[3] = 10'b0000000011;  // 3
        test_vectors[4] = 10'b0000000100;  // 4
        test_vectors[5] = 10'b0000000101;  // 5
        test_vectors[6] = 10'b0000001111;  // 15
        test_vectors[7] = 10'b0000010000;  // 16
        test_vectors[8] = 10'b0000100000;  // 32
        test_vectors[9] = 10'b0001000000;  // 64
        test_vectors[10] = 10'b0010000000; // 128
        test_vectors[11] = 10'b0100000000; // 256
        test_vectors[12] = 10'b1000000000; // 512
        test_vectors[13] = 10'b1111111111; // 1023
        test_vectors[14] = 10'b1010101010; // 682
        test_vectors[15] = 10'b0101010101; // 341
        test_vectors[16] = 10'b1100110011; // 819
        test_vectors[17] = 10'b0011001100; // 204
        test_vectors[18] = 10'b1111000000; // 960
        test_vectors[19] = 10'b0000111111; // 63

        // Run test vectors
        for (i = 0; i < 20; i = i + 1) begin
            bin = test_vectors[i];
            #10;  // Allow combinatorial logic to settle

            // Calculate expected Gray code
            expected_gray = bin ^ (bin >> 1);

            // Check if output matches expected value
            if (gray !== expected_gray) begin
                $display("TEST FAILED");
                $display("Input: %b, Expected: %b, Got: %b", bin, expected_gray, gray);
                $finish;
            end
        end

        // Additional sequential test from 0 to 255
        for (i = 0; i < 256; i = i + 1) begin
            bin = i[9:0];
            #10;

            // Calculate expected Gray code
            expected_gray = bin ^ (bin >> 1);

            // Check if output matches expected value
            if (gray !== expected_gray) begin
                $display("TEST FAILED");
                $display("Input: %b, Expected: %b, Got: %b", bin, expected_gray, gray);
                $finish;
            end
        end

        // Test high-range values
        for (i = 256; i < 1024; i = i + 64) begin
            bin = i[9:0];
            #10;

            // Calculate expected Gray code
            expected_gray = bin ^ (bin >> 1);

            // Check if output matches expected value
            if (gray !== expected_gray) begin
                $display("TEST FAILED");
                $display("Input: %b, Expected: %b, Got: %b", bin, expected_gray, gray);
                $finish;
            end
        end

        $display("TEST PASSED");
        $finish;
    end

endmodule