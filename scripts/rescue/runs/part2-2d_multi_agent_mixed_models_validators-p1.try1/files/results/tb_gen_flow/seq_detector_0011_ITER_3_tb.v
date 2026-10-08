`timescale 1ns/1ps

module tb;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    integer timeout;
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
        clk = 0;
        reset = 1;
        data_in = 0;
        timeout = 0;
        
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Verify reset state
        if (detected !== 1'b0) begin
            $display("TEST: FAIL | Inputs: [RESET] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: PASS | Inputs: [RESET] | Expected: [0] | Output: [%b]", detected);
        end

        // Main test sequence
        for (i = 15; i >= 0; i = i - 1) begin
            @(negedge clk);
            if (detected === outputs[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
            end
            data_in = inputs[i];
            
            timeout = timeout + 1;
            if (timeout > 1000) $finish;
        end
        
        // Final clock to capture last detection
        @(negedge clk);
        if (detected === 0) begin
            $display("TEST: PASS | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end

        $finish;
    end
endmodule