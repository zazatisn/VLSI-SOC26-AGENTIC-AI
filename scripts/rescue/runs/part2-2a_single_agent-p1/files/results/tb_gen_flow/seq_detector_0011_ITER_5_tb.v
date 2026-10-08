`timescale 1ns/1ps

module tb_seq_detector;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;
    integer i;
    reg [15:0] sample_input = 16'b0001100110110010;
    reg [15:0] sample_output = 16'b0000010001000000;

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
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 16; i = i + 1) begin
            if (detected !== sample_output[i]) begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, sample_output[i], detected);
            end else begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, sample_output[i], detected);
            end
            data_in = sample_input[i];
            @(negedge clk);
        end
        $finish;
    end
endmodule