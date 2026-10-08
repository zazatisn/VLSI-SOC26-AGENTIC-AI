`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign;
    reg [4:0] exp_a, exp_b, exp_res;
    reg [10:0] sig_a, sig_b;
    reg [21:0] product;
    reg [4:0] sum_exp;
    reg [10:0] norm_sig;
    reg [9:0] rounded_sig;
    reg guard, round, sticky;
    reg round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};
        
        // Zero detection
        if ((exp_a == 5'd0) || (exp_b == 5'd0)) begin
            result = {sign, 15'b0};
        end else begin
            sum_exp = exp_a + exp_b - 5'd15;
            product = sig_a * sig_b;
            
            // Normalize product [1, 4) -> [1, 2)
            if (product[21]) begin
                norm_sig = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = (|product[8:0]);
                exp_res = sum_exp + 5'd1;
            end else begin
                norm_sig = product[20:10];
                guard = product[9];
                round = product[8];
                sticky = (|product[7:0]);
                exp_res = sum_exp;
            end
            
            // Round to nearest even
            round_up = guard && (round || sticky || norm_sig[0]);
            rounded_sig = norm_sig[9:0] + round_up;
            
            // Check for carry out from rounding
            if (rounded_sig == 10'b0 && round_up) begin
                exp_res = exp_res + 5'd1;
            end
            
            // Check overflow/underflow
            if (exp_res >= 5'd31) begin
                result = {sign, 5'd31, 10'd0}; // Infinity
            end else if (exp_res <= 5'd0) begin
                result = {sign, 15'd0};        // Underflow to zero
            end else begin
                result = {sign, exp_res, rounded_sig};
            end
        end
    end
endmodule