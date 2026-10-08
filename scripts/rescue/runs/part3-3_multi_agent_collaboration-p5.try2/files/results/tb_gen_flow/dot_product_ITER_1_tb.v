`timescale 1ns/1ps

module tb_dot_product;

parameter N = 8;
parameter WIDTH = 8;
parameter CLK_PERIOD = 4.5;

reg clk;
reg rst;
reg [N*WIDTH-1:0] A;
reg [N*WIDTH-1:0] B;
wire signed [2*WIDTH+3:0] dot_out;

integer i, j;
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
    forever #(CLK_PERIOD/2) clk = ~clk;
end

task drive_and_check;
    input [N*WIDTH-1:0] in_A;
    input [N*WIDTH-1:0] in_B;
    begin
        @(negedge clk);
        A = in_A;
        B = in_B;
        
        // Calculate reference in task
        expected = 0;
        for (i = 0; i < N; i = i + 1) begin
            expected = expected + ($signed(in_A[i*WIDTH +: WIDTH]) * $signed(in_B[i*WIDTH +: WIDTH]));
        end

        // Wait 2 cycles for result
        repeat(2) @(negedge clk);
        
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

    // Sample Case
    drive_and_check({8'd6, 8'd22, 8'd50, 8'd37, 8'd14, 8'd31, 8'd50, 8'd256-40}, 
                    {8'd29, 8'd22, 8'd50, 8'd37, 8'd14, 8'd41, 8'd30, 8'd256-1});

    // Zero Case
    drive_and_check(0, 0);

    // Max/Min Case
    drive_and_check({N{8'h7F}}, {N{8'h7F}});
    drive_and_check({N{8'h80}}, {N{8'h80}});

    $finish;
end

endmodule