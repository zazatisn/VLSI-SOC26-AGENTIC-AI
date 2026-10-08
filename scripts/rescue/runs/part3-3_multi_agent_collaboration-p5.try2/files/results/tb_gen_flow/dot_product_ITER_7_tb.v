`timescale 1ns/1ps

module tb_dot_product;

parameter N = 8;
parameter WIDTH = 8;
parameter CLK_PERIOD = 4.5;

reg clk;
reg rst;
reg signed [N*WIDTH-1:0] A;
reg signed [N*WIDTH-1:0] B;
wire signed [2*WIDTH+3:0] dot_out;

integer i;
reg signed [2*WIDTH+3:0] expected;
reg signed [WIDTH-1:0] A_arr [0:N-1];
reg signed [WIDTH-1:0] B_arr [0:N-1];

dot_product #(.N(N), .WIDTH(WIDTH)) dut (
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),
    .dot_out(dot_out)
);

initial begin
    clk = 0;
    forever #(CLK_PERIOD/2.0) clk = ~clk;
end

task run_test;
    input [N*WIDTH-1:0] in_A;
    input [N*WIDTH-1:0] in_B;
    begin
        @(negedge clk);
        A = in_A;
        B = in_B;
        
        expected = 0;
        for (i = 0; i < N; i = i + 1) begin
            expected = expected + ($signed(in_A[i*WIDTH +: WIDTH]) * $signed(in_B[i*WIDTH +: WIDTH]));
        end

        @(negedge clk);
        @(negedge clk);
        
        if (dot_out === expected) begin
            $display("TEST: PASS | Inputs: A=%h, B=%h | Expected: %d | Output: %d", in_A, in_B, expected, dot_out);
        end else begin
            $display("TEST: FAIL | Inputs: A=%h, B=%h | Expected: %d | Output: %d", in_A, in_B, expected, dot_out);
        end
    end
endtask

initial begin
    clk = 0;
    rst = 1;
    A = 0;
    B = 0;
    
    repeat(2) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // Sample Case
    run_test(128'hD832CE1F0E0906E0, 128'hFF1E290E2532161D);

    // Zero Case
    run_test(0, 0);

    // Max/Min Values
    run_test({8{8'sd127}}, {8{8'sd-128}});

    $finish;
end

endmodule