// Verilog-2001 Testbench for FIR filter
`timescale 1ns/1ps

module test_fir_filter;

  parameter WIDTH = 16;
  parameter N = 8;
  
  // Replace logic with reg/wire
  reg clk, rst;
  reg signed [WIDTH-1:0] x_in;
  reg signed [N*WIDTH-1:0] h; // Flattened port
  wire signed [2*WIDTH + $clog2(N) - 1 : 0] y_out;

  // Instantiate the DUT
  fir_filter #(.WIDTH(WIDTH), .N(N)) dut (
    .clk(clk),
    .rst(rst),
    .x_in(x_in),
    .h(h),
    .y_out(y_out)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Input samples and helper arrays
  reg signed [WIDTH-1:0] samples [0:15];
  reg signed [WIDTH-1:0] h_array [0:N-1]; // Unpacked array for TB math
  reg signed [2*WIDTH + $clog2(N) - 1 : 0] expected_val;
  
  integer i, j;

  initial begin
    // Initialize
    clk = 0;
    rst = 1;
    x_in = 0;
    h = 0;

    // Set Coefficients and pack them into the flattened 'h' port
    for (i = 0; i < N; i = i + 1) begin
      h_array[i] = i + 1; // 1, 2, ..., N
      // Pack using indexed part-select
      h[i*WIDTH +: WIDTH] = h_array[i];
    end

    // Fill sample buffer
    for (i = 0; i < 16; i = i + 1) begin
      samples[i] = i + 1;
    end

    @(negedge clk);
    rst = 0;

    // Stimulus loop
    for (i = 0; i < 16; i = i + 1) begin
      @(negedge clk);
      x_in = samples[i];
      
      // Calculate expected convolution result
      expected_val = 0;
      for (j = 0; j < N; j = j + 1) begin
        if ((i - j) >= 0) begin
          expected_val = expected_val + (samples[i-j] * h_array[j]);
        end
      end

      // Sample output on next posedge (allowing for combinatorial path/clocking)
      @(posedge clk);
      #1; 
      $display("Sample %0d: x_in = %0d, y_out = %0d, expected = %0d", i, x_in, y_out, expected_val);
      
      if (y_out === expected_val)
        $display("PASS");
      else
        $display("FAIL");
    end

    $finish;
  end

endmodule