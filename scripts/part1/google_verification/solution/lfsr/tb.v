`timescale 1ns/1ps

module testbench;
    reg clk;
    reg rst;
    reg reinit;
    reg advance;
    reg [4:0] initial_state;
    reg [4:0] taps;
    wire out;
    wire [4:0] out_state;
    
    integer i;
    integer j;
    reg [4:0] expected_state;
    reg [4:0] temp_and;
    reg feedback_bit;
    
    // Instantiate the LFSR module
    lfsr uut (
        .clk(clk),
        .rst(rst),
        .reinit(reinit),
        .advance(advance),
        .out(out),
        .initial_state(initial_state),
        .taps(taps),
        .out_state(out_state)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Main test procedure
    initial begin
        // Initialize control signals
        rst = 0;
        reinit = 0;
        advance = 0;
        initial_state = 5'b00000;
        taps = 5'b00000;
        #20;
        
        // Test 1: Reset functionality
        rst = 1;
        reinit = 0;
        advance = 0;
        initial_state = 5'b10101;
        taps = 5'b10011;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b10101) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 2: Release reset and hold state
        rst = 0;
        reinit = 0;
        advance = 0;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b10101) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 3: Advance with taps = 5'b10011
        // Current state: 5'b10101
        // AND result: 5'b10101 & 5'b10011 = 5'b10001
        // XOR reduce: 1 ^ 0 ^ 0 ^ 0 ^ 1 = 0
        // New state: {0101, 0} = 5'b01010
        advance = 1;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b01010) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 4: Advance again
        // Current state: 5'b01010
        // AND result: 5'b01010 & 5'b10011 = 5'b00010
        // XOR reduce: 0 ^ 0 ^ 0 ^ 1 ^ 0 = 1
        // New state: {1010, 1} = 5'b11010
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11010) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 5: Advance again
        // Current state: 5'b11010
        // AND result: 5'b11010 & 5'b10011 = 5'b10010
        // XOR reduce: 1 ^ 0 ^ 0 ^ 1 ^ 0 = 0
        // New state: {1010, 0} = 5'b01010
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b01010) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 6: Test reinit precedence over advance
        reinit = 1;
        advance = 1;
        initial_state = 5'b11110;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11110) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 7: Hold state when both reinit and advance are low
        reinit = 0;
        advance = 0;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11110) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 8: Advance from 5'b11110
        // AND result: 5'b11110 & 5'b10011 = 5'b10010
        // XOR reduce: 1 ^ 0 ^ 0 ^ 1 ^ 0 = 0
        // New state: {1110, 0} = 5'b01110
        advance = 1;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b01110) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 9: Advance again
        // Current state: 5'b01110
        // AND result: 5'b01110 & 5'b10011 = 5'b00010
        // XOR reduce: 0 ^ 0 ^ 0 ^ 1 ^ 0 = 1
        // New state: {1110, 1} = 5'b11110
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11110) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 10: Test with different initial state and taps
        advance = 0;
        reinit = 1;
        initial_state = 5'b00001;
        taps = 5'b11111;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b00001) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 11: Advance with all taps set
        // Current state: 5'b00001
        // AND result: 5'b00001 & 5'b11111 = 5'b00001
        // XOR reduce: 0 ^ 0 ^ 0 ^ 0 ^ 1 = 1
        // New state: {0000, 1} = 5'b10000
        reinit = 0;
        advance = 1;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b10000) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 12: Advance again
        // Current state: 5'b10000
        // AND result: 5'b10000 & 5'b11111 = 5'b10000
        // XOR reduce: 1 ^ 0 ^ 0 ^ 0 ^ 0 = 1
        // New state: {0000, 1} = 5'b10000
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b10000) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 13: Test with no taps
        reinit = 1;
        advance = 0;
        initial_state = 5'b10000;
        taps = 5'b00000;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b10000) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 14: Advance with no taps (feedback should be 0)
        // Current state: 5'b10000
        // AND result: 5'b10000 & 5'b00000 = 5'b00000
        // XOR reduce: 0 ^ 0 ^ 0 ^ 0 ^ 0 = 0
        // New state: {0000, 0} = 5'b00000
        reinit = 0;
        advance = 1;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b00000) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 15: Test edge case - all ones
        reinit = 1;
        initial_state = 5'b11111;
        taps = 5'b10101;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11111) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 16: Advance from all ones
        // Current state: 5'b11111
        // AND result: 5'b11111 & 5'b10101 = 5'b10101
        // XOR reduce: 1 ^ 0 ^ 1 ^ 0 ^ 1 = 1
        // New state: {1111, 1} = 5'b11111
        reinit = 0;
        advance = 1;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11111) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 17: Test with taps = 5'b11110
        reinit = 1;
        initial_state = 5'b10101;
        taps = 5'b11110;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b10101) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 18: Advance
        // Current state: 5'b10101
        // AND result: 5'b10101 & 5'b11110 = 5'b10100
        // XOR reduce: 1 ^ 0 ^ 1 ^ 0 ^ 0 = 0
        // New state: {0101, 0} = 5'b01010
        reinit = 0;
        advance = 1;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b01010) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 19: Test with taps = 5'b00001
        reinit = 1;
        initial_state = 5'b11111;
        taps = 5'b00001;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11111) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 20: Advance
        // Current state: 5'b11111
        // AND result: 5'b11111 & 5'b00001 = 5'b00001
        // XOR reduce: 0 ^ 0 ^ 0 ^ 0 ^ 1 = 1
        // New state: {1111, 1} = 5'b11111
        reinit = 0;
        advance = 1;
        @(posedge clk);
        #10;
        
        if (out_state !== 5'b11111) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // All tests passed
        $display("TEST PASSED");
        $finish;
    end
endmodule