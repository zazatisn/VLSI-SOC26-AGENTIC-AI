// Reference testbench for uart_tx (p15), CLKS_PER_BIT = 8.
// A frame is: start bit (0), 8 data bits LSB first, stop bit (1); each bit lasts CLKS_PER_BIT cycles.
// The testbench samples tx in the middle of every bit and checks busy cycle by cycle.
// Tests: spec sample 0x35, 0x00, 0xFF, a start request while busy (ignored), back-to-back frames,
// 10 random bytes, reset in the middle of a frame.
`timescale 1ns/1ps

module tb_uart_tx;
    parameter CPB = 8;
    reg clk, reset, start;
    reg [7:0] data_in;
    wire tx, busy;
    integer i, n, errors;

    uart_tx #(.CLKS_PER_BIT(CPB)) dut(.clk(clk), .reset(reset), .start(start), .data_in(data_in), .tx(tx), .busy(busy));

    initial clk = 0;
    always #5 clk = ~clk;

    task expect_line;
        input t, bz;
        input [8*24:1] what;
        begin
            if (tx !== t || busy !== bz) begin
                $display("ERROR (%0s): tx=%b busy=%b, expected tx=%b busy=%b", what, tx, busy, t, bz);
                errors = errors + 1;
            end
        end
    endtask

    // Send one byte: start is high for one rising edge (edge k). Then check the 10 bits,
    // sampling tx on the falling edge in the middle of each bit, and busy on every cycle.
    task send;
        input [7:0] d;
        input poke;                    // 1: raise start again in the middle of the frame (must be ignored)
        reg [9:0] frame;
        integer b, k;
        begin
            frame = {1'b1, d, 1'b0};
            data_in = d; start = 1;
            @(negedge clk);            // edge k has sampled start
            start = 0; data_in = 8'h00;
            for (b = 0; b < 10; b = b + 1) begin
                for (k = 0; k < CPB; k = k + 1) begin
                    if (k == CPB/2) expect_line(frame[b], 1'b1, "bit middle");
                    else if (busy !== 1'b1) begin $display("ERROR: busy dropped inside bit %0d", b); errors = errors + 1; end
                    if (poke && b == 4 && k == 2) begin start = 1; data_in = 8'h3c; end
                    if (poke && b == 4 && k == 3) begin start = 0; data_in = 8'h00; end
                    @(negedge clk);
                end
            end
            expect_line(1'b1, 1'b0, "idle after stop bit");   // edge k + 10*CPB returned to idle
        end
    endtask

    initial begin
        errors = 0;
        reset = 1; start = 0; data_in = 0;
        @(negedge clk); @(negedge clk);
        expect_line(1'b1, 1'b0, "reset");
        reset = 0;
        @(negedge clk);
        expect_line(1'b1, 1'b0, "idle");

        send(8'h35, 0);                // spec sample (not a bit-palindrome: catches MSB-first)
        send(8'h00, 0);                // back-to-back: start on the first idle cycle
        @(negedge clk); @(negedge clk);
        expect_line(1'b1, 1'b0, "idle line stays 1");
        send(8'hFF, 1);                // start pulse during the frame is ignored
        @(negedge clk);
        expect_line(1'b1, 1'b0, "ignored start");
        for (n = 0; n < 10; n = n + 1) send($random, 0);

        // reset in the middle of a frame
        data_in = 8'h0f; start = 1; @(negedge clk); start = 0;
        repeat (3 * CPB) @(negedge clk);
        reset = 1; @(negedge clk);
        expect_line(1'b1, 1'b0, "reset mid-frame");
        reset = 0; @(negedge clk);
        send(8'h1e, 0);

        if (errors == 0) $display("Test PASSED!");
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end
endmodule
