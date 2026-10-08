`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign_a, sign_b, res_sign;
    reg [4:0] exp_a, exp_b, res_exp;
    reg [10:0] mant_a, mant_b;
    reg [21:0] prod;
    reg [10:0] sig_a, sig_b;
    reg [22:0] product;
    reg [4:0] exp_sum;
    reg [10:0] norm_mant;
    reg [4:0] norm_exp;
    reg round_bit, guard_bit, sticky_bit;
    reg round_up;

    always @(*) begin
        sign_a = a[15];
        sign_b = b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        mant_a = {1'b1, a[9:0]};
        mant_b = {1'b1, b[9:0]};

        res_sign = sign_a ^ sign_b;

        // Zero case detection
        if ((exp_a == 5'b0) || (exp_b == 5'b0)) begin
            result = {res_sign, 15'b0};
        end else begin
            product = mant_a * mant_b;
            exp_sum = exp_a + exp_b - 5'd15;

            // Normalization
            if (product[22]) begin
                norm_mant = product[21:11];
                guard_bit = product[10];
                sticky_bit = |product[9:0];
                norm_exp = exp_sum + 5'd1;
            end else begin
                norm_mant = product[20:10];
                guard_bit = product[9];
                sticky_bit = |product[8:0];
                norm_exp = exp_sum;
            end

            // Round to nearest even
            round_bit = norm_mant[0];
            round_up = guard_bit && (round_bit || sticky_bit);

            if (norm_exp >= 5'd31) begin
                result = {res_sign, 5'b11111, 10'b0}; // Infinity
            end else if (norm_exp < 5'd1) begin
                result = {res_sign, 15'b0}; // Underflow
            end else begin
                result = {res_sign, norm_exp, norm_mant[9:0]};
                if (round_up) begin
                    result[9:0] = result[9:0] + 1'b1;
                    if (result[9:0] == 10'b0) begin
                        result[14:10] = result[14:10] + 1'b1;
                    end
                end
            end
        end
    end
endmodule