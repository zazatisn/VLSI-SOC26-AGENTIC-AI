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
integer j;
reg signed [2*WIDTH+3:0] expected;

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

task check_dot;
    input [N*WIDTH-1:0] in_A;
    input [N*WIDTH-1:0] in_B;
    begin
        @(negedge clk);
        A = in_A;
        B = in_B;
        
        expected = 0;
        for (j = 0; j < N; j = j + 1) begin
            expected = expected + ($signed(in_A[j*WIDTH +: WIDTH]) * $signed(in_B[j*WIDTH +: WIDTH]));
        end

        @(negedge clk); // Latency 1
        @(negedge clk); // Latency 2: result ready
        
        if (dot_out === expected) begin
            $display("TEST: PASS | Inputs: A=%h, B=%h | Expected: %d | Output: %d", in_A, in_B, expected, dot_out);
        end else begin
            $display("TEST: FAIL | Inputs: A=%h, B=%h | Expected: %d | Output: %d", in_A, in_B, expected, dot_out);
        end
    end
endtask

initial begin
    rst = 1;
    A = 0;
    B = 0;
    
    repeat(2) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // Sample Case: A = {-40, 50, -50, 31, 14, 9, 6, -32}, B = {-1, 30, 41, 14, 37, 50, 22, 29}
    // A: d8 32 ce 1f 0e 09 06 e0
    // B: ff 1e 29 0e 25 32 16 1d
    check_dot(64'hD832CE1F0E0906E0, 64'hFF1E290E2532161D);

    // Zero Case
    check_dot(64'h0, 64'h0);

    // Max/Min Values: 127 and -128
    check_dot(64'h7F7F7F7F7F7F7F7F, 64'h8080808080808080);

    $finish;
end

endmodule