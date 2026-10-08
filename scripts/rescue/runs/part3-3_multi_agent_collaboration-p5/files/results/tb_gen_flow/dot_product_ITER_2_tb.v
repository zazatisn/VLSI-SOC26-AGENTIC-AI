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

    reg signed [2*WIDTH+3:0] expected_pipe [0:1];
    reg signed [N*WIDTH-1:0] A_pipe [0:1];
    reg signed [N*WIDTH-1:0] B_pipe [0:1];

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

    task drive_and_expect;
        input [N*WIDTH-1:0] a_val;
        input [N*WIDTH-1:0] b_val;
        begin
            @(negedge clk);
            A = a_val;
            B = b_val;
            A_pipe[1] = A_pipe[0]; A_pipe[0] = a_val;
            B_pipe[1] = B_pipe[0]; B_pipe[0] = b_val;
            expected_pipe[1] = expected_pipe[0];
            expected_pipe[0] = calc_dot(a_val, b_val);
            
            @(negedge clk);
            @(negedge clk);
            if (dot_out === expected_pipe[1]) begin
                $display("TEST: PASS | Inputs: A=%h, B=%h | Expected: %d | Output: %d", A_pipe[1], B_pipe[1], expected_pipe[1], dot_out);
            end else begin
                $display("TEST: FAIL | Inputs: A=%h, B=%h | Expected: %d | Output: %d", A_pipe[1], B_pipe[1], expected_pipe[1], dot_out);
            end
        end
    endtask

    initial begin
        rst = 1; A = 0; B = 0;
        repeat(2) @(negedge clk);
        rst = 0;
        @(negedge clk);

        drive_and_expect({8'd(-32), 8'd6, 8'd9, 8'd14, 8'd31, 8'd(-50), 8'd50, 8'd(-40)}, {8'd29, 8'd22, 8'd50, 8'd37, 8'd14, 8'd41, 8'd30, 8'd(-1)});
        drive_and_expect(64'd0, 64'd0);
        drive_and_expect(64'h7F7F7F7F7F7F7F7F, 64'h7F7F7F7F7F7F7F7F);
        drive_and_expect(64'h8080808080808080, 64'h8080808080808080);
        
        $finish;
    end
endmodule