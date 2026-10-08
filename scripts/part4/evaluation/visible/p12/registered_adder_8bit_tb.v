// Reference testbench for registered_adder_8bit (p12).
// Drives on falling edges, checks on the next falling edge (latency 1). Sum is modulo 256.
`timescale 1ns/1ps

module tb_registered_adder_8bit;
    reg clk, reset;
    reg [7:0] a, b;
    wire [7:0] sum;
    reg  [7:0] expected;
    integer i, errors;

    registered_adder_8bit dut(.clk(clk), .reset(reset), .a(a), .b(b), .sum(sum));

    initial clk = 0;
    always #5 clk = ~clk;

    task step;
        input r;
        input [7:0] x, y;
        begin
            reset = r; a = x; b = y;
            @(negedge clk);
            expected = r ? 8'd0 : x + y;
            if (sum !== expected) begin
                $display("ERROR: reset=%b a=%0d b=%0d sum=%0d expected=%0d", r, x, y, sum, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        reset = 1; a = 0; b = 0;
        @(negedge clk);
        step(1, 8'd7, 8'd9);                  // reset wins
        step(0, 8'd5, 8'd10);                 // spec sample: 15
        step(0, 8'd128, 8'd1);                // spec sample: 129
        step(0, 8'd200, 8'd100);              // overflow: 44
        step(0, 8'd255, 8'd255);              // 254
        step(0, 8'd0, 8'd0);
        for (i = 0; i < 50; i = i + 1) step(0, $random, $random);
        step(1, 8'd1, 8'd1); step(0, 8'd3, 8'd4);
        if (errors == 0) $display("Test PASSED!");
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end
endmodule
