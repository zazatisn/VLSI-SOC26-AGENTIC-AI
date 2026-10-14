// Reference testbench for sliding_window_avg_8bit (p13).
// data_out = (data_in + 3 previous samples) >> 2, updated at the rising edge that samples data_in.
// Drives on falling edges, checks on the next falling edge.
`timescale 1ns/1ps

module tb_sliding_window_avg_8bit;
    reg clk, reset;
    reg [7:0] data_in;
    wire [7:0] data_out;
    reg [7:0] h0, h1, h2;          // model history (h0 = most recent)
    reg [9:0] total;
    reg [7:0] expected;
    integer i, errors;

    sliding_window_avg_8bit dut(.clk(clk), .reset(reset), .data_in(data_in), .data_out(data_out));

    initial clk = 0;
    always #5 clk = ~clk;

    task step;
        input r;
        input [7:0] d;
        begin
            reset = r; data_in = d;
            @(negedge clk);
            if (r) begin
                h0 = 0; h1 = 0; h2 = 0; expected = 0;
            end else begin
                total = d + h0 + h1 + h2;
                expected = total[9:2];
                h2 = h1; h1 = h0; h0 = d;
            end
            if (data_out !== expected) begin
                $display("ERROR: reset=%b data_in=%0d data_out=%0d expected=%0d", r, d, data_out, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; h0 = 0; h1 = 0; h2 = 0;
        reset = 1; data_in = 0;
        @(negedge clk);
        step(1, 8'd99);
        step(0, 8'd8); step(0, 8'd12); step(0, 8'd4); step(0, 8'd16);   // spec sample: 2, 5, 6, 10
        step(0, 8'd255); step(0, 8'd255); step(0, 8'd255); step(0, 8'd255); // no overflow: 255
        for (i = 0; i < 50; i = i + 1) step(0, $random);
        step(1, 8'd50); step(0, 8'd40);                                    // reset clears history: 10
        if (errors == 0) $display("Test PASSED!");
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end
endmodule
