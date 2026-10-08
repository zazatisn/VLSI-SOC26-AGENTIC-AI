`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg        sign;
    reg signed [6:0] raw_exp;
    reg [10:0] mant_a, mant_b;
    reg [21:0] prod;
    reg [4:0]  final_exp;
    reg [9:0]  final_mant;
    reg        guard, round, sticky;

    always @(*) begin
        sign = a[15] ^ b[15];
        result = 16'b0;

        if ((a[14:10] == 5'b0) || (b[14:10] == 5'b0)) begin
            result = {sign, 15'b0};
        end else begin
            raw_exp = a[14:10] + b[14:10] - 15;
            mant_a = {1'b1, a[9:0]};
            mant_b = {1'b1, b[9:0]};
            prod = mant_a * mant_b;

            if (prod[21]) begin
                final_exp = raw_exp[4:0];
                final_mant = prod[20:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
            end else begin
                final_exp = raw_exp[4:0] - 1;
                final_mant = prod[19:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
            end

            if (guard && (round || sticky || final_mant[0])) begin
                final_mant = final_mant + 1;
                if (final_mant == 10'b0) begin
                    final_exp = final_exp + 1;
                end
            end

            if (final_exp >= 31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if ($signed(raw_exp) <= 0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, final_exp, final_mant};
            end
        end
    end
endmodule