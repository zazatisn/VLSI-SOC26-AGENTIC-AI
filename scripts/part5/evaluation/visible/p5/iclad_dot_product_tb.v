// Reference testbench for dot_product (p5).
// Corrected from the ICLAD 2025 original, which waited for a 'valid' output that the
// specification does not have. This version follows the spec: latency 2, one result per cycle.
// Tests: the spec example (96), 12 random vector pairs streamed back to back, a reset in the middle of traffic.
`timescale 1ns/1ps

module tb_dot_product;

    parameter N = 8;
    parameter WIDTH = 8;
    parameter NT = 13;

    reg clk;
    reg rst;
    reg signed [N*WIDTH-1:0] A;
    reg signed [N*WIDTH-1:0] B;
    wire signed [2*WIDTH+3:0] dot_out;

    dot_product #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .A(A), .B(B), .dot_out(dot_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg signed [N*WIDTH-1:0]  va [0:NT-1];
    reg signed [N*WIDTH-1:0]  vb [0:NT-1];
    reg signed [2*WIDTH+3:0]  exp_v [0:NT-1];
    reg signed [WIDTH-1:0] ea, eb;
    integer i, k, errors;

    initial begin
        errors = 0;
        // Spec example: A = [-40, 50, -50, 31, 14, 9, 6, -32], B = [-1, 30, 41, 14, 37, 50, 22, 29] -> 96
        va[0] = 0; vb[0] = 0;
        va[0][0*WIDTH +: WIDTH] = -40; vb[0][0*WIDTH +: WIDTH] = -1;
        va[0][1*WIDTH +: WIDTH] =  50; vb[0][1*WIDTH +: WIDTH] = 30;
        va[0][2*WIDTH +: WIDTH] = -50; vb[0][2*WIDTH +: WIDTH] = 41;
        va[0][3*WIDTH +: WIDTH] =  31; vb[0][3*WIDTH +: WIDTH] = 14;
        va[0][4*WIDTH +: WIDTH] =  14; vb[0][4*WIDTH +: WIDTH] = 37;
        va[0][5*WIDTH +: WIDTH] =   9; vb[0][5*WIDTH +: WIDTH] = 50;
        va[0][6*WIDTH +: WIDTH] =   6; vb[0][6*WIDTH +: WIDTH] = 22;
        va[0][7*WIDTH +: WIDTH] = -32; vb[0][7*WIDTH +: WIDTH] = 29;
        for (k = 1; k < NT; k = k + 1) begin
            va[k] = {$random, $random};
            vb[k] = {$random, $random};
        end
        va[NT-1] = {N{8'h80}}; vb[NT-1] = {N{8'h80}};    // corner case: all -128
        for (k = 0; k < NT; k = k + 1) begin
            exp_v[k] = 0;
            for (i = 0; i < N; i = i + 1) begin
                ea = va[k][i*WIDTH +: WIDTH];
                eb = vb[k][i*WIDTH +: WIDTH];
                exp_v[k] = exp_v[k] + ea * eb;
            end
        end

        rst = 1; A = 0; B = 0;
        @(posedge clk); @(posedge clk);
        @(negedge clk);
        if (dot_out !== 0) begin
            $display("ERROR: dot_out = %0d during reset, expected 0", dot_out);
            errors = errors + 1;
        end
        rst = 0;

        // Stream one vector pair per cycle; result k is visible 2 falling edges after it is driven
        for (k = 0; k < NT + 2; k = k + 1) begin
            if (k < NT) begin A = va[k]; B = vb[k]; end
            else        begin A = 0;     B = 0;     end
            if (k >= 2) begin
                if (dot_out === exp_v[k-2])
                    $display("Vector %0d: dot_out = %0d (ok)", k-2, dot_out);
                else begin
                    $display("ERROR vector %0d: dot_out = %0d, expected %0d", k-2, dot_out, exp_v[k-2]);
                    errors = errors + 1;
                end
            end
            @(negedge clk);
        end

        // Reset in the middle of traffic, with non-zero inputs: dot_out must be 0 after the first reset edge
        A = va[1]; B = vb[1];
        @(negedge clk); @(negedge clk);
        rst = 1;
        @(negedge clk);
        if (dot_out !== 0) begin
            $display("ERROR: dot_out = %0d after a reset edge, expected 0", dot_out);
            errors = errors + 1;
        end
        @(negedge clk);
        if (dot_out !== 0) begin
            $display("ERROR: dot_out = %0d during reset, expected 0", dot_out);
            errors = errors + 1;
        end
        rst = 0;

        if (errors == 0) $display("Test PASSED!");
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end

endmodule
