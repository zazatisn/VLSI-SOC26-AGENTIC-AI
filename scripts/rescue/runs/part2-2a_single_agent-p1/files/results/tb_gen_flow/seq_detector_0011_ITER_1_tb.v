`timescale 1ns/1ps

module tb;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;
    integer i;
    reg [15:0] sample_input = 16'b0001100110110010;
    reg [15:0] sample_output = 16'b0000010001000000;

    seq_detector_0011 dut(.clk(clk), .reset(reset), .data_in(data_in), .detected(detected));

    always #0.55 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        data_in = 0;
        #1.1;
        #1.1;
        @(negedge clk) reset = 0;

        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            if (detected === sample_output[15-i]) 
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", sample_input[15-i], sample_output[15-i], detected);
            else 
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", sample_input[15-i], sample_output[15-i], detected);
            data_in = sample_input[15-i];
        end
        $finish;
    end
endmodule