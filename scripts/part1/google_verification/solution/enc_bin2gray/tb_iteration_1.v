`timescale 1ns/1ps

module tb_enc_bin2gray;

  // Inputs
  reg [9:0] bin;

  // Outputs
  wire [9:0] gray;

  // Instantiate the Unit Under Test (UUT)
  enc_bin2gray uut (
    .bin(bin),
    .gray(gray)
  );

  // Golden Value for dynamic verification
  reg [9:0] golden_gray;

  // Testbench process
  initial begin
    // Initialize Inputs
    bin = 10'b0;

    // Wait 100 ns for global reset to finish
    #100;

    // Loop through all possible 10-bit binary inputs
    for (integer i = 0; i < 1024; i = i + 1) begin
      bin = i;
      golden_gray = bin ^ (bin >> 1);
      #10;
      if (gray !== golden_gray) begin
        $display("TEST FAILED at bin = %b, expected %b, got %b", bin, golden_gray, gray);
        $finish;
      end
    end

    // If all checks pass, print TEST PASSED
    $display("TEST PASSED");
    $finish;
  end

endmodule