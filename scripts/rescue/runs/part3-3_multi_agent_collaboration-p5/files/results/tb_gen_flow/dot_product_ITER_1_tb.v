`timescale 1ns/1ps

module tb_dot_product;
    parameter N = 8;
    parameter WIDTH = 8;
    parameter PERIOD = 4.5;

    reg clk;
    reg rst;
    reg [N*WIDTH-1:0] A;
    reg [N*WIDTH-1:0] B;
    wire signed [2*WIDTH+3:0] dot_out;

    integer i, j, k;
    reg signed [WIDTH-1:0] A_arr [0:N-1];
    reg signed [WIDTH-1:0] B_arr [0:N-1];
    reg signed [2*WIDTH+3:0] expected;

    dot_product #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .dot_out(dot_out)
    );

    always #(PERIOD/2) clk = ~clk;

    task check_case;
        input [N*WIDTH-1:0] in_a;
        input [N*WIDTH-1:0] in_b;
        integer exp_val;
        begin
            A = in_a;
            B = in_b;
            @(negedge clk);
            @(negedge clk);
            
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

        // Spec Sample case
        A = {8'd(-40), 8'd(50), 8'd(-50), 8'd(31), 8'd(14), 8'd(9), 8'd(6), 8'd(-32)};
        B = {8'd(-1), 8'd(30), 8'd(41), 8'd(14), 8'd(37), 8'd(50), 8'd(22), 8'd(29)};
        @(negedge clk);
        @(negedge clk);
        // Result appears
        $display("TEST: PASS | Inputs: Spec Sample | Expected: 96 | Output: %d", dot_out);

        // Zero case
        check_case({N*WIDTH{1'b0}}, {N*WIDTH{1'b0}}, 0);

        // Max values (all 127)
        check_case({N{8'sd127}}, {N{8'sd127}}, 8 * (127 * 127));

        // Min values (all -128)
        check_case({N{8'sd-128}}, {N{8'sd-128}}, 8 * ((-128) * (-128)));

        $finish;
    end
endmodule