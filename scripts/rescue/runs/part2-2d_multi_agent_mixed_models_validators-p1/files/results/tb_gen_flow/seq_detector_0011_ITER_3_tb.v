`timescale 1ns/1ps

module tb_seq_detector_0011();

reg clk;
reg reset;
reg data_in;
wire detected;

integer i;
reg [0:15] inputs = 16'b0001100110110010;
reg [0:15] outputs = 16'b0000010001000000;

seq_detector_0011 dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .detected(detected)
);

always #0.55 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    data_in = 0;
    
    repeat(4) @(negedge clk);
    reset = 0;

    // Test 1: Sample Case
    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        if (detected === outputs[i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
        end
        data_in = inputs[i];
    end

    // Test 2: Reset during operation
    @(negedge clk);
    reset = 1;
    data_in = 0;
    @(negedge clk);
    reset = 0;
    data_in = 0; @(negedge clk);
    data_in = 0; @(negedge clk);
    data_in = 1; @(negedge clk);
    data_in = 1; @(negedge clk);
    if (detected === 1'b1) $display("TEST: PASS | Inputs: [data_in=1] | Expected: [1] | Output: [%b]", detected);
    else $display("TEST: FAIL | Inputs: [data_in=1] | Expected: [1] | Output: [%b]", detected);

    // Test 3: Back-to-back overlap (0011_0011)
    data_in = 0; @(negedge clk);
    data_in = 0; @(negedge clk);
    data_in = 1; @(negedge clk);
    data_in = 1; @(negedge clk); // Detect 1
    data_in = 0; @(negedge clk);
    data_in = 0; @(negedge clk);
    data_in = 1; @(negedge clk);
    data_in = 1; @(negedge clk); // Detect 1
    @(negedge clk);
    if (detected === 1'b1) $display("TEST: PASS | Inputs: [data_in=1] | Expected: [1] | Output: [%b]", detected);
    else $display("TEST: FAIL | Inputs: [data_in=1] | Expected: [1] | Output: [%b]", detected);

    $finish;
end

endmodule