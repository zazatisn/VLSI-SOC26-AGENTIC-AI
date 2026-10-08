// Reference testbench for sync_fifo (p16), WIDTH = 8, DEPTH = 8.
// A FIFO model in the testbench predicts dout/full/empty. Drives on falling edges, checks on the
// next falling edge. Tests: fill to full, write while full (dropped), drain to empty, read while
// empty (ignored), simultaneous read + write, 400 random operations, reset with data inside.
`timescale 1ns/1ps

module tb_sync_fifo;
    parameter WIDTH = 8;
    parameter DEPTH = 8;
    reg clk, reset, wr_en, rd_en;
    reg [WIDTH-1:0] din;
    wire [WIDTH-1:0] dout;
    wire full, empty;

    reg [WIDTH-1:0] q [0:DEPTH-1];     // model queue, q[0] = oldest
    integer n, i, j, errors;
    reg [WIDTH-1:0] edout;
    reg can_wr, can_rd;

    sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut(.clk(clk), .reset(reset), .wr_en(wr_en), .rd_en(rd_en),
                                                  .din(din), .dout(dout), .full(full), .empty(empty));

    initial clk = 0;
    always #5 clk = ~clk;

    task step;
        input r, w, rd;
        input [WIDTH-1:0] d;
        begin
            reset = r; wr_en = w; rd_en = rd; din = d;
            can_wr = w && (n < DEPTH);       // decided by the status BEFORE the edge
            can_rd = rd && (n > 0);
            @(negedge clk);
            if (r) begin
                n = 0; edout = 0;
            end else begin
                if (can_rd) begin
                    edout = q[0];
                    for (j = 0; j < DEPTH-1; j = j + 1) q[j] = q[j+1];
                    n = n - 1;
                end
                if (can_wr) begin q[n] = d; n = n + 1; end
            end
            if (dout !== edout || full !== (n == DEPTH) || empty !== (n == 0)) begin
                $display("ERROR: wr=%b rd=%b din=%0d -> dout=%0d full=%b empty=%b, expected %0d %b %b (count %0d)",
                         w, rd, d, dout, full, empty, edout, n == DEPTH, n == 0, n);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; n = 0; edout = 0;
        reset = 1; wr_en = 0; rd_en = 0; din = 0;
        @(negedge clk);
        step(1, 0, 0, 0);
        step(0, 0, 1, 0);                                   // read while empty: ignored
        for (i = 0; i < DEPTH; i = i + 1) step(0, 1, 0, 8'd10 + i);   // fill
        step(0, 1, 0, 8'd99);                               // write while full: dropped
        step(0, 1, 1, 8'd77);                               // full: read happens, write dropped
        step(0, 1, 1, 8'd78);                               // read + write together
        for (i = 0; i < DEPTH + 2; i = i + 1) step(0, 0, 1, 0);       // drain past empty
        step(0, 1, 1, 8'd55);                               // empty: write happens, read ignored
        step(0, 0, 1, 0);
        for (i = 0; i < 400; i = i + 1) step(0, $random, $random, $random);
        step(0, 1, 0, 8'd1); step(0, 1, 0, 8'd2);
        step(1, 0, 0, 0);                                   // reset empties the FIFO
        step(0, 0, 1, 0);
        if (errors == 0) $display("Test PASSED!");
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end
endmodule
