`timescale 1ns/1ps

module tb_counter;

    reg clk;
    reg rst;
    reg reinit;
    reg incr_valid;
    reg decr_valid;
    reg [3:0] initial_value;
    reg [1:0] incr;
    reg [1:0] decr;
    wire [3:0] value;
    wire [3:0] value_next;

    counter uut (
        .clk(clk),
        .rst(rst),
        .reinit(reinit),
        .incr_valid(incr_valid),
        .decr_valid(decr_valid),
        .initial_value(initial_value),
        .incr(incr),
        .decr(decr),
        .value(value),
        .value_next(value_next)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        reinit = 0;
        incr_valid = 0;
        decr_valid = 0;
        initial_value = 5;
        incr = 0;
        decr = 0;

        #10 rst = 0;
        #10;
        if (value !== 5) begin $display("TEST FAILED"); $finish; end

        // Test Increment: 5 + 2 = 7
        incr_valid = 1; incr = 2;
        #10; 
        if (value !== 7) begin $display("TEST FAILED"); $finish; end

        // Test Overflow: 7 + 3 = 10
        incr = 3;
        #10;
        if (value !== 10) begin $display("TEST FAILED"); $finish; end

        // Test Wrap: 10 + 3 = 13 mod 11 = 2
        incr = 3;
        #10;
        if (value !== 2) begin $display("TEST FAILED"); $finish; end

        // Test Underflow: 2 - 3 = -1 -> 10
        incr_valid = 0; decr_valid = 1; decr = 3;
        #10;
        if (value !== 10) begin $display("TEST FAILED"); $finish; end

        // Test Concurrent: 10 + 1 - 2 = 9
        incr_valid = 1; incr = 1; decr = 2;
        #10;
        if (value !== 9) begin $display("TEST FAILED"); $finish; end

        // Test Reinit
        reinit = 1; incr_valid = 0; decr_valid = 0;
        #10;
        if (value !== 5) begin $display("TEST FAILED"); $finish; end

        $display("TEST PASSED");
        $finish;
    end
endmodule