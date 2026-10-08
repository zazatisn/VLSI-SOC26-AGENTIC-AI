`timescale 1ns/1ps

module tb_seq_detector;

reg clk;
reg reset;
reg data_in;
wire detected;

reg [15:0] inputs = 16'b0001100110110010;
reg [15:0] expected_outputs = 16'b0000010001000000;
integer i;

seq_detector_0011 uut (
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
    // Initialize
    reset = 1;
    data_in = 0;
    
    // Hold reset high for 2 rising edges
    @(posedge clk);
    @(posedge clk);
    
    // Release on falling edge
    @(negedge clk);
    reset = 0;
    
    // Check-then-Drive loop
    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        // Check detected against expected for current cycle
        if (detected === expected_outputs[i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected_outputs[i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected_outputs[i], detected);
        end
        // Apply input for next cycle
        data_in = inputs[i];
    end
    
    // Additional reset test case
    @(negedge clk);
    reset = 1;
    @(negedge clk);
    if (detected === 1'b0) begin
        $display("TEST: PASS | Inputs: [Reset=1] | Expected: [0] | Output: [%b]", detected);
    end else begin
        $display("TEST: FAIL | Inputs: [Reset=1] | Expected: [0] | Output: [%b]", detected);
    end

    $finish;
end

endmodule