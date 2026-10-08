`timescale 1ns/1ps

module tb_seq_detector_0011;

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

    initial begin
        clk = 0;
        forever #0.55 clk = ~clk;
    end

    initial begin
        reset = 1;
        data_in = 0;
        // Hold reset for 2 rising edges
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            
            // Check detected against expected
            if (detected === sample_output[15-i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, sample_output[15-i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, sample_output[15-i], detected);
            end

            // Drive next data
            data_in = sample_input[15-i];
        end

        // Wait for final cycle observation
        @(negedge clk);
        if (detected === 1'b0) begin
            $display("TEST: PASS | Inputs: [final] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [final] | Expected: [0] | Output: [%b]", detected);
        end

        $finish;
    end

endmodule