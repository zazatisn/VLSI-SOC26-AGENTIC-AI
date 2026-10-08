`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg        sign;
    reg [4:0]  exp_a, exp_b;
    reg [10:0] sig_a, sig_b;
    reg [21:0] prod;
    reg [10:0] mantissa;
    reg signed [9:0] exp_sum;
    reg        guard, round, sticky;
    reg        round_up;
    reg [4:0]  exp_out;
    reg [9:0]  mant_out;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};

        result = 16'b0;

        if ((exp_a == 5'd0) || (exp_b == 5'd0)) begin
            result = {sign, 15'b0};
        end else begin
            prod = sig_a * sig_b;
            exp_sum = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 10'd15;

            // prod is 22 bits: [21] is 2^1, [20] is 2^0, [19:0] are fractional
            if (prod[21]) begin
                mantissa = prod[21:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
                exp_sum = exp_sum + 1;
            end else begin
                mantissa = prod[20:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
            end

            round_up = guard && (round || sticky || mantissa[0]);

            if (round_up) begin
                mantissa = mantissa + 1;
                if (mantissa[10]) begin
                    mantissa = {1'b1, 10'd0};
                    exp_sum = exp_sum + 1;
                end
            end

            exp_out = exp_sum[4:0];
            mant_out = mantissa[9:0];

            if (exp_sum >= 10'd31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if (exp_sum <= 10'd0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, exp_out, mant_out};
            end
        end
    end
endmodule