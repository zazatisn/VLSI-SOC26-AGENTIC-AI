`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg        sign;
    reg [4:0]  exp_a, exp_b;
    reg [10:0] sig_a, sig_b;
    reg [21:0] product;
    reg [10:0] norm_mantissa;
    reg        guard, round, sticky;
    reg        round_up;
    reg [10:0] final_mantissa;
    reg signed [6:0] exp_temp;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};
        product = sig_a * sig_b;

        // Default outputs
        result = 16'd0;

        if (exp_a == 5'd0 || exp_b == 5'd0) begin
            result = {sign, 15'd0};
        end else begin
            // Normalization: product is [21:0]
            // Bit 21 represents 2^1 (e.g. 1.x * 1.x = 2.x or 1.x)
            if (product[21]) begin
                norm_mantissa = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = |product[8:0];
                exp_temp = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 15 + 1;
            end else begin
                norm_mantissa = product[20:10];
                guard = product[9];
                round = product[8];
                sticky = |product[7:0];
                exp_temp = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 15;
            end

            // Rounding (Nearest even)
            round_up = guard && (round || sticky || norm_mantissa[0]);
            final_mantissa = norm_mantissa + round_up;

            // Handle rounding carry
            if (final_mantissa[10]) begin
                exp_temp = exp_temp + 1;
                final_mantissa = {1'b1, 10'd0};
            end

            // Exponent overflow/underflow
            if (exp_temp >= 31) begin
                result = {sign, 5'b11111, 10'd0};
            end else if (exp_temp <= 0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, exp_temp[4:0], final_mantissa[9:0]};
            end
        end
    end
endmodule