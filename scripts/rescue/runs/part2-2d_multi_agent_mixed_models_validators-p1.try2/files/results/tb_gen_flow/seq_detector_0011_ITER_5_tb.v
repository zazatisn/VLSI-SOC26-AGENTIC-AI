`timescale 1ns/1ps

module tb_seq_detector;

reg clk;
reg reset;
reg data_in;
wire detected;

reg [15:0] inputs = 16'b0001100110110010;
reg [15:0] expected = 16'b0000010001000000;
integer i;

seq_detector_0011 uut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .detected(detected)
);

initial begin
    clk = 0;
    forever #0.55 clk = ~clk;
end

initial begin
    reset = 1;
    data_in = 0;
    
    // Hold reset for 2 rising edges
    @(posedge clk);
    @(posedge clk);
    @(negedge clk);
    reset = 0;
    
    // Main loop
    for (i = 0; i < 16; i = i + 1) begin
        // Drive input on falling edge
        data_in = inputs[i];
        @(negedge clk);
        // Check output on falling edge after the rising edge has occurred
        if (detected === expected[i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected[i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected[i], detected);
        end
    end

    // Overlap test: 00110011 -> 0011 occurs at index 3, then 0011 occurs again at index 7
    // Sequence: 0 0 1 1 0 0 1 1
    // Expected: 0 0 0 1 0 0 0 1
    reset = 1;
    @(negedge clk);
    reset = 0;
    data_in = 0; @(negedge clk); // 0
    data_in = 0; @(negedge clk); // 0
    data_in = 1; @(negedge clk); // 1
    data_in = 1; @(negedge clk); // 1 - check 0
    data_in = 0; @(negedge clk); // 0 - check 1
    data_in = 0; @(negedge clk); // 0 - check 0
    data_in = 1; @(negedge clk); // 1 - check 0
    data_in = 1; @(negedge clk); // 1 - check 1

    $finish;
end

endmodule