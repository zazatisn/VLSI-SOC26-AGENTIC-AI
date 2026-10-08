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

    initial begin
        reset = 1;
        data_in = 0;
        
        // Wait for 2 rising edges (0.55, 1.65), then release on falling edge (2.75)
        repeat (5) @(negedge clk);
        reset = 0;

        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            
            if (detected === outputs[15 - i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", inputs[15 - i], outputs[15 - i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", inputs[15 - i], outputs[15 - i], detected);
            end
            
            data_in = inputs[15 - i];
        end

        // Extra cycle to verify final detection
        @(negedge clk);
        
        $finish;
    end
endmodule