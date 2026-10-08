`timescale 1ns/1ps

module tb_fp16_multiplier;

reg [15:0] a;
reg [15:0] b;
wire [15:0] result;

fp16_multiplier dut (
    .a(a),
    .b(b),
    .result(result)
);

task check_mul;
    input [15:0] in_a;
    input [15:0] in_b;
    input [15:0] expected;
    begin
        a = in_a;
        b = in_b;
        #1;
        if (result === expected) begin
            $display("TEST: PASS | Inputs: [a=%h, b=%h] | Expected: %h | Output: %h", in_a, in_b, expected, result);
        end else begin
            $display("TEST: FAIL | Inputs: [a=%h, b=%h] | Expected: %h | Output: %h", in_a, in_b, expected, result);
        end
    end
endtask

initial begin
    // Spec examples
    // 1.0 * 2.0 = 2.0
    check_mul(16'h3c00, 16'h4000, 16'h4000);
    // 0.0 * 5.0 = 0.0
    check_mul(16'h0000, 16'h4400, 16'h0000);
    // -3.0 * 4.0 = -12.0
    check_mul(16'hc000, 16'h4400, 16'hc800);
    
    // Additional corner cases
    // Zero * Zero
    check_mul(16'h0000, 16'h0000, 16'h0000);
    // Identity * 1.0
    check_mul(16'h3c00, 16'h3c00, 16'h3c00);
    // Large * Small
    check_mul(16'h7bff, 16'h0400, 16'h3c00);
    // Signs
    // 2.0 * -2.0 = -4.0
    check_mul(16'h4000, 16'hc000, 16'hc400);

    $finish;
end

endmodule