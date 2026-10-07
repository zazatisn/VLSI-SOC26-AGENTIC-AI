// Verilog-2001 Testbench for dot_product
`timescale 1ns/1ps

module tb_dot_product;

    // Parameters (removed 'int' keyword)
    parameter N = 8;
    parameter WIDTH = 8;

    // Standard Verilog types: reg for drivers, wire for monitors
    reg clk;
    reg rst;
    reg signed [N*WIDTH-1:0] A; // Flattened vector
    reg signed [N*WIDTH-1:0] B; // Flattened vector
    wire signed [2*WIDTH+3:0] dot_out;
    wire valid;

    // Instantiate DUT (Standard Verilog-2001 syntax)
    dot_product #(
        .N(N),
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .dot_out(dot_out),
        .valid(valid)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Internal unpacked arrays for easy math calculation in TB
    reg signed [WIDTH-1:0] a_array [0:N-1];
    reg signed [WIDTH-1:0] b_array [0:N-1];

    integer i;
    reg signed [2*WIDTH+3:0] expected_result;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        A = 0;
        B = 0;
        #10;
        rst = 0;

        // Generate test vectors
        expected_result = 0;
        for (i = 0; i < N; i = i + 1) begin
            // Generate random values
            a_array[i] = ($random % 50); 
            b_array[i] = ($random % 50);
            
            // Pack the values into the flattened vectors A and B
            // Using indexed part-select for Verilog compatibility
            A[i*WIDTH +: WIDTH] = a_array[i];
            B[i*WIDTH +: WIDTH] = b_array[i];
            
            // Calculate expected result
            expected_result = expected_result + (a_array[i] * b_array[i]);
        end

        // Display inputs
        $display("A (hex flattened) = %h", A);
        $display("B (hex flattened) = %h", B);
        $write("A elements: ");
        for (i = 0; i < N; i = i + 1) $write("%0d ", a_array[i]);
        $display();
        $write("B elements: ");
        for (i = 0; i < N; i = i + 1) $write("%0d ", b_array[i]);
        $display();
        $display("Expected dot product: %0d", expected_result);

        // Wait for valid output
        // Verilog-2001 doesn't have 'wait' in the same SV context sometimes, 
        // but 'wait' on a wire is generally supported.
        wait (valid == 1'b1);
        #1; // Small delay to settle

        // Check result
        if (dot_out === expected_result) begin
            $display("PASS: Output = %0d", dot_out);
        end else begin
            $display("FAIL: Output = %0d, Expected = %0d", dot_out, expected_result);
        end

        $finish;
    end

endmodule