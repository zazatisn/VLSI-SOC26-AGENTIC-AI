`timescale 1ns/1ps

module tb_fp16_multiplier();

reg [15:0] a;
reg [15:0] b;
wire [15:0] result;

fp16_multiplier dut (
    .a(a),
    .b(b),
    .result(result)
);

task check_fp16;
    input [15:0] in_a;
    input [15:0] in_b;
    input [15:0] expected;
begin
    a = in_a;
    b = in_b;
    #1;
    if (result === expected) begin
        $display("TEST: PASS | Inputs: [a=%h, b=%h] | Expected: [%h] | Output: [%h]", in_a, in_b, expected, result);
    end else begin
        $display("TEST: FAIL | Inputs: [a=%h, b=%h] | Expected: [%h] | Output: [%h]", in_a, in_b, expected, result);
    end
end
endtask

initial begin
    // Sample cases from spec
    check_fp16(16'h3c00, 16'h4000, 16'h4000); // 1.0 * 2.0 = 2.0
    check_fp16(16'h0000, 16'h4100, 16'h0000); // 0.0 * 5.0 = 0.0
    check_fp16(16'hc800, 16'h4100, 16'hc900); // -3.0 * 4.0 = -12.0
    
    // Additional cases
    check_fp16(16'h0000, 16'h0000, 16'h0000); // 0.0 * 0.0
    check_fp16(16'h7c00, 16'h3c00, 16'h7c00); // Inf * 1.0 = Inf
    check_fp16(16'h3c00, 16'h7c00, 16'h7c00); // 1.0 * Inf = Inf
    check_fp16(16'hbc00, 16'h3c00, 16'hbc00); // -1.0 * 1.0 = -1.0
    
    $finish;
end

endmodule