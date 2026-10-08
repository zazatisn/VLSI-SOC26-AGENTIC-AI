`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign;
    reg [4:0] exp_a, exp_b;
    reg [10:0] sig_a, sig_b;
    reg [21:0] product;
    reg [5:0] exp_sum;
    reg [10:0] norm_sig;
    reg [4:0] exp_res;
    reg guard, round, sticky;
    reg round_up;
    reg [10:0] rounded_sig_full;

    always @(*) begin
        // Default values to prevent latches
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};
        
        if ((exp_a == 5'd0) || (exp_b == 5'd0)) begin
            result = {sign, 15'b0};
        end else begin
            exp_sum = exp_a + exp_b - 5'd15;
            product = sig_a * sig_b;
            
            if (product[21]) begin
                norm_sig = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = (|product[8:0]);
                exp_res = exp_sum + 5'd1;
            end else begin
                norm_sig = product[20:10];
                guard = product[9];
                round = product[8];
                sticky = (|product[7:0]);
                exp_res = exp_sum;
            end
            
            // Round to nearest even
            round_up = guard && (round || sticky || norm_sig[0]);
            rounded_sig_full = {1'b0, norm_sig[9:0]} + round_up;
            
            // Check for exponent overflow / normalization carry
            if (rounded_sig_full[10]) begin
                exp_res = exp_res + 5'd1;
                rounded_sig_full = 11'b0;
            end
            
            if (exp_res >= 5'd31) begin
                result = {sign, 5'd31, 10'd0}; // Infinity
            end else if ($signed(exp_res) <= 0) begin
                result = {sign, 15'd0};        // Underflow
            end else begin
                result = {sign, exp_res, rounded_sig_full[9:0]};
            end
        end
    end
endmodule