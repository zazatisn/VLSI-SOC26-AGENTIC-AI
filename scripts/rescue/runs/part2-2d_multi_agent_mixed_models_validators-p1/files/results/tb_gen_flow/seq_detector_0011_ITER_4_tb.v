`timescale 1ns/1ps

module tb_seq_detector;

    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    reg [15:0] input_stream;
    reg [15:0] expected_output;
    reg [7:0] b2b_in;
    reg [7:0] b2b_out;

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
        input_stream = 16'b0001_1001_1011_0010;
        expected_output = 16'b0000_0100_0100_0000;
        b2b_in = 8'b00110011;
        b2b_out = 8'b00010001;

        reset = 1;
        data_in = 0;
        repeat(2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 15; i >= 0; i = i - 1) begin
            // Check first
            #0.1; // Small delta to ensure state is settled before checking on negedge
            if (detected === expected_output[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, expected_output[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, expected_output[i], detected);
            end
            // Drive next
            data_in = input_stream[i];
            @(negedge clk);
        end

        reset = 1; 
        @(negedge clk); 
        reset = 0;
        
        for (i = 7; i >= 0; i = i - 1) begin
            #0.1;
            if (detected === b2b_out[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, b2b_out[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b, reset=%b] | Expected: [%b] | Output: [%b]", 
                         data_in, reset, b2b_out[i], detected);
            end
            data_in = b2b_in[i];
            @(negedge clk);
        end

        $finish;
    end
endmodule