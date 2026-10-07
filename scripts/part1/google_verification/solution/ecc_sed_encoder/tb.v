`timescale 1ns/1ps

module testbench;
  reg clk;
  reg rst;
  reg data_valid;
  reg [11:0] data;
  wire enc_valid;
  wire [12:0] enc_codeword;
  
  integer i;
  integer j;
  integer parity_count;
  integer expected_parity;
  integer actual_parity;
  integer test_vector;
  
  // Instantiate the Unit Under Test
  ecc_sed_encoder uut (
    .clk(clk),
    .rst(rst),
    .data_valid(data_valid),
    .enc_valid(enc_valid),
    .data(data),
    .enc_codeword(enc_codeword)
  );
  
  initial begin
    // Initialize signals
    clk = 0;
    rst = 1;
    data_valid = 0;
    data = 12'b0;
    
    // Release reset
    #10 rst = 0;
    
    // Test 1: All zeros
    #10;
    data = 12'b0;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'b0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[12] !== 1'b0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 2: All ones
    #10;
    data = 12'hFFF;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'hFFF) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[12] !== 1'b0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 3: Single bit set (bit 0)
    #10;
    data = 12'b1;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'b1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[12] !== 1'b1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 4: Single bit set (bit 11)
    #10;
    data = 12'h800;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'h800) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[12] !== 1'b1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 5: Alternating pattern 0xAAA (10101010...)
    #10;
    data = 12'hAAA;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'hAAA) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 6: Alternating pattern 0x555 (01010101...)
    #10;
    data = 12'h555;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'h555) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 7: Random pattern 0x7B3
    #10;
    data = 12'h7B3;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'h7B3) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 8: data_valid = 0, enc_valid should be 0
    #10;
    data = 12'hFFF;
    data_valid = 0;
    #10;
    
    if (enc_valid !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 9: Another random pattern 0x3C7
    #10;
    data = 12'h3C7;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'h3C7) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    // Test 10: Pattern with 6 ones (even parity, parity bit should be 0)
    #10;
    data = 12'h03F;
    data_valid = 1;
    #10;
    
    if (enc_valid !== 1) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[11:0] !== 12'h03F) begin
      $display("TEST FAILED");
      $finish;
    end
    
    if (enc_codeword[12] !== 1'b0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    parity_count = 0;
    for (i = 0; i < 13; i = i + 1) begin
      if (enc_codeword[i] == 1'b1) begin
        parity_count = parity_count + 1;
      end
    end
    if (parity_count % 2 !== 0) begin
      $display("TEST FAILED");
      $finish;
    end
    
    #10;
    $display("TEST PASSED");
    $finish;
  end
  
  always #5 clk = ~clk;

endmodule