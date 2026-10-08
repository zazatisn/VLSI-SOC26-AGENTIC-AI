`timescale 1ns/1ps

module tb_seq_detector;

reg clk;
reg reset;
reg data_in;
wire detected;

reg [15:0] inputs = 16'b0001100110110010;
reg [15:0] expected = 16'b0000010001000000;

reg [7:0] overlap_in = 8'b00110011;
reg [7:0] overlap_exp = 8'b00010001;

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
    
    // Reset sequence: 2 rising edges, release on falling
    repeat(2) @(posedge clk);
    @(negedge clk);
    reset = 0;

    // Test Case 1: Provided Sample
    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        if (detected === expected[15-i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected[15-i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected[15-i], detected);
        end
        data_in = inputs[15-i];
    end

    // Test Case 2: Overlap Test 00110011
    // Reset before new test phase
    reset = 1;
    @(negedge clk);
    reset = 0;
    data_in = 0;

    for (i = 0; i < 8; i = i + 1) begin
        @(negedge clk);
        if (detected === overlap_exp[7-i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, overlap_exp[7-i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, overlap_exp[7-i], detected);
        end
        data_in = overlap_in[7-i];
    end

    $finish;
end

endmodule