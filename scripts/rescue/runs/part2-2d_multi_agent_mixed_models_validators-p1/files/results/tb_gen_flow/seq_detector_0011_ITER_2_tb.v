`timescale 1ns/1ps

module tb_seq_detector_0011();

reg clk;
reg reset;
reg data_in;
wire detected;

integer i;
reg [15:0] inputs = 16'b0001_1001_1011_0010;
reg [15:0] outputs = 16'b0000_0100_0100_0000;

seq_detector_0011 dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .detected(detected)
);

always #0.55 clk = ~clk;

task run_sequence;
    input [15:0] seq_in;
    input [15:0] seq_out;
    integer idx;
    begin
        for (idx = 15; idx >= 0; idx = idx - 1) begin
            @(negedge clk);
            if (detected === seq_out[idx]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, seq_out[idx], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, seq_out[idx], detected);
            end
            data_in = seq_in[idx];
        end
        @(negedge clk);
        #0.1; // Observe final state
    end
endtask

initial begin
    clk = 0;
    reset = 1;
    data_in = 0;
    
    repeat(2) @(posedge clk);
    @(negedge clk);
    reset = 0;

    // Test 1: Sample Case
    run_sequence(inputs, outputs);

    // Test 2: Reset during operation
    reset = 1;
    repeat(2) @(posedge clk);
    @(negedge clk);
    reset = 0;
    data_in = 0; @(negedge clk);
    data_in = 0; @(negedge clk);
    data_in = 1; @(negedge clk);
    data_in = 1; @(negedge clk);
    // After 0011, output should be 1
    if (detected === 1'b1) $display("TEST: PASS | Inputs: [0011] | Expected: [1] | Output: [%b]", detected);
    else $display("TEST: FAIL | Inputs: [0011] | Expected: [1] | Output: [%b]", detected);

    // Test 3: Back-to-back overlap
    // 0011 -> 0011. Pattern: 0,0,1,1,0,0,1,1
    data_in = 0; @(negedge clk);
    data_in = 0; @(negedge clk);
    data_in = 1; @(negedge clk);
    data_in = 1; @(negedge clk);
    if (detected === 1'b1) $display("TEST: PASS | Inputs: [Seq1] | Expected: [1] | Output: [%b]", detected);
    else $display("TEST: FAIL | Inputs: [Seq1] | Expected: [1] | Output: [%b]", detected);
    
    data_in = 0; @(negedge clk);
    data_in = 0; @(negedge clk);
    data_in = 1; @(negedge clk);
    data_in = 1; @(negedge clk);
    if (detected === 1'b1) $display("TEST: PASS | Inputs: [Seq2] | Expected: [1] | Output: [%b]", detected);
    else $display("TEST: FAIL | Inputs: [Seq2] | Expected: [1] | Output: [%b]", detected);

    $finish;
end

endmodule