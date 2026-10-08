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

    integer i, j;
    reg signed [2*WIDTH+3:0] expected;
    reg signed [WIDTH-1:0] A_arr[0:N-1];
    reg signed [WIDTH-1:0] B_arr[0:N-1];

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

    task check_result;
        input [N*WIDTH-1:0] a_val;
        input [N*WIDTH-1:0] b_val;
        begin
            expected = calc_dot(a_val, b_val);
            if (dot_out === expected) begin
                $display("TEST: PASS | Inputs: A=%h, B=%h | Expected: %d | Output: %d", a_val, b_val, expected, dot_out);
            end else begin
                $display("TEST: FAIL | Inputs: A=%h, B=%h | Expected: %d | Output: %d", a_val, b_val, expected, dot_out);
            end
        end
    endtask

    initial begin
        rst = 1;
        A = 0;
        B = 0;
        repeat(3) @(negedge clk);
        rst = 0;

        // Case 1: Spec example
        @(negedge clk);
        A = {8'd(-32), 8'd6, 8'd9, 8'd14, 8'd31, 8'd(-50), 8'd50, 8'd(-40)};
        B = {8'd29, 8'd22, 8'd50, 8'd37, 8'd14, 8'd41, 8'd30, 8'd(-1)};
        
        @(negedge clk);
        // Pipeline slot 1
        @(negedge clk);
        // Pipeline slot 2 - Result appears
        check_result(A, B);

        // Case 2: Zero inputs
        @(negedge clk);
        A = 0; B = 0;
        repeat(2) @(negedge clk);
        check_result(A, B);

        // Case 3: Max values
        @(negedge clk);
        A = {(N){8'h7F}};
        B = {(N){8'h7F}};
        repeat(2) @(negedge clk);
        check_result(A, B);

        // Case 4: Min values
        @(negedge clk);
        A = {(N){8'h80}};
        B = {(N){8'h80}};
        repeat(2) @(negedge clk);
        check_result(A, B);

        $finish;
    end
endmodule