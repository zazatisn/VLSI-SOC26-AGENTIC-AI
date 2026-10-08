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

    task check_case;
        input [15:0] in_a;
        input [15:0] in_b;
        input [15:0] exp;
        begin
            a = in_a;
            b = in_b;
            #1;
            if (result === exp) begin
                $display("TEST: PASS | Inputs: a=%h, b=%h | Expected: %h | Output: %h", in_a, in_b, exp, result);
            end else begin
                $display("TEST: FAIL | Inputs: a=%h, b=%h | Expected: %h | Output: %h", in_a, in_b, exp, result);
            end
        end
    endtask

    initial begin
        // Reference cases from spec
        // 1.0 * 2.0 = 2.0
        check_case(16'h3c00, 16'h4000, 16'h4000);
        // 0.0 * 5.0 = 0.0
        check_case(16'h0000, 16'h4500, 16'h0000);
        // -3.0 * 4.0 = -12.0
        check_case(16'hc000, 16'h4800, 16'hc900);

        // Corner cases
        // 0.0 * 0.0 = 0.0
        check_case(16'h0000, 16'h0000, 16'h0000);
        // 1.0 * -1.0 = -1.0
        check_case(16'h3c00, 16'hbc00, 16'hbc00);
        // Infinity * 1.0 = Infinity
        check_case(16'h7c00, 16'h3c00, 16'h7c00);
        // Max Positive * 2.0 = Infinity (Overflow)
        check_case(16'h7bff, 16'h4000, 16'h7c00);
        // Smallest positive * 0.5 = 0.0 (Underflow)
        check_case(16'h0400, 16'h3800, 16'h0000);

        $finish;
    end

endmodule