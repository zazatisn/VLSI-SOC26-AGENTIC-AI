`timescale 1ns/1ps

module tb_seq_detector;

    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
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
        repeat(2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 15; i >= 0; i = i - 1) begin
            data_in = input_stream[i];
            @(negedge clk);
            if (detected === expected_output[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, expected_output[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, expected_output[i], detected);
            end
        end

        // Test Back-to-Back: 00110011
        // Resetting to clear state
        reset = 1; @(negedge clk); reset = 0;
        
        // Sequence: 0 0 1 1 0 0 1 1
        // Expected: 0 0 0 1 0 0 0 1
        begin
            reg [7:0] b2b_in = 8'b00110011;
            reg [7:0] b2b_out = 8'b00010001;
            for (i = 7; i >= 0; i = i - 1) begin
                data_in = b2b_in[i];
                @(negedge clk);
                if (detected === b2b_out[i]) begin
                    $display("TEST: PASS | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                             data_in, reset, b2b_out[i], detected);
                end else begin
                    $display("TEST: FAIL | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                             data_in, reset, b2b_out[i], detected);
                end
            end
        end

        $finish;
    end
endmodule