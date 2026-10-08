`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg        sign;
    reg [4:0]  exp_a, exp_b;
    reg [10:0] mant_a, mant_b;
    reg [21:0] prod;
    reg [6:0]  res_exp; // Signed range
    reg [10:0] norm_mant;
    reg        guard, round, sticky;
    reg        round_up;
    reg [5:0]  biased_exp;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        mant_a = {1'b1, a[9:0]};
        mant_b = {1'b1, b[9:0]};
        prod = mant_a * mant_b;

        // Zero detection
        if (exp_a == 5'b0 || exp_b == 5'b0) begin
            result = {sign, 15'b0};
        end else begin
            // Exponent math: E = (Ea - 15) + (Eb - 15) + 15 = Ea + Eb - 15
            res_exp = (exp_a + exp_b) - 7'd15;
            
            if (prod[21]) begin
                norm_mant = prod[21:11];
                guard     = prod[10];
                round     = prod[9];
                sticky    = |prod[8:0];
                res_exp   = res_exp + 1'b1;
            end else begin
                norm_mant = prod[20:10];
                guard     = prod[9];
                round     = prod[8];
                sticky    = |prod[7:0];
            end

            // Round to nearest even
            round_up = guard && (round || sticky || norm_mant[0]);
            if (round_up) begin
                norm_mant = norm_mant + 1'b1;
                // Check for carry out from round up
                if (norm_mant[10]) begin
                    norm_mant = norm_mant >> 1;
                    res_exp = res_exp + 1'b1;
                end
            end

            // Final exponent clamping
            if (res_exp >= 7'd31) begin
                // Infinity
                result = {sign, 5'b11111, 10'b0};
            end else if ($signed(res_exp) <= 0) begin
                // Underflow
                result = {sign, 15'b0};
            end else begin
                // Normal
                result = {sign, res_exp[4:0], norm_mant[9:0]};
            end
        end
    end
endmodule