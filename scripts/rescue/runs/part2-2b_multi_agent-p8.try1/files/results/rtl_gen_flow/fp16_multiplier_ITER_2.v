`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign_a, sign_b, res_sign;
    reg [4:0] exp_a, exp_b;
    reg [10:0] mant_a, mant_b;
    reg [22:0] product;
    reg [5:0] exp_sum;
    reg [10:0] round_mant;
    reg [4:0] final_exp;
    reg [9:0] final_mant;
    reg guard, round, sticky;
    reg round_up;

    always @(*) begin
        sign_a = a[15];
        sign_b = b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        mant_a = {1'b1, a[9:0]};
        mant_b = {1'b1, b[9:0]};
        res_sign = sign_a ^ sign_b;

        if ((exp_a == 5'b0) || (exp_b == 5'b0)) begin
            result = {res_sign, 15'b0};
        end else begin
            product = mant_a * mant_b;
            exp_sum = exp_a + exp_b - 5'd15;

            if (product[22]) begin
                round_mant = product[22:12];
                guard = product[11];
                round = product[10];
                sticky = |product[9:0];
                final_exp = exp_sum + 5'd1;
            end else begin
                round_mant = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = |product[8:0];
                final_exp = exp_sum;
            end

            // Round to nearest even
            round_up = guard && (round || sticky || round_mant[0]);

            if (round_up) begin
                round_mant = round_mant + 1'b1;
                if (round_mant[10]) begin
                    round_mant = {1'b1, 10'b0};
                    final_exp = final_exp + 5'd1;
                end
            end

            if (final_exp >= 5'd31) begin
                result = {res_sign, 5'b11111, 10'b0};
            end else if (final_exp < 5'd1) begin
                result = {res_sign, 15'b0};
            end else begin
                result = {res_sign, final_exp, round_mant[9:0]};
            end
        end
    end
endmodule