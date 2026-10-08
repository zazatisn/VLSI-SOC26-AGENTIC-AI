`timescale 1ns/1ps

module tb_seq_detector;

    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    // Input sequence: 0001100110110010
    // Expected output: 0000010001000000
    reg [15:0] input_stream = 16'b0001_1001_1011_0010;
    reg [15:0] expected_output = 16'b0000_0100_0100_0000;

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
        repeat(2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Sequence Testing
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            if (detected === expected_output[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, expected_output[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, expected_output[i], detected);
            end
            data_in = input_stream[i];
        end

        // Corner Case: Reset in the middle of operation
        @(negedge clk);
        data_in = 0; // Preparing a potential sequence
        @(negedge clk);
        reset = 1;
        @(negedge clk);
        if (detected === 0) begin
            $display("TEST: PASS | Inputs: [Reset Asserted] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [Reset Asserted] | Expected: [0] | Output: [%b]", detected);
        end
        
        @(negedge clk);
        reset = 0;
        
        // Corner Case: Back-to-back sequences '00110011'
        // '0011' then '0011'
        repeat(8) begin
            @(negedge clk);
            data_in = 0; // Placeholder for sequence logic
        end

        $finish;
    end

endmodule