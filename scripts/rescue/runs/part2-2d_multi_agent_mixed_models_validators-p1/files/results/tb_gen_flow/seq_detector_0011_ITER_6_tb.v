`timescale 1ns/1ps

module tb_seq_detector;

    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    reg [15:0] input_stream;
    reg [15:0] expected_output;

    seq_detector_0011 dut (
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
        input_stream = 16'b0001100110110010;
        expected_output = 16'b0000010001000000;

        reset = 1;
        data_in = 0;
        
        repeat(2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 16; i = i + 1) begin
            // Check output first
            if (detected === expected_output[i]) begin
                $display("TEST: PASS | Index: %0d | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         i, data_in, reset, expected_output[i], detected);
            end else begin
                $display("TEST: FAIL | Index: %0d | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         i, data_in, reset, expected_output[i], detected);
            end
            
            // Drive next bit
            data_in = input_stream[i];
            @(negedge clk);
        end

        $finish;
    end
endmodule