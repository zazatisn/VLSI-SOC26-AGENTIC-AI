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

    // Test Case 1: Provided Sample
    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        if (detected === sample_exp[15-i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, sample_exp[15-i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, sample_exp[15-i], detected);
        end
        data_in = sample_in[15-i];
    end

    // Test Case 2: Reset during operation
    @(negedge clk);
    data_in = 0;
    @(negedge clk);
    data_in = 0;
    @(negedge clk);
    reset = 1; // Assert reset mid-stream
    @(negedge clk);
    reset = 0;
    @(negedge clk);
    data_in = 1;
    @(negedge clk);
    data_in = 1;
    // Check if output remains low (reset successful)
    if (detected === 0) begin
        $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [0] | Output: [%b]", data_in, detected);
    end else begin
        $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [0] | Output: [%b]", data_in, detected);
    end

    $finish;
end

endmodule