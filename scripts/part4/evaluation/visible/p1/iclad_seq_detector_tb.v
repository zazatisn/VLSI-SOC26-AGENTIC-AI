// Clock-driven testbench for seq_detector_0011
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

reg [15:0] input_vec = 16'b0001100110110010;
reg [15:0] expected_output = 16'b0000010001000000; // Adjusted for one cycle delay
integer i;
integer errors = 0;

initial begin
    reset = 1;
    @(posedge clk);
    reset = 0;

    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        data_in = input_vec[15 - i];
        @(posedge clk);
        if (detected !== expected_output[15 - i]) begin
            $display("ERROR at bit %0d: data_in=%b detected=%b expected=%b", i, data_in, detected, expected_output[15 - i]);
            errors = errors + 1;
        end
    end

    if (errors == 0)
        $display("Test PASSED!");
    else
        $display("Test FAILED: %0d errors found.", errors);

    $finish;
end

endmodule
