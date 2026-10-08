`timescale 1ns/1ps

module tb_alu_8bit;
    reg clk;
    reg reset;
    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] op;
    wire [7:0] result;
    wire zero;
    wire carry;

    alu_8bit dut(
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .carry(carry)
    );

    initial clk = 1'b0;
    always #1.25 clk = ~clk;

    task apply_check(
        input [2:0] t_op,
        input [7:0] t_a,
        input [7:0] t_b,
        input [7:0] exp_res,
        input exp_zero,
        input exp_carry
    );
        @(negedge clk);
        op = t_op;
        a = t_a;
        b = t_b;
        @(negedge clk);
        if (result == exp_res && zero == exp_zero && carry == exp_carry) begin
            $display("TEST: PASS | Inputs: op=%0d a=%0d b=%0d | Expected: res=%0d z=%0d c=%0d | Output: res=%0d z=%0d c=%0d",
                t_op, t_a, t_b, exp_res, exp_zero, exp_carry, result, zero, carry);
        end else begin
            $display("TEST: FAIL | Inputs: op=%0d a=%0d b=%0d | Expected: res=%0d z=%0d c=%0d | Output: res=%0d z=%0d c=%0d",
                t_op, t_a, t_b, exp_res, exp_zero, exp_carry, result, zero, carry);
        end
    endtask

    initial begin
        reset = 1'b1;
        a = 8'd0;
        b = 8'd0;
        op = 3'd0;

        @(posedge clk);
        if (result != 8'd0 || zero != 1'b0 || carry != 1'b0) begin
            $display("TEST: FAIL | Reset check cycle 1 | Expected: res=0 z=0 c=0 | Output: res=%0d z=%0d c=%0d",
                result, zero, carry);
        end

        @(posedge clk);
        if (result != 8'd0 || zero != 1'b0 || carry != 1'b0) begin
            $display("TEST: FAIL | Reset check cycle 2 | Expected: res=0 z=0 c=0 | Output: res=%0d z=%0d c=%0d",
                result, zero, carry);
        end

        @(posedge clk);
        if (result != 8'd0 || zero != 1'b0 || carry != 1'b0) begin
            $display("TEST: FAIL | Reset check cycle 3 | Expected: res=0 z=0 c=0 | Output: res=%0d z=%0d c=%0d",
                result, zero, carry);
        end

        @(negedge clk);
        reset = 1'b0;

        apply_check(3'd0, 8'd200, 8'd100, 8'd44, 1'b0, 1'b1);
        apply_check(3'd1, 8'd5, 8'd7, 8'd254, 1'b0, 1'b1);
        apply_check(3'd7, 8'd3, 8'd9, 8'd1, 1'b0, 1'b0);
        apply_check(3'd1, 8'd9, 8'd9, 8'd0, 1'b1, 1'b0);

        @(negedge clk);
        reset = 1'b1;
        a = 8'd255;
        b = 8'd255;
        op = 3'd0;
        @(negedge clk);
        if (result != 8'd0 || zero != 1'b0 || carry != 1'b0) begin
            $display("TEST: FAIL | Mid-run reset check | Expected: res=0 z=0 c=0 | Output: res=%0d z=%0d c=%0d",
                result, zero, carry);
        end
        @(negedge clk);
        reset = 1'b0;

        apply_check(3'd0, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0);
        apply_check(3'd0, 8'd255, 8'd255, 8'd254, 1'b0, 1'b1);
        apply_check(3'd0, 8'd255, 8'd1, 8'd0, 1'b1, 1'b1);

        apply_check(3'd1, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0);
        apply_check(3'd1, 8'd255, 8'd255, 8'd0, 1'b1, 1'b0);
        apply_check(3'd1, 8'd0, 8'd1, 8'd255, 1'b0, 1'b1);

        apply_check(3'd2, 8'd255, 8'd255, 8'd255, 1'b0, 1'b0);
        apply_check(3'd2, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0);
        apply_check(3'd2, 8'd255, 8'd0, 8'd0, 1'b1, 1'b0);

        apply_check(3'd3, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0);
        apply_check(3'd3, 8'd255, 8'd0, 8'd255, 1'b0, 1'b0);
        apply_check(3'd3, 8'd128, 8'd64, 8'd192, 1'b0, 1'b0);

        apply_check(3'd4, 8'd255, 8'd255, 8'd0, 1'b1, 1'b0);
        apply_check(3'd4, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0);
        apply_check(3'd4, 8'd255, 8'd0, 8'd255, 1'b0, 1'b0);

        apply_check(3'd5, 8'd128, 8'd0, 8'd0, 1'b1, 1'b1);
        apply_check(3'd5, 8'd64, 8'd0, 8'd128, 1'b0, 1'b0);
        apply_check(3'd5, 8'd255, 8'd0, 8'd254, 1'b0, 1'b1);

        apply_check(3'd6, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1);
        apply_check(3'd6, 8'd128, 8'd0, 8'd64, 1'b0, 1'b0);
        apply_check(3'd6, 8'd255, 8'd0, 8'd127, 1'b0, 1'b1);

        apply_check(3'd7, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0);
        apply_check(3'd7, 8'd255, 8'd255, 8'd0, 1'b1, 1'b0);
        apply_check(3'd7, 8'd255, 8'd1, 8'd0, 1'b1, 1'b0);
        apply_check(3'd7, 8'd1, 8'd255, 8'd1, 1'b0, 1'b0);

        @(negedge clk);
        @(negedge clk);

        $finish;
    end

endmodule