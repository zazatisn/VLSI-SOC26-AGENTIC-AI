`timescale 1ns/1ps

module tb_shift_left;
    reg [2:0] shift;
    reg [11:0] fill;
    reg [95:0] in;
    wire [95:0] out;
    wire out_valid;
    
    integer s, j, test_iter;
    reg [11:0] in_arr [0:7];
    reg [11:0] expected_out [0:7];

    shift_left uut (
        .out_valid(out_valid),
        .in(in),
        .shift(shift),
        .fill(fill),
        .out(out)
    );

    initial begin
        // Use a mix of patterned and randomized tests
        for (test_iter = 0; test_iter < 20; test_iter = test_iter + 1) begin
            fill = $random;
            for (j = 0; j < 8; j = j + 1) begin
                in_arr[j] = $random;
            end
            in = {in_arr[7], in_arr[6], in_arr[5], in_arr[4], in_arr[3], in_arr[2], in_arr[1], in_arr[0]};

            for (s = 0; s < 8; s = s + 1) begin
                shift = s;
                #1; // Allow combinatorial logic to settle
                
                if (s <= 5) begin
                    if (out_valid !== 1'b1) begin
                        $display("TEST FAILED: out_valid low for valid shift %d", s);
                        $finish;
                    end
                    
                    for (j = 0; j < 8; j = j + 1) begin
                        if (j < s) expected_out[j] = fill;
                        else expected_out[j] = in_arr[j - s];
                        
                        if (out[(j*12) +: 12] !== expected_out[j]) begin
                            $display("TEST FAILED: Iter %d, Shift %d, index %d: expected %h, got %h", test_iter, s, j, expected_out[j], out[(j*12) +: 12]);
                            $finish;
                        end
                    end
                end else begin
                    if (out_valid !== 1'b0) begin
                        $display("TEST FAILED: out_valid high for invalid shift %d", s);
                        $finish;
                    end
                end
            end
        end
        $display("TEST PASSED");
        $finish;
    end
endmodule