// Reference testbench for simple_8bit_counter (p11).
// Drives on falling edges, checks on the next falling edge (latency 1).
// Tests: reset, counting, hold with en = 0, wrap 255 -> 0, reset in the middle.
`timescale 1ns/1ps

module tb_simple_8bit_counter;
    reg clk, reset, en;
    wire [7:0] count;
    reg  [7:0] model;
    integer i, errors;

    simple_8bit_counter dut(.clk(clk), .reset(reset), .en(en), .count(count));

    initial clk = 0;
    always #5 clk = ~clk;

    task step;          // apply reset/en for one cycle, then compare with the model
        input r, e;
        begin
            reset = r; en = e;
            @(negedge clk);
            if (r)      model = 0;
            else if (e) model = model + 1;
            if (count !== model) begin
                $display("ERROR: reset=%b en=%b count=%0d expected=%0d", r, e, count, model);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; model = 0;
        reset = 1; en = 0;
        @(negedge clk);
        step(1, 0); step(1, 1);                          // reset wins over en
        step(0, 1); step(0, 1); step(0, 0); step(0, 0);   // count, then hold
        for (i = 0; i < 260; i = i + 1) step(0, 1);       // wraps 255 -> 0
        step(0, 0); step(1, 1); step(0, 1);               // reset in the middle
        for (i = 0; i < 40; i = i + 1) step(0, $random);  // random enable
        if (errors == 0) $display("Test PASSED!");
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end
endmodule
