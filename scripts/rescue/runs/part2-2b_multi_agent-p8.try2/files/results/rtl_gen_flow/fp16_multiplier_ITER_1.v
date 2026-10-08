`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign;
    reg [4:0] exp_a, exp_b, exp_res;
    reg [10:0] man_a, man_b;
    reg [21:0] prod;
    reg [9:0] round_bit;
    reg guard, round, sticky;
    reg [22:0] normalized_man;
    reg [4:0] final_exp;
    reg [9:0] final_man;

    always @(*) begin
        // Default assignments
        result = 16'b0;
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        man_a = {1'b1, a[9:0]};
        man_b = {1'b1, b[9:0]};
        prod = man_a * man_b;
        
        // Zero detection
        if (exp_a == 5'd0 || exp_b == 5'd0) begin
            result = {sign, 15'b0};
        end else begin
            // Calculate Exponent
            exp_res = exp_a + exp_b - 5'd15;
            
            // Normalize Product
            if (prod[21]) begin
                final_exp = exp_res + 1'b1;
                normalized_man = {1'b0, prod[21:0]};
            end else begin
                final_exp = exp_res;
                normalized_man = {prod[21:0], 1'b0};
            end
            
            // Rounding (Nearest Even)
            // normalized_man is {hidden, frac[9:0], guard, round, sticky}
            // For FP16, we keep 10 bits of fraction. 
            // Position of guard bit is index 11 (if hidden is 22)
            guard = normalized_man[11];
            round = normalized_man[10];
            sticky = |normalized_man[9:0];
            
            if (guard && (round || sticky || normalized_man[12])) begin
                normalized_man[22:12] = normalized_man[22:12] + 1'b1;
            end
            
            // Overflow / Underflow check
            if (final_exp >= 5'd31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if (final_exp <= 5'd0) begin
                result = {sign, 15'b0};
            end else begin
                final_man = normalized_man[21:12];
                // Check if rounding caused exponent overflow
                if (normalized_man[22]) begin
                    result = {sign, final_exp + 1'b1, 10'b0};
                end else begin
                    result = {sign, final_exp, final_man};
                end
            end
        end
    end
endmodule