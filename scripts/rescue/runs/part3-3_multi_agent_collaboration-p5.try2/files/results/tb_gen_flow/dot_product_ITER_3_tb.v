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
reg signed [N*WIDTH-1:0] temp_A;
reg signed [N*WIDTH-1:0] temp_B;

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
    input signed [N*WIDTH-1:0] in_A;
    input signed [N*WIDTH-1:0] in_B;
    begin
        @(negedge clk);
        A = in_A;
        B = in_B;
        
        expected = 0;
        for (i = 0; i < N; i = i + 1) begin
            expected = expected + ($signed(in_A[(i*WIDTH) +: WIDTH]) * $signed(in_B[(i*WIDTH) +: WIDTH]));
        end

        repeat(2) @(negedge clk);
        
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
    temp_A = {8'sd-40, 8'sd50, 8'sd-50, 8'sd31, 8'sd14, 8'sd9, 8'sd6, 8'sd-32};
    temp_B = {8'sd-1, 8'sd30, 8'sd41, 8'sd14, 8'sd37, 8'sd50, 8'sd22, 8'sd29};
    run_test(temp_A, temp_B);

    // Zero Case
    run_test({N*WIDTH{1'b0}}, {N*WIDTH{1'b0}});

    // Max Values
    run_test({N{8'sd127}}, {N{8'sd127}});
    
    // Min Values
    run_test({N{8'sd-128}}, {N{8'sd-128}});

    $finish;
end

endmodule