`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg        sign;
    reg signed [5:0] raw_exp;
    reg [10:0] mant_a, mant_b;
    reg [23:0] prod;
    reg [4:0]  final_exp;
    reg [9:0]  final_mant;
    reg        round_bit, sticky_bit, guard_bit;

    always @(*) begin
        // Defaults
        result = 16'b0;
        sign = a[15] ^ b[15];
        
        // Exponents and Mantissas
        // If exponent is 0, treat as 0.0 per spec.
        if (a[14:10] == 5'b0 || b[14:10] == 5'b0) begin
            result = {sign, 15'b0};
        end else begin
            raw_exp = a[14:10] + b[14:10] - 15;
            mant_a = {1'b1, a[9:0]};
            mant_b = {1'b1, b[9:0]};
            prod = mant_a * mant_b; // 12 * 12 = 24 bits

            // Normalization
            if (prod[23]) begin
                final_exp = raw_exp + 1;
                // Guard: prod[12], Round: prod[11], Sticky: |prod[10:0]
                guard_bit = prod[12];
                round_bit = prod[11];
                sticky_bit = |prod[10:0];
                final_mant = prod[22:13];
            end else begin
                final_exp = raw_exp;
                guard_bit = prod[11];
                round_bit = prod[10];
                sticky_bit = |prod[9:0];
                final_mant = prod[21:12];
            end

            // Rounding (Nearest Even)
            if (guard_bit && (round_bit || sticky_bit || final_mant[0])) begin
                final_mant = final_mant + 1;
                if (final_mant == 10'b0) begin
                    final_exp = final_exp + 1;
                end
            end

            // Overflow/Underflow
            if (final_exp >= 31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if (final_exp <= 0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, final_exp[4:0], final_mant};
            end
        end
    end

endmodule