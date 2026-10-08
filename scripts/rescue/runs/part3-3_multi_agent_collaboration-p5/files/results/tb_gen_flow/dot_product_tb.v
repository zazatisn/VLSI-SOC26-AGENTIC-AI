`timescale 1ns/1ps

module tb_dot_product;
    parameter N = 8;
    parameter WIDTH = 8;
    parameter PERIOD = 4.5;

    reg clk;
    reg rst;
    reg signed [N*WIDTH-1:0] A;
    reg signed [N*WIDTH-1:0] B;
    wire signed [2*WIDTH+3:0] dot_out;

    integer k;
    reg signed [2*WIDTH+3:0] exp_val;

    dot_product #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .dot_out(dot_out)
    );

    always #(PERIOD/2.0) clk = ~clk;

    task set_vector;
        output [N*WIDTH-1:0] vec;
        input integer v0, v1, v2, v3, v4, v5, v6, v7;
        begin
            vec = {v0[WIDTH-1:0], v1[WIDTH-1:0], v2[WIDTH-1:0], v3[WIDTH-1:0], v4[WIDTH-1:0], v5[WIDTH-1:0], v6[WIDTH-1:0], v7[WIDTH-1:0]};
        end
    endtask

    task apply_and_check;
        input signed [N*WIDTH-1:0] in_a;
        input signed [N*WIDTH-1:0] in_b;
        integer i;
        reg signed [2*WIDTH+3:0] local_sum;
        begin
            @(negedge clk);
            A = in_a;
            B = in_b;
            
            @(negedge clk);
            @(negedge clk);
            
            local_sum = 0;
            for (i = 0; i < N; i = i + 1) begin
                local_sum = local_sum + ($signed(in_a[i*WIDTH +: WIDTH]) * $signed(in_b[i*WIDTH +: WIDTH]));
            end
            exp_val = local_sum;

            if (dot_out === exp_val)
                $display("TEST: PASS | Inputs: A=%h B=%h | Expected: %d | Output: %d", in_a, in_b, exp_val, dot_out);
            else
                $display("TEST: FAIL | Inputs: A=%h B=%h | Expected: %d | Output: %d", in_a, in_b, exp_val, dot_out);
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

        // Sample case
        set_vector(A, -40, 50, -50, 31, 14, 9, 6, -32);
        set_vector(B, -1, 30, 41, 14, 37, 50, 22, 29);
        apply_and_check(A, B);

        // Zero case
        apply_and_check({N*WIDTH{1'b0}}, {N*WIDTH{1'b0}});

        // Max values
        set_vector(A, 127, 127, 127, 127, 127, 127, 127, 127);
        set_vector(B, 127, 127, 127, 127, 127, 127, 127, 127);
        apply_and_check(A, B);

        // Min values
        set_vector(A, -128, -128, -128, -128, -128, -128, -128, -128);
        set_vector(B, -128, -128, -128, -128, -128, -128, -128, -128);
        apply_and_check(A, B);

        $finish;
    end
endmodule