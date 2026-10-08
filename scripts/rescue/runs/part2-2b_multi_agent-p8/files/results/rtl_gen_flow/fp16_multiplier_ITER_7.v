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
    reg signed [7:0] exp_raw;
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
        result = 16'd0;

        // Zero / Infinity handling
        if ((exp_a == 5'd0) || (exp_b == 5'd0)) begin
            result = {sign, 15'd0};
        end else if ((exp_a == 5'd31) || (exp_b == 5'd31)) begin
            result = {sign, 5'd31, 10'd0};
        end else begin
            // Calculate exponent: (Ea - 15) + (Eb - 15) + 15 = Ea + Eb - 15
            exp_raw = $signed({3'd0, exp_a}) + $signed({3'd0, exp_b}) - 8'd15;
            
            if (product[21]) begin
                // Result is 1.xxxx, no shift needed
                mant_res = product[21:11];
                guard = product[10];
                round = product[9];
                sticky = (|product[8:0]);
            end else begin
                // Result is 0.1xxxx, shift left
                exp_raw = exp_raw - 8'd1;
                mant_res = product[20:10];
                guard = product[9];
                round = product[8];
                sticky = (|product[7:0]);
            end

            // Round to nearest, ties to even
            round_up = guard && (round || sticky || mant_res[0]);
            if (round_up) begin
                mant_res = mant_res + 1'b1;
                if (mant_res[10]) begin
                    exp_raw = exp_raw + 8'd1;
                    mant_res = {1'b1, 10'd0};
                end
            end

            // Overflow/Underflow check
            if (exp_raw >= 8'd31) begin
                result = {sign, 5'd31, 10'd0};
            end else if (exp_raw <= 8'd0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, exp_raw[4:0], mant_res[9:0]};
            end
        end
    end
endmodule