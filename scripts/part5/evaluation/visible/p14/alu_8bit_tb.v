// Reference testbench for alu_8bit (p14).
// Drives on falling edges, checks result/zero/carry on the next falling edge (latency 1).
// Tests: the spec samples, every operation on corner operands, 300 random operations, reset.
`timescale 1ns/1ps

module tb_alu_8bit;
    reg clk, reset;
    reg [7:0] a, b;
    reg [2:0] op;
    wire [7:0] result;
    wire zero, carry;
    reg [7:0] er; reg ez, ec; reg [8:0] t;
    integer i, j, errors;

    alu_8bit dut(.clk(clk), .reset(reset), .a(a), .b(b), .op(op), .result(result), .zero(zero), .carry(carry));

    initial clk = 0;
    always #5 clk = ~clk;

    task model;        // expected outputs for op, a, b
        input [2:0] o; input [7:0] x, y;
        begin
            ec = 0; er = 0;
            case (o)
                3'd0: begin t = x + y; er = t[7:0]; ec = t[8]; end
                3'd1: begin t = {1'b0, x} - {1'b0, y}; er = t[7:0]; ec = (x < y); end
                3'd2: er = x & y;
                3'd3: er = x | y;
                3'd4: er = x ^ y;
                3'd5: begin er = x << 1; ec = x[7]; end
                3'd6: begin er = x >> 1; ec = x[0]; end
                3'd7: er = (x < y) ? 8'd1 : 8'd0;
            endcase
            ez = (er == 0);
        end
    endtask

    task step;
        input r; input [2:0] o; input [7:0] x, y;
        begin
            reset = r; op = o; a = x; b = y;
            @(negedge clk);
            if (r) begin er = 0; ez = 0; ec = 0; end
            else model(o, x, y);
            if (result !== er || zero !== ez || carry !== ec) begin
                $display("ERROR: reset=%b op=%0d a=%0d b=%0d -> result=%0d zero=%b carry=%b, expected %0d %b %b",
                         r, o, x, y, result, zero, carry, er, ez, ec);
                errors = errors + 1;
            end
        end
    endtask

    reg [7:0] corner [0:5];
    initial begin
        errors = 0;
        corner[0] = 0; corner[1] = 1; corner[2] = 8'h7f; corner[3] = 8'h80; corner[4] = 8'hfe; corner[5] = 8'hff;
        reset = 1; op = 0; a = 0; b = 0;
        @(negedge clk);
        step(1, 3'd0, 8'd1, 8'd1);
        step(0, 3'd0, 8'd200, 8'd100);   // spec sample: 44, carry 1
        step(0, 3'd1, 8'd5, 8'd7);       // spec sample: 254, borrow 1
        step(0, 3'd7, 8'd3, 8'd9);       // spec sample: 1
        step(0, 3'd1, 8'd9, 8'd9);       // 0, zero flag
        for (i = 0; i < 8; i = i + 1)
            for (j = 0; j < 36; j = j + 1)
                step(0, i, corner[j / 6], corner[j % 6]);
        for (i = 0; i < 300; i = i + 1) step(0, $random, $random, $random);
        step(1, 3'd0, 8'd3, 8'd4);
        if (errors == 0) $display("Test PASSED!");
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end
endmodule
