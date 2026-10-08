`timescale 1ns/1ps

module tb_seq_detector;

reg clk;
reg reset;
reg data_in;
wire detected;

integer i;
reg [15:0] sample_in = 16'b0001100110110010;
reg [15:0] sample_exp = 16'b0000010001000000;

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
    reset = 1;
    data_in = 0;
    
    @(posedge clk);
    @(posedge clk);
    @(negedge clk);
    reset = 0;

    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        if (detected === sample_exp[i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, sample_exp[i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, sample_exp[i], detected);
        end
        data_in = sample_in[i];
    end
    
    @(negedge clk);
    if (detected === 0) begin
        $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [0] | Output: [%b]", data_in, detected);
    end else begin
        $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [0] | Output: [%b]", data_in, detected);
    end

    $finish;
end

endmodule