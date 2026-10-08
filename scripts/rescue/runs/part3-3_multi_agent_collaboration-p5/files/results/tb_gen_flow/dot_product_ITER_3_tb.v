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

    reg signed [N*WIDTH-1:0] history_A [0:2];
    reg signed [N*WIDTH-1:0] history_B [0:2];
    reg signed [2*WIDTH+3:0] expected_val;

    integer i;
    integer j;

    dot_product #(
        .N(N),
        .WIDTH(WIDTH)
    ) dut (
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

    function signed [2*WIDTH+3:0] calc_dot;
        input [N*WIDTH-1:0] a_in;
        input [N*WIDTH-1:0] b_in;
        integer k;
        reg signed [WIDTH-1:0] a_val;
        reg signed [WIDTH-1:0] b_val;
        begin
            calc_dot = 0;
            for (k = 0; k < N; k = k + 1) begin
                a_val = a_in[k*WIDTH +: WIDTH];
                b_val = b_in[k*WIDTH +: WIDTH];
                calc_dot = calc_dot + (a_val * b_val);
            end
        end
    endfunction

    task run_test;
        input [N*WIDTH-1:0] a_val;
        input [N*WIDTH-1:0] b_val;
        begin
            @(negedge clk);
            A <= a_val;
            B <= b_val;
            history_A[0] = a_val;
            history_B[0] = b_val;
            
            // Wait 2 cycles for pipeline
            repeat(2) @(negedge clk);
            
            expected_val = calc_dot(history_A[0], history_B[0]);
            if (dot_out === expected_val) begin
                $display("TEST: PASS | Inputs: A=%h, B=%h | Expected: %d | Output: %d", history_A[0], history_B[0], expected_val, dot_out);
            end else begin
                $display("TEST: FAIL | Inputs: A=%h, B=%h | Expected: %d | Output: %d", history_A[0], history_B[0], expected_val, dot_out);
            end
        end
    endtask

    initial begin
        rst = 1; A = 0; B = 0;
        repeat(2) @(negedge clk);
        rst = 0;
        @(negedge clk);

        run_test({8'd(-32), 8'd6, 8'd9, 8'd14, 8'd31, 8'd(-50), 8'd50, 8'd(-40)}, {8'd29, 8'd22, 8'd50, 8'd37, 8'd14, 8'd41, 8'd30, 8'd(-1)});
        run_test(64'd0, 64'd0);
        run_test(64'h7F7F7F7F7F7F7F7F, 64'h7F7F7F7F7F7F7F7F);
        run_test(64'h8080808080808080, 64'h8080808080808080);
        
        $finish;
    end
endmodule