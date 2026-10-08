// Reference testbench for exp_fixed_point (p7).
// Starts with the official ICLAD 2025 case (x = 1.0 -> 341), then all 256 input values streamed
// one per cycle, enable = 0 (hold) and reset. Expected: the 3-term Taylor value in UQ9.7,
// accepted within +/-8 as the specification allows.
`timescale 1ns/1ps

module test_exp_fixed_point;
  parameter WIDTH = 8;
  reg clk, rst, enable;
  reg [WIDTH-1:0] x_in;
  wire [2*WIDTH-1:0] exp_out;
  integer k, errors, expected, diff;
  real x;

  exp_fixed_point #(.WIDTH(WIDTH)) dut (.clk(clk), .rst(rst), .enable(enable), .x_in(x_in), .exp_out(exp_out));

  initial clk = 0;
  always #5 clk = ~clk;

  function integer taylor;            // round(128 * (1 + x + x^2/2 + x^3/6)), x = v / 128
    input integer v;
    real xr;
    begin
      xr = v / 128.0;
      taylor = $rtoi(128.0 * (1.0 + xr + xr*xr/2.0 + xr*xr*xr/6.0) + 0.5);
    end
  endfunction

  task check;
    input integer v;
    input integer exp_val;
    begin
      diff = exp_out - exp_val;
      if (diff < 0) diff = -diff;
      if (diff > 8) begin
        $display("ERROR: x_in=%0d exp_out=%0d expected=%0d (+/-8)", v, exp_out, exp_val);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    errors = 0;
    rst = 1; enable = 0; x_in = 0;
    @(negedge clk); @(negedge clk);
    if (exp_out !== 0) begin $display("ERROR: exp_out=%0d during reset", exp_out); errors = errors + 1; end
    rst = 0;

    // Official case: x = 1.0 -> 341
    x_in = 128; enable = 1;
    repeat (2) @(negedge clk);
    check(128, 341);
    $display("exp(1.0) = %0d (expected approx 341)", exp_out);

    // All 256 inputs, one per cycle: the result for input k is visible 2 falling edges later
    for (k = 0; k < 258; k = k + 1) begin
      if (k >= 2) check(k - 2, taylor(k - 2));
      x_in = (k < 256) ? k : 0;
      @(negedge clk);
    end

    // enable = 0 holds the output
    x_in = 64; enable = 1; repeat (2) @(negedge clk); check(64, 211);
    enable = 0; x_in = 255; repeat (3) @(negedge clk); check(64, 211);

    // reset clears the output
    rst = 1; @(negedge clk);
    if (exp_out !== 0) begin $display("ERROR: exp_out=%0d after reset", exp_out); errors = errors + 1; end

    if (errors == 0) $display("Test PASSED!");
    else             $display("Test FAILED: %0d errors found.", errors);
    $finish;
  end
endmodule
