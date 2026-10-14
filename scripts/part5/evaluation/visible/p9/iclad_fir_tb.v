// Reference testbench for fir_filter (p9).
// Starts with the official ICLAD 2025 test (x = 1..16, h = 1..8), then signed random coefficients
// and samples (including the extreme values) and a reset in the middle. Latency 1:
// drive x_in on a falling edge, check y_out on the next falling edge.
`timescale 1ns/1ps

module test_fir_filter;
  parameter WIDTH = 16;
  parameter N = 8;
  localparam OW = 2*WIDTH + $clog2(N);

  reg clk, rst;
  reg signed [WIDTH-1:0] x_in;
  reg signed [N*WIDTH-1:0] h;
  wire signed [OW-1:0] y_out;

  reg signed [WIDTH-1:0] hist [0:N-1];     // model: hist[0] = current sample
  reg signed [WIDTH-1:0] hj;
  reg signed [OW-1:0] expected;
  integer i, j, errors;

  fir_filter #(.WIDTH(WIDTH), .N(N)) dut (.clk(clk), .rst(rst), .x_in(x_in), .h(h), .y_out(y_out));

  initial clk = 0;
  always #5 clk = ~clk;

  task step;
    input r;
    input signed [WIDTH-1:0] x;
    begin
      rst = r; x_in = x;
      @(negedge clk);
      if (r) begin
        for (j = 0; j < N; j = j + 1) hist[j] = 0;
        expected = 0;
      end else begin
        for (j = N-1; j > 0; j = j - 1) hist[j] = hist[j-1];
        hist[0] = x;
        expected = 0;
        for (j = 0; j < N; j = j + 1) begin
          hj = h[j*WIDTH +: WIDTH];
          expected = expected + hj * hist[j];
        end
      end
      if (y_out !== expected) begin
        $display("ERROR: x_in=%0d y_out=%0d expected=%0d", x, y_out, expected);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    errors = 0;
    for (j = 0; j < N; j = j + 1) begin hist[j] = 0; h[j*WIDTH +: WIDTH] = j + 1; end
    rst = 1; x_in = 0;
    @(negedge clk);
    step(1, 0);
    for (i = 1; i <= 16; i = i + 1) step(0, i);          // official: 1, 4, 10, 20, 35, 56, 84, 120, 156, ...

    for (j = 0; j < N; j = j + 1) h[j*WIDTH +: WIDTH] = $random;
    h[0 +: WIDTH] = -32768;                               // extreme coefficient
    step(1, 0);
    for (i = 0; i < 40; i = i + 1) step(0, $random);
    step(0, -32768); step(0, -32768); step(0, 32767);
    step(1, 5); step(0, 3);                               // reset clears the history
    if (errors == 0) $display("Test PASSED!");
    else             $display("Test FAILED: %0d errors found.", errors);
    $finish;
  end
endmodule
