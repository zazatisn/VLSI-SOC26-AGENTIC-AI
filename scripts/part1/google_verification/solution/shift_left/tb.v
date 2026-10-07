`timescale 1ns/1ps

module testbench;
    // Declarations at the top
    reg [95:0] in;
    reg [2:0] shift;
    reg [11:0] fill;
    wire [95:0] out;
    wire out_valid;
    integer i, j;
    integer expected_symbol, actual_symbol;
    integer bit_start;
    
    // Instantiate the Unit Under Test
    shift_left uut (
        .out_valid(out_valid),
        .in(in),
        .shift(shift),
        .fill(fill),
        .out(out)
    );
    
    initial begin
        // Test 1: Shift = 0, no shift
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b000;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        if (out !== in) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 2: Shift = 1
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b001;
        fill = 12'hFFF;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Position 0 should be fill
        actual_symbol = out[11:0] & 12'hFFF;
        if (actual_symbol !== 12'hFFF) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Position 1 should be in[0]
        actual_symbol = (out >> 12) & 12'hFFF;
        expected_symbol = in[11:0] & 12'hFFF;
        if (actual_symbol !== expected_symbol) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Position 2 should be in[1]
        actual_symbol = (out >> 24) & 12'hFFF;
        expected_symbol = (in >> 12) & 12'hFFF;
        if (actual_symbol !== expected_symbol) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 3: Shift = 2
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b010;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-1 should be fill
        for (i = 0; i < 2; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Position 2 should be in[0]
        actual_symbol = (out >> 24) & 12'hFFF;
        expected_symbol = in[11:0] & 12'hFFF;
        if (actual_symbol !== expected_symbol) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 4: Shift = 3
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b011;
        fill = 12'h555;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-2 should be fill
        for (i = 0; i < 3; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h555) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 5: Shift = 4
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b100;
        fill = 12'hAAA;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-3 should be fill
        for (i = 0; i < 4; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hAAA) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 6: Shift = 5
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b101;
        fill = 12'hDDD;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-4 should be fill
        for (i = 0; i < 5; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hDDD) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 7: Shift = 6 (invalid)
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b110;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 8: Shift = 7 (invalid)
        in = 96'h000001000002000003000004000005000006000007000008;
        shift = 3'b111;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b0) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Test 9: Shift = 1 with distinctive values
        in = 96'h000100020003000400050006000700080;
        shift = 3'b001;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Verify position 0 is fill
        actual_symbol = out[11:0] & 12'hFFF;
        if (actual_symbol !== 12'h000) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Verify positions 1-7 are shifted
        for (i = 1; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 1) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 10: Shift = 2 with distinctive values
        in = 96'h000100020003000400050006000700080;
        shift = 3'b010;
        fill = 12'h111;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Verify positions 0-1 are fill
        for (i = 0; i < 2; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h111) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify positions 2-7 are shifted
        for (i = 2; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 2) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 11: Shift = 3 with distinctive values
        in = 96'h000100020003000400050006000700080;
        shift = 3'b011;
        fill = 12'h222;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Verify positions 0-2 are fill
        for (i = 0; i < 3; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h222) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify positions 3-7 are shifted
        for (i = 3; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 3) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 12: Shift = 4 with distinctive values
        in = 96'h000100020003000400050006000700080;
        shift = 3'b100;
        fill = 12'h333;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Verify positions 0-3 are fill
        for (i = 0; i < 4; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h333) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify positions 4-7 are shifted
        for (i = 4; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 4) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 13: Shift = 5 with distinctive values
        in = 96'h000100020003000400050006000700080;
        shift = 3'b101;
        fill = 12'h444;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Verify positions 0-4 are fill
        for (i = 0; i < 5; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h444) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify positions 5-7 are shifted
        for (i = 5; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 5) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 14: All ones input with zero fill, shift = 1
        in = 96'hFFFFFFFFFFFFFFFFFFFFFFFFF;
        shift = 3'b001;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Position 0 must be fill (0x000)
        actual_symbol = out[11:0] & 12'hFFF;
        if (actual_symbol !== 12'h000) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // All other positions must be 0xFFF
        for (i = 1; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 15: All zeros input with ones fill, shift = 1
        in = 96'h000000000000000000000000;
        shift = 3'b001;
        fill = 12'hFFF;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Position 0 must be fill (0xFFF)
        actual_symbol = out[11:0] & 12'hFFF;
        if (actual_symbol !== 12'hFFF) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // All other positions must be 0x000
        for (i = 1; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 16: Shift = 2 with all ones input, zero fill
        in = 96'hFFFFFFFFFFFFFFFFFFFFFFFFF;
        shift = 3'b010;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-1 must be fill (0x000)
        for (i = 0; i < 2; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0xFFF
        for (i = 2; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 17: Shift = 3 with all ones input, zero fill
        in = 96'hFFFFFFFFFFFFFFFFFFFFFFFFF;
        shift = 3'b011;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-2 must be fill (0x000)
        for (i = 0; i < 3; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0xFFF
        for (i = 3; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 18: Shift = 4 with all ones input, zero fill
        in = 96'hFFFFFFFFFFFFFFFFFFFFFFFFF;
        shift = 3'b100;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-3 must be fill (0x000)
        for (i = 0; i < 4; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0xFFF
        for (i = 4; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 19: Shift = 5 with all ones input, zero fill
        in = 96'hFFFFFFFFFFFFFFFFFFFFFFFFF;
        shift = 3'b101;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-4 must be fill (0x000)
        for (i = 0; i < 5; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0xFFF
        for (i = 5; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 20: Shift = 2 with all zeros input, ones fill
        in = 96'h000000000000000000000000;
        shift = 3'b010;
        fill = 12'hFFF;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-1 must be fill (0xFFF)
        for (i = 0; i < 2; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0x000
        for (i = 2; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 21: Shift = 3 with all zeros input, ones fill
        in = 96'h000000000000000000000000;
        shift = 3'b011;
        fill = 12'hFFF;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-2 must be fill (0xFFF)
        for (i = 0; i < 3; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0x000
        for (i = 3; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 22: Shift = 4 with all zeros input, ones fill
        in = 96'h000000000000000000000000;
        shift = 3'b100;
        fill = 12'hFFF;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-3 must be fill (0xFFF)
        for (i = 0; i < 4; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0x000
        for (i = 4; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 23: Shift = 5 with all zeros input, ones fill
        in = 96'h000000000000000000000000;
        shift = 3'b101;
        fill = 12'hFFF;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-4 must be fill (0xFFF)
        for (i = 0; i < 5; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'hFFF) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All other positions must be 0x000
        for (i = 5; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h000) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 24: Shift = 1 with alternating pattern
        in = 96'h555AAAA555AAAA555AAAA555;
        shift = 3'b001;
        fill = 12'h000;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Position 0 must be fill
        actual_symbol = out[11:0] & 12'hFFF;
        if (actual_symbol !== 12'h000) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Verify shifted positions
        for (i = 1; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 1) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 25: Shift = 2 with alternating pattern
        in = 96'h555AAAA555AAAA555AAAA555;
        shift = 3'b010;
        fill = 12'h111;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-1 must be fill
        for (i = 0; i < 2; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h111) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify shifted positions
        for (i = 2; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 2) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 26: Shift = 3 with alternating pattern
        in = 96'h555AAAA555AAAA555AAAA555;
        shift = 3'b011;
        fill = 12'h222;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-2 must be fill
        for (i = 0; i < 3; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h222) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify shifted positions
        for (i = 3; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 3) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 27: Shift = 4 with alternating pattern
        in = 96'h555AAAA555AAAA555AAAA555;
        shift = 3'b100;
        fill = 12'h333;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-3 must be fill
        for (i = 0; i < 4; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h333) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify shifted positions
        for (i = 4; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 4) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Test 28: Shift = 5 with alternating pattern
        in = 96'h555AAAA555AAAA555AAAA555;
        shift = 3'b101;
        fill = 12'h444;
        #10;
        
        if (out_valid !== 1'b1) begin
            $display("TEST FAILED");
            $finish;
        end
        
        // Positions 0-4 must be fill
        for (i = 0; i < 5; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            if (actual_symbol !== 12'h444) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // Verify shifted positions
        for (i = 5; i < 8; i = i + 1) begin
            bit_start = i * 12;
            actual_symbol = (out >> bit_start) & 12'hFFF;
            expected_symbol = (in >> ((i - 5) * 12)) & 12'hFFF;
            if (actual_symbol !== expected_symbol) begin
                $display("TEST FAILED");
                $finish;
            end
        end
        
        // All tests passed
        $display("TEST PASSED");
        $finish;
    end
endmodule