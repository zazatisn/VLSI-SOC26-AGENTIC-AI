`timescale 1ns/1ps

module tb_seq_detector_0011();

reg clk;
reg reset;
reg data_in;
wire detected;

integer i;
reg [15:0] inputs = 16'b0001_1001_1011_0010;
reg [15:0] outputs = 16'b0000_0100_0100_0000;
reg expected;

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
    
    // Hold reset for 2 rising edges
    repeat(4) @(posedge clk);
    @(negedge clk);
    reset = 0;

    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        expected = outputs[15 - i];
        
        if (detected === expected) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected, detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected, detected);
        end
        
        data_in = inputs[15 - i];
    end

    // Final check for the last bit result
    @(negedge clk);
    if (detected === outputs[0]) begin
        $display("TEST: PASS | Inputs: [final] | Expected: [%b] | Output: [%b]", outputs[0], detected);
    end else begin
        $display("TEST: FAIL | Inputs: [final] | Expected: [%b] | Output: [%b]", outputs[0], detected);
    end

    $finish;
end

endmodule