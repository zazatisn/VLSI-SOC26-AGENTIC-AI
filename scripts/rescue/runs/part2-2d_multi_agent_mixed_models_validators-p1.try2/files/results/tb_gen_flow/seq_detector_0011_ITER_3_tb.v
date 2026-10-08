`timescale 1ns/1ps

module tb_seq_detector;

reg clk;
reg reset;
reg data_in;
wire detected;

reg [15:0] inputs = 16'b0001100110110010;
reg [15:0] expected_outputs = 16'b0000010001000000;
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
    
    // Reset for 2 rising edges
    repeat(2) @(posedge clk);
    @(negedge clk);
    reset = 0;
    
    // Main Test Sequence
    for (i = 15; i >= 0; i = i - 1) begin
        @(negedge clk);
        if (detected === expected_outputs[i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected_outputs[i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected_outputs[i], detected);
        end
        data_in = inputs[i];
    end
    
    // Corner Case: Reset in the middle
    @(negedge clk); // last bit
    
    reset = 1;
    data_in = 0;
    repeat(2) @(posedge clk);
    @(negedge clk);
    reset = 0;
    
    // Check reset state
    if (detected === 1'b0) begin
        $display("TEST: PASS | Inputs: [ResetMid] | Expected: [0] | Output: [%b]", detected);
    end else begin
        $display("TEST: FAIL | Inputs: [ResetMid] | Expected: [0] | Output: [%b]", detected);
    end

    $finish;
end

endmodule