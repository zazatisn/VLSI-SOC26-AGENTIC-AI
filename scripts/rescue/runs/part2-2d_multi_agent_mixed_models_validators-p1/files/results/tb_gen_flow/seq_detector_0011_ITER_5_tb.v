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
        input_stream = 16'b0000_1001_1011_0010; // Corresponds to sample 0001100110110010
        expected_output = 16'b0000_0000_0100_0100; // Corresponds to sample 0000010001000000

        reset = 1;
        data_in = 0;
        
        // Hold reset for 2 rising edges
        repeat(2) @(posedge clk);
        
        // Release on a falling edge
        @(negedge clk);
        reset = 0;

        // Process stream
        for (i = 0; i < 16; i = i + 1) begin
            // Check immediately on negedge
            if (detected === expected_output[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, expected_output[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, expected_output[i], detected);
            end
            
            // Drive next data on negedge
            data_in = input_stream[i];
            
            // Wait for next cycle
            @(negedge clk);
        end

        // Final check for the last data bit
        if (detected === expected_output[15]) begin
            $display("TEST: PASS | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                     data_in, reset, expected_output[15], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                     data_in, reset, expected_output[15], detected);
        end

        $finish;
    end
endmodule