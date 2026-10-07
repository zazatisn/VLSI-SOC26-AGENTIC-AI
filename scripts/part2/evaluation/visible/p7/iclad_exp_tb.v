// Verilog-2001 Testbench for exp_fixed_point
`timescale 1ns/1ps

module test_exp_fixed_point;

  parameter WIDTH = 8;
  // localparam is supported in Verilog-2001
  localparam FRAC = WIDTH - 1;

  // Change 'logic' to 'reg' for drivers and 'wire' for DUT outputs
  reg clk;
  reg rst;
  reg enable;
  reg [WIDTH-1:0] x_in;
  wire [2*WIDTH-1:0] exp_out;
  reg [2*WIDTH-1:0] expected;
  reg [2*WIDTH-1:0] diff;

  // DUT instantiation using standard Verilog syntax
  exp_fixed_point #(.WIDTH(WIDTH)) dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .x_in(x_in),
    .exp_out(exp_out)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Function: standard Verilog function (remove 'automatic' and 'int')
  function [WIDTH-1:0] to_fixed;
    input [31:0] int_val; // Use 32-bit vector for integer input
    begin
      to_fixed = int_val << FRAC;
    end
  endfunction

  initial begin
    clk = 0;
    rst = 1;
    enable = 0;
    x_in = 0;

    @(negedge clk);
    rst = 0;

    // Apply input: x = 1.0 (128 in UQ1.7)
    x_in = to_fixed(1);  
    enable = 1;
    @(negedge clk);

    // Wait for pipeline stages
    repeat (3) @(negedge clk);

    // Expected result
    expected = 341;

    // Verilog absolute difference calculation
    diff = (exp_out > expected) ? (exp_out - expected) : (expected - exp_out);

    $display("exp(1.0) = %0d (expected approx %0d)", exp_out, expected);

    // Tolerance check using standard Verilog logic
    if (diff < (1 << (FRAC - 2)))
      $display("PASS");
    else
      $display("FAIL");

    $finish;
  end

endmodule