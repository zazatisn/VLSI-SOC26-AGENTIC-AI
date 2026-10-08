`timescale 1ns/1ps

module seq_detector_0011_tb;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;
    
    integer error_count;
    integer i;
    
    reg [0:15] in_v1;
    reg [0:15] out_v1;
    reg [0:14] in_v2;
    reg [0:14] out_v2;
    
    reg expected_bit;
    
    seq_detector_0011 dut(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .detected(detected)
    );
    
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        data_in = 1'b1;
        error_count = 32'h00000000;
        
        in_v1 = 16'b0001100110110010;
        out_v1 = 16'b0000010001000000;
        in_v2 = 15'b001100110000011;
        out_v2 = 15'b000010001000001;
        
        repeat(2) @(posedge clk);
        
        @(negedge clk);
        reset = 1'b0;
        
        for (i = 0; i < 16; i = i + 1) begin
            expected_bit = out_v1[i];
            if (detected === expected_bit) begin
                $display("TEST: PASS | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", in_v1[i], i, expected_bit, detected);
            end else begin
                $display("TEST: FAIL | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", in_v1[i], i, expected_bit, detected);
                error_count = error_count + 1;
            end
            @(negedge clk);
            data_in = in_v1[i];
        end
        
        for (i = 0; i < 15; i = i + 1) begin
            expected_bit = out_v2[i];
            if (detected === expected_bit) begin
                $display("TEST: PASS | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", in_v2[i], i, expected_bit, detected);
            end else begin
                $display("TEST: FAIL | Inputs: data_in=%b idx=%0d | Expected: %b | Output: %b", in_v2[i], i, expected_bit, detected);
                error_count = error_count + 1;
            end
            @(negedge clk);
            data_in = in_v2[i];
        end
        
        @(negedge clk);
        if (detected === 1'b0) begin
            $display("TEST: PASS | Inputs: data_in=%b idx=final | Expected: %b | Output: %b", data_in, 1'b0, detected);
        end else begin
            $display("TEST: FAIL | Inputs: data_in=%b idx=final | Expected: %b | Output: %b", data_in, 1'b0, detected);
            error_count = error_count + 1;
        end
        
        $display("DONE");
        $finish;
    end
    
    always #(0.55) clk = ~clk;
    
endmodule