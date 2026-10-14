// Reference testbench for seq_detector_0011 (p1).
// Corrected from the ICLAD 2025 original, which released reset exactly at a rising edge
// (a race: a correct synchronous-reset design could miss the reset and output x).
// Same vectors and expected values; inputs are driven and outputs checked on falling edges.
`timescale 1ns/1ps

module tb_seq_detector_0011;

reg clk;
reg reset;
reg data_in;
wire detected;

seq_detector_0011 dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .detected(detected)
);

initial clk = 0;
always #5 clk = ~clk;

reg [15:0] input_vec       = 16'b0001100110110010;
reg [15:0] expected_output = 16'b0000010001000000; // expected[i]: detected while input[i] is applied
integer i;
integer errors = 0;

initial begin
    reset = 1;
    data_in = 0;
    @(posedge clk);
    @(posedge clk);
    @(negedge clk);
    reset = 0;

    for (i = 0; i < 16; i = i + 1) begin
        // detected reflects only the bits sampled before input[i]
        if (detected !== expected_output[15 - i]) begin
            $display("ERROR at bit %0d: detected=%b expected=%b", i, detected, expected_output[15 - i]);
            errors = errors + 1;
        end
        data_in = input_vec[15 - i];
        @(negedge clk);
    end

    if (errors == 0)
        $display("Test PASSED!");
    else
        $display("Test FAILED: %0d errors found.", errors);

    $finish;
end

endmodule
