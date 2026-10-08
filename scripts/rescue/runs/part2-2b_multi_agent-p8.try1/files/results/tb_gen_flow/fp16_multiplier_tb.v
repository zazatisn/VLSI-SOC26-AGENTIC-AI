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

    task check_case;
        input [15:0] in_a;
        input [15:0] in_b;
        input [15:0] expected;
        begin
            a = in_a;
            b = in_b;
            #1;
            if (result === expected) begin
                $display("TEST: PASS | Inputs: a=%h, b=%h | Expected: %h | Output: %h", in_a, in_b, expected, result);
            end else begin
                $display("TEST: FAIL | Inputs: a=%h, b=%h | Expected: %h | Output: %h", in_a, in_b, expected, result);
            end
        end
    endtask

    initial begin
        // Example 1: 1.0 * 2.0 = 2.0
        check_case(16'h3c00, 16'h4000, 16'h4000);
        
        // Example 2: 0.0 * 5.0 = 0.0
        check_case(16'h0000, 16'h4400, 16'h0000);
        
        // Example 3: -3.0 * 4.0 = -12.0
        // -3.0: 1 10000 1000000000 -> C400
        // 4.0:  0 10001 0000000000 -> 4400
        // -12.0: 1 10010 1000000000 -> C900
        check_case(16'hC400, 16'h4400, 16'hC900);

        // Corner case: Zero
        check_case(16'h0000, 16'h0000, 16'h0000);

        // Corner case: Signed identity
        // 1.0 * -1.0 = -1.0
        check_case(16'h3c00, 16'hBC00, 16'hBC00);

        $finish;
    end

endmodule