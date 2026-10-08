`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign;
    reg [4:0] exp_a, exp_b;
    reg [10:0] mant_a, mant_b;
    reg [21:0] prod;
    reg [5:0] raw_exp;
    reg [10:0] norm_mant;
    reg [5:0] res_exp;
    reg guard, round, sticky;
    reg [10:0] rounded_mant;

    always @(*) begin
        // Defaults
        result = 16'b0;
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        mant_a = {1'b1, a[9:0]};
        mant_b = {1'b1, b[9:0]};
        prod = mant_a * mant_b;

        if (exp_a == 5'b0 || exp_b == 5'b0) begin
            result = {sign, 15'b0};
        end else begin
            raw_exp = exp_a + exp_b - 5'd15;
            
            if (prod[21]) begin
                norm_mant = prod[21:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
                res_exp = raw_exp + 1'b1;
            end else begin
                norm_mant = prod[20:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
                res_exp = raw_exp;
            end

            // Rounding to nearest even
            if (guard && (round || sticky || norm_mant[0])) begin
                rounded_mant = norm_mant + 1'b1;
            end else begin
                rounded_mant = norm_mant;
            end

            // Re-normalize if carry out
            if (rounded_mant[10]) begin
                res_exp = res_exp + 1'b1;
                rounded_mant = rounded_mant >> 1;
            end

            // Bounds check
            if (res_exp >= 6'd31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if ($signed(res_exp) <= 0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, res_exp[4:0], rounded_mant[9:0]};
            end
        end
    end
endmodule