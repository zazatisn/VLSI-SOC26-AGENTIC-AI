`timescale 1ns/1ps

module tb_enc_bin2onehot;
    reg clk;
    reg rst;
    reg in_valid;
    reg [3:0] in;
    wire [14:0] out;
    reg [14:0] expected_out;
    integer i;

    enc_bin2onehot uut (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 1'b0;
        forever #(5) clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        in_valid = 1'b0;
        in = 4'b0;
        #(20);
        rst = 1'b0;
        #(20);

        for (i = 0; i < 16; i = i + 1) begin
            in = i;
            in_valid = 1'b0;
            #(10);
            expected_out = 15'b0;
            if (out !== expected_out) begin
                $display("TEST FAILED");
                $finish;
            end
        end

        for (i = 0; i < 15; i = i + 1) begin
            in = i;
            in_valid = 1'b1;
            #(10);
            expected_out = (15'b1 << in);
            if (out !== expected_out) begin
                $display("TEST FAILED");
                $finish;
            end
        end

        $display("TEST PASSED");
        $finish;
    end
endmodule