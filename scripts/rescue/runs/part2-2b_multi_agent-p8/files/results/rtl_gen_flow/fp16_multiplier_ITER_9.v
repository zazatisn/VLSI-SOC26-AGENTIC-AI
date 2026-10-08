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
    reg [5:0]  exp_sum;
    reg [11:0] mant_rounded;
    reg [5:0]  exp_final;
    reg        guard, round, sticky;
    reg [10:0] mant_shifted;
    reg        round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};
        product = sig_a * sig_b;

        // Default
        result = 16'd0;

        if (exp_a == 5'd0 || exp_b == 5'd0) begin
            result = {sign, 15'd0};
        end else if (exp_a == 5'd31 || exp_b == 5'd31) begin
            result = {sign, 5'd31, 10'd0};
        end else begin
            exp_sum = exp_a + exp_b - 5'd15;
            
            if (product[21]) begin
                exp_final = exp_sum + 6'd1;
                mant_shifted = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = (|product[8:0]);
            end else begin
                exp_final = exp_sum;
                mant_shifted = product[20:10];
                guard = product[9];
                round = product[8];
                sticky = (|product[7:0]);
            end

            round_up = guard && (round || sticky || mant_shifted[0]);
            mant_rounded = mant_shifted + (round_up ? 1'b1 : 1'b0);

            if (mant_rounded[11]) begin
                exp_final = exp_final + 6'd1;
                mant_rounded = {1'b1, 10'd0, 1'b0};
            end

            if (exp_final >= 6'd31) begin
                result = {sign, 5'd31, 10'd0};
            end else if (exp_final[5] || exp_final == 6'd0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, exp_final[4:0], mant_rounded[10:1]};
            end
        end
    end
endmodule