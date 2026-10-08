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

    always #(PERIOD/2.0) clk = ~clk;

    task check_dot;
        input [N*WIDTH-1:0] inA;
        input [N*WIDTH-1:0] inB;
        begin
            @(negedge clk);
            A = inA;
            B = inB;
            
            // Calculate expected
            expected = 0;
            for (i = 0; i < N; i = i + 1) begin
                expected = expected + ($signed(inA[i*WIDTH +: WIDTH]) * $signed(inB[i*WIDTH +: WIDTH]));
            end

            // Wait 2 cycles for latency
            @(negedge clk);
            @(negedge clk);

            if (dot_out === expected) begin
                $display("TEST: PASS | Inputs: A=%h, B=%h | Expected: %d | Output: %d", A, B, expected, dot_out);
            end else begin
                $display("TEST: FAIL | Inputs: A=%h, B=%h | Expected: %d | Output: %d", A, B, expected, dot_out);
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        A = 0;
        B = 0;
        
        // Reset sequence
        repeat(3) @(negedge clk);
        rst = 0;

        // Case 1: Sample from spec
        // A: [-40, 50, -50, 31, 14, 9, 6, -32]
        // B: [-1, 30, 41, 14, 37, 50, 22, 29]
        check_dot(
            {8'shD8, 8'sh06, 8'sh09, 8'sh0E, 8'sh1F, 8'shCE, 8'sh32, 8'shD8},
            {8'sh1D, 8'sh16, 8'sh32, 8'sh25, 8'sh0E, 8'sh29, 8'sh1E, 8'shFF}
        );

        // Case 2: Zeros
        check_dot({N*WIDTH{1'b0}}, {N*WIDTH{1'b0}});

        // Case 3: Ones
        check_dot({N{8'sh01}}, {N{8'sh01}});

        // Case 4: Alternating
        check_dot({4{8'sh0A, 8'shF6}}, {4{8'sh02, 8'sh02}});

        #20 $finish;
    end

endmodule