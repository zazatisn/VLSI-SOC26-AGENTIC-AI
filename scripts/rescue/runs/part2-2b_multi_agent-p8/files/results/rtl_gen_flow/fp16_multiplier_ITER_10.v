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
    reg signed [7:0] exp_sum;
    reg [10:0] mantissa;
    reg        guard, round, sticky;
    reg        round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};
        product = sig_a * sig_b;
        
        result = 16'd0;

        if (exp_a == 5'd0 || exp_b == 5'd0) begin
            result = {sign, 15'd0};
        end else if (exp_a == 5'd31 || exp_b == 5'd31) begin
            result = {sign, 5'd31, 10'd0};
        end else begin
            // Calculate exponent: (Ea - 15) + (Eb - 15) + 15 = Ea + Eb - 15
            exp_sum = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 8'd15;

            // Normalize product: product is 22 bits [21:0]. Bit 21 is the 2^1 position.
            if (product[21]) begin
                exp_sum = exp_sum + 1;
                mantissa = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = (|product[8:0]);
            end else begin
                mantissa = product[20:10];
                guard = product[9];
                round = product[8];
                sticky = (|product[7:0]);
            end

            // Rounding to nearest even
            round_up = guard && (round || sticky || mantissa[0]);
            if (round_up) begin
                mantissa = mantissa + 1;
                if (mantissa[11]) begin
                    mantissa = mantissa >> 1;
                    exp_sum = exp_sum + 1;
                end
            end

            // Overflow / Underflow check
            if (exp_sum >= 8'd31) begin
                result = {sign, 5'd31, 10'd0};
            end else if (exp_sum <= 8'd0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, exp_sum[4:0], mantissa[9:0]};
            end
        end
    end
endmodule