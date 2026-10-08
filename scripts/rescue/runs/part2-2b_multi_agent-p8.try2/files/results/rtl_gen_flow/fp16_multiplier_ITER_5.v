`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign;
    reg [4:0] exp_a, exp_b;
    reg [10:0] man_a, man_b;
    reg [21:0] prod;
    reg signed [6:0] exp_sum;
    reg [10:0] mantissa;
    reg [4:0] exponent;
    reg guard, round_bit, sticky;
    reg round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        man_a = {1'b1, a[9:0]};
        man_b = {1'b1, b[9:0]};
        prod = man_a * man_b;

        // Default result logic
        if ((exp_a == 5'd0) || (exp_b == 5'd0)) begin
            result = {sign, 15'd0};
        end else if ((exp_a == 5'd31) || (exp_b == 5'd31)) begin
            result = {sign, 5'b11111, 10'd0};
        end else begin
            exp_sum = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 7'd15;
            
            if (prod[21]) begin
                exponent = exp_sum[4:0];
                mantissa = prod[21:11];
                guard = prod[10];
                round_bit = prod[9];
                sticky = |prod[8:0];
            end else begin
                exponent = exp_sum[4:0] - 5'd1;
                mantissa = prod[20:10];
                guard = prod[9];
                round_bit = prod[8];
                sticky = |prod[7:0];
            end

            round_up = guard && (round_bit || sticky || mantissa[0]);
            if (round_up) begin
                mantissa = mantissa + 1'b1;
                if (mantissa[10]) begin
                    mantissa = mantissa >> 1;
                    exponent = exponent + 5'd1;
                end
            end

            if ($signed(exponent) >= 5'd31) begin
                result = {sign, 5'b11111, 10'd0};
            end else if ($signed(exponent) <= 0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, exponent, mantissa[9:0]};
            end
        end
    end
endmodule