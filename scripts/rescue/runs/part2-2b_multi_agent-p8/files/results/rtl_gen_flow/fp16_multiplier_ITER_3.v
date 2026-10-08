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
    reg signed [7:0] exp_sum;
    reg [4:0] res_exp;
    reg [9:0] res_mant;
    reg guard, round, sticky;
    reg round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        mant_a = {1'b1, a[9:0]};
        mant_b = {1'b1, b[9:0]};
        
        if (exp_a == 5'b0 || exp_b == 5'b0) begin
            result = {sign, 15'b0};
        end else begin
            exp_sum = exp_a + exp_b - 5'd15;
            prod = mant_a * mant_b;
            
            if (prod[21]) begin
                res_exp = exp_sum + 1;
                res_mant = prod[20:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
            end else begin
                res_exp = exp_sum;
                res_mant = prod[19:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
            end

            round_up = guard && (round || sticky || res_mant[0]);
            
            if (round_up) begin
                {res_mant, res_exp} = {res_mant, res_exp} + 1'b1;
            end

            if ($signed(res_exp) >= 31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if ($signed(res_exp) <= 0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, res_exp, res_mant};
            end
        end
    end
endmodule