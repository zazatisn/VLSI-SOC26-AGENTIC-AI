`timescale 1ns/1ps

module tb;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    reg [15:0] inputs = 16'b0001_1001_1011_0010;
    reg [15:0] outputs = 16'b0000_0100_0100_0000;

    seq_detector_0011 dut(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .detected(detected)
    );

    initial clk = 0;
    always #0.55 clk = ~clk;

    task check_and_drive;
        input reg_in;
        input exp_out;
        begin
            if (detected === exp_out) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", reg_in, exp_out, detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", reg_in, exp_out, detected);
            end
            data_in = reg_in;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        data_in = 0;
        
        // Assert reset for 2 rising edges
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Sequence case
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            check_and_drive(inputs[15-i], outputs[15-i]);
        end

        // Mid-sequence reset test
        @(negedge clk);
        data_in = 0; @(negedge clk); // Start sequence
        data_in = 0; @(negedge clk);
        reset = 1;   @(negedge clk); // Reset
        reset = 0;   @(negedge clk);
        data_in = 1; @(negedge clk); // Should not detect 0011
        data_in = 1; @(negedge clk);
        
        // Back-to-back test
        data_in = 0; @(negedge clk);
        data_in = 0; @(negedge clk);
        data_in = 1; @(negedge clk);
        data_in = 1; @(negedge clk); // Detected
        data_in = 0; @(negedge clk);
        data_in = 0; @(negedge clk);
        data_in = 1; @(negedge clk);
        data_in = 1; @(negedge clk); // Detected
        
        $finish;
    end
endmodule