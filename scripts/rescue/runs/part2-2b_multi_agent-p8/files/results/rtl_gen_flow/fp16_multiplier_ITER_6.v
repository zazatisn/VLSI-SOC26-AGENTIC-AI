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
    reg signed [6:0] exp_raw;
    reg [10:0] mant_res;
    reg        guard, round, sticky;
    reg        round_up;
    reg [4:0]  exp_final;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};
        product = sig_a * sig_b;

        // Default outputs
        result = 16'b0;

        // Zero/Inf handling
        if ((exp_a == 5'b0) || (exp_b == 5'b0)) begin
            result = {sign, 15'b0};
        end else if ((exp_a == 5'b11111) || (exp_b == 5'b11111)) begin
            result = {sign, 5'b11111, 10'b0};
        end else begin
            if (product[21]) begin
                exp_raw = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 7'd15;
                mant_res = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = (|product[8:0]);
            end else begin
                exp_raw = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 7'd16;
                mant_res = product[20:10];
                guard = product[9];
                round = product[8];
                sticky = (|product[7:0]);
            end

            round_up = guard && (round || sticky || mant_res[0]);
            if (round_up) begin
                mant_res = mant_res + 1'b1;
                if (mant_res[10]) begin
                    exp_raw = exp_raw + 1'b1;
                    mant_res = {1'b1, 10'b0};
                end
            end

            if (exp_raw >= 7'd31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if (exp_raw <= 7'd0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, exp_raw[4:0], mant_res[9:0]};
            end
        end
    end
endmodule