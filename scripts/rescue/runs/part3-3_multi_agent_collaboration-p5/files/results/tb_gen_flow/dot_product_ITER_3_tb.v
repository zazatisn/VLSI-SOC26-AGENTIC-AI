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
    integer i;
    reg signed [2*WIDTH+3:0] exp_val;
    reg signed [WIDTH-1:0] A_arr [0:N-1];
    reg signed [WIDTH-1:0] B_arr [0:N-1];

    dot_product #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .dot_out(dot_out)
    );

    always #(PERIOD/2.0) clk = ~clk;

    task apply_and_check;
        input signed [N*WIDTH-1:0] in_a;
        input signed [N*WIDTH-1:0] in_b;
        begin
            @(negedge clk);
            A = in_a;
            B = in_b;
            
            // Wait 2 cycles for pipeline
            repeat(2) @(negedge clk);
            
            exp_val = 0;
            for (k = 0; k < N; k = k + 1) begin
                exp_val = exp_val + ($signed(in_a[k*WIDTH +: WIDTH]) * $signed(in_b[k*WIDTH +: WIDTH]));
            end

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

        repeat(4) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // Sample case
        A = {8'sd-40, 8'sd50, 8'sd-50, 8'sd31, 8'sd14, 8'sd9, 8'sd6, 8'sd-32};
        B = {8'sd-1, 8'sd30, 8'sd41, 8'sd14, 8'sd37, 8'sd50, 8'sd22, 8'sd29};
        apply_and_check(A, B);

        // Zero case
        apply_and_check({N*WIDTH{1'b0}}, {N*WIDTH{1'b0}});

        // Max values
        for (i = 0; i < N; i = i + 1) begin
            A[i*WIDTH +: WIDTH] = 8'sd127;
            B[i*WIDTH +: WIDTH] = 8'sd127;
        end
        apply_and_check(A, B);

        // Min values
        for (i = 0; i < N; i = i + 1) begin
            A[i*WIDTH +: WIDTH] = -8'sd128;
            B[i*WIDTH +: WIDTH] = -8'sd128;
        end
        apply_and_check(A, B);

        $finish;
    end
endmodule