`timescale 1ns/1ps

module tb_seq_detector;

    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    reg [15:0] sample_input = 16'b0001_1001_1011_0010;
    reg [15:0] sample_output = 16'b0000_0100_0100_0000;

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

        // Reset for 2 rising edges
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            
            // Check output against expected
            if (detected === sample_output[15-i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, sample_output[15-i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, sample_output[15-i], detected);
            end

            // Drive next input
            data_in = sample_input[15-i];
        end

        // Final check after last bit
        @(negedge clk);
        if (detected === 0) begin
            $display("TEST: PASS | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end

        $finish;
    end

endmodule