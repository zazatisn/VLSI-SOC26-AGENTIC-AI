`timescale 1ns/1ps

module tb;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    reg [15:0] inputs = 16'b0001100110110010;
    reg [15:0] outputs = 16'b0000010001000000;

    seq_detector_0011 dut(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .detected(detected)
    );

    initial clk = 0;
    always #0.55 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        data_in = 0;
        
        // Reset sequence: at least 2 rising edges
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Process inputs
        for (i = 0; i < 16; i = i + 1) begin
            // Check detected based on previous state
            if (detected === outputs[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
            end
            
            // Drive next data
            data_in = inputs[i];
            @(negedge clk);
        end

        // Check last output bit
        if (detected === 1'b0) begin
            $display("TEST: PASS | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end

        // Corner Case: Mid-sequence reset
        data_in = 0; @(negedge clk);
        data_in = 0; @(negedge clk);
        data_in = 1; @(negedge clk);
        reset = 1;
        @(negedge clk);
        if (detected === 1'b0) begin
            $display("TEST: PASS | Inputs: [RESET_MID] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [RESET_MID] | Expected: [0] | Output: [%b]", detected);
        end
        reset = 0;
        
        $finish;
    end
endmodule