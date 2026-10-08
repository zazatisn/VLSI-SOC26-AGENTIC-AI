`timescale 1ns/1ps

module tb_seq_detector_0011;
  reg clk;
  reg reset;
  reg data_in;
  wire detected;
  reg [0:15] in_bits;
  reg [0:15] exp_bits;
  integer i;

  seq_detector_0011 dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .detected(detected)
  );

  initial begin
    clk = 0;
  end

  always #0.55 begin
    clk = ~clk;
  end

  initial begin
    in_bits = 16'b0001100110110010;
    exp_bits = 16'b0000010001000000;
    reset = 1;
    data_in = 1;
    
    @(posedge clk);
    @(posedge clk);
    
    @(negedge clk);
    reset = 0;
    
    for (i = 0; i < 16; i = i + 1) begin
      @(negedge clk);
      if (detected !== exp_bits[i]) begin
        $display("TEST: FAIL | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", data_in, i, exp_bits[i], detected);
      end else begin
        $display("TEST: PASS | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", data_in, i, exp_bits[i], detected);
      end
      data_in = in_bits[i];
    end
    
    @(negedge clk);
    $finish;
  end

endmodule