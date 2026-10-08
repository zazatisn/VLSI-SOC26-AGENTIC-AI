`timescale 1ns/1ps

module tb_seq_detector;

reg clk;
reg reset;
reg data_in;
wire detected;

integer i;
reg [15:0] sample_in = 16'b0001100110110010;
reg [15:0] sample_exp = 16'b0000010001000000;

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
    
    // Hold reset high for 2 rising edges
    @(posedge clk);
    @(posedge clk);
    // Release on falling edge
    @(negedge clk);
    reset = 0;

    // Test Case 1: Provided Sample with overlapping check
    for (i = 15; i >= 0; i = i - 1) begin
        @(negedge clk);
        if (detected === sample_exp[i]) begin
            $display("TEST: PASS | Inputs: [clk=%b, reset=%b, data_in=%b] | Expected: [%b] | Output: [%b]", clk, reset, data_in, sample_exp[i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [clk=%b, reset=%b, data_in=%b] | Expected: [%b] | Output: [%b]", clk, reset, data_in, sample_exp[i], detected);
        end
        data_in = sample_in[i];
    end

    // Test Case 2: Overlapping '00110011'
    // Sequence '0011' then '0011'
    @(negedge clk);
    data_in = 0; // Cycle 1 of 0011
    @(negedge clk);
    data_in = 0; // Cycle 2 of 0011
    @(negedge clk);
    data_in = 1; // Cycle 3 of 0011
    @(negedge clk);
    data_in = 1; // Cycle 4, detected should be 1
    @(negedge clk);
    if (detected === 1) $display("TEST: PASS | Inputs: [clk=%b, reset=%b, data_in=%b] | Expected: [1] | Output: [%b]", clk, reset, data_in, detected);
    else $display("TEST: FAIL | Inputs: [clk=%b, reset=%b, data_in=%b] | Expected: [1] | Output: [%b]", clk, reset, data_in, detected);
    
    data_in = 0; // Start of next 0011
    @(negedge clk);
    data_in = 0;
    @(negedge clk);
    data_in = 1;
    @(negedge clk);
    data_in = 1;
    @(negedge clk);
    if (detected === 1) $display("TEST: PASS | Inputs: [clk=%b, reset=%b, data_in=%b] | Expected: [1] | Output: [%b]", clk, reset, data_in, detected);
    else $display("TEST: FAIL | Inputs: [clk=%b, reset=%b, data_in=%b] | Expected: [1] | Output: [%b]", clk, reset, data_in, detected);

    $finish;
end

endmodule