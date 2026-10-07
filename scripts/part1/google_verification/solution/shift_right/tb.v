`timescale 1ns/1ps

module testbench;
    reg [49:0] in;
    reg [2:0] shift;
    reg [4:0] fill;
    wire [49:0] out;
    wire out_valid;
    
    integer i, j, test_num;
    reg [4:0] expected_symbol;
    reg expected_valid;
    
    // Instantiate the Unit Under Test
    shift_right uut (
        .out_valid(out_valid),
        .in(in),
        .shift(shift),
        .fill(fill),
        .out(out)
    );
    
    initial begin
        test_num = 0;
        
        // Test 1: shift=0, no shift, output should equal input
        test_num = test_num + 1;
        in = 50'b11001_10110_10101_10000_01111_01110_01101_01100_01011_01010;
        shift = 3'b000;
        fill = 5'b11111;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== in) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 2: shift=1, shift right by 1 symbol
        test_num = test_num + 1;
        in = 50'b00001_00010_00011_00100_00101_00110_00111_01000_01001_01010;
        shift = 3'b001;
        fill = 5'b11111;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Symbol 0 should be fill
        if (out[4:0] !== fill) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Symbols 1-9 should be from input 0-8
        for (i = 1; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-1)*5+4:(i-1)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 3: shift=2, shift right by 2 symbols
        test_num = test_num + 1;
        in = 50'b10101_10100_10011_10010_10001_10000_01111_01110_01101_01100;
        shift = 3'b010;
        fill = 5'b00000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Symbols 0-1 should be fill
        for (i = 0; i < 2; i = i + 1) begin
            if (out[i*5+4:i*5] !== fill) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Symbols 2-9 should be from input 0-7
        for (i = 2; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-2)*5+4:(i-2)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 4: shift=3, shift right by 3 symbols
        test_num = test_num + 1;
        in = 50'b11111_11110_11101_11100_11011_11010_11001_11000_10111_10110;
        shift = 3'b011;
        fill = 5'b10101;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Symbols 0-2 should be fill
        for (i = 0; i < 3; i = i + 1) begin
            if (out[i*5+4:i*5] !== fill) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Symbols 3-9 should be from input 0-6
        for (i = 3; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-3)*5+4:(i-3)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 5: shift=4, shift right by 4 symbols (maximum valid)
        test_num = test_num + 1;
        in = 50'b01010_01001_01000_00111_00110_00101_00100_00011_00010_00001;
        shift = 3'b100;
        fill = 5'b01111;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Symbols 0-3 should be fill
        for (i = 0; i < 4; i = i + 1) begin
            if (out[i*5+4:i*5] !== fill) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Symbols 4-9 should be from input 0-5
        for (i = 4; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-4)*5+4:(i-4)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 6: shift=5, invalid shift (out_valid should be low)
        test_num = test_num + 1;
        in = 50'b11111_11111_11111_11111_11111_11111_11111_11111_11111_11111;
        shift = 3'b101;
        fill = 5'b00000;
        #10;
        
        if (out_valid !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 7: shift=6, invalid shift (out_valid should be low)
        test_num = test_num + 1;
        in = 50'b10101_10101_10101_10101_10101_10101_10101_10101_10101_10101;
        shift = 3'b110;
        fill = 5'b01010;
        #10;
        
        if (out_valid !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 8: shift=7, invalid shift (out_valid should be low)
        test_num = test_num + 1;
        in = 50'b00000_00000_00000_00000_00000_00000_00000_00000_00000_00000;
        shift = 3'b111;
        fill = 5'b11111;
        #10;
        
        if (out_valid !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 9: shift=1 with alternating pattern
        test_num = test_num + 1;
        in = 50'b10101_01010_10101_01010_10101_01010_10101_01010_10101_01010;
        shift = 3'b001;
        fill = 5'b11111;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out[4:0] !== fill) begin
            $display("TEST FAILED");
            $finish;
        end
        
        for (i = 1; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-1)*5+4:(i-1)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 10: shift=2 with all ones
        test_num = test_num + 1;
        in = 50'b11111_11111_11111_11111_11111_11111_11111_11111_11111_11111;
        shift = 3'b010;
        fill = 5'b00000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        for (i = 0; i < 2; i = i + 1) begin
            if (out[i*5+4:i*5] !== fill) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        for (i = 2; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-2)*5+4:(i-2)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 11: shift=3 with sequential pattern
        test_num = test_num + 1;
        in = 50'b01001_01000_00111_00110_00101_00100_00011_00010_00001_00000;
        shift = 3'b011;
        fill = 5'b10000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        for (i = 0; i < 3; i = i + 1) begin
            if (out[i*5+4:i*5] !== fill) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        for (i = 3; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-3)*5+4:(i-3)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 12: shift=4 with mixed pattern
        test_num = test_num + 1;
        in = 50'b00101_10010_01100_11001_10011_01101_10110_01111_10000_00001;
        shift = 3'b100;
        fill = 5'b10101;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        for (i = 0; i < 4; i = i + 1) begin
            if (out[i*5+4:i*5] !== fill) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        for (i = 4; i < 10; i = i + 1) begin
            if (out[i*5+4:i*5] !== in[(i-4)*5+4:(i-4)*5]) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All tests passed
        $display("TEST PASSED");
        $finish;
    end
endmodule