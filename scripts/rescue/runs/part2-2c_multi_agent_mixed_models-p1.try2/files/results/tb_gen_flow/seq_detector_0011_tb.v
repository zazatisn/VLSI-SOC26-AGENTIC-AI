`timescale 1ns/1ps

module tb_seq_detector_0011();

reg clk;
reg reset;
reg data_in;
wire detected;

integer i;
reg [15:0] inputs = 16'b0001100110110010;
reg [15:0] expected = 16'b0000010001000000;

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
    
    // Process input sequence
    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        
        // Check current output against expectation
        if (detected === expected[15-i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                     data_in, expected[15-i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", 
                     data_in, expected[15-i], detected);
        end
        
        // Drive next input
        data_in = inputs[15-i];
    end
    
    // Final check for the last data bit cycle
    @(negedge clk);
    if (detected === 0) begin
        $display("TEST: PASS | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
    end else begin
        $display("TEST: FAIL | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
    end
    
    $finish;
end

endmodule