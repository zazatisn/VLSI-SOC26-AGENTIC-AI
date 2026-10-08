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
    reg [4:0]  exp_res;
    reg        guard, round, sticky;
    reg        round_up;
    reg signed [7:0] exp_sum;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};

        if (exp_a == 5'd0 || exp_b == 5'd0) begin
            result = {sign, 15'b0};
        end else begin
            prod = sig_a * sig_b;
            exp_sum = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 8'd15;

            if (prod[21]) begin
                mantissa = prod[21:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
                exp_sum = exp_sum + 8'd1;
            end else begin
                mantissa = prod[20:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
            end

            round_up = guard && (round || sticky || mantissa[0]);

            if (round_up) begin
                mantissa = mantissa + 1'b1;
                if (mantissa == 11'b10000000000) begin
                    mantissa = 11'b01000000000;
                    exp_sum = exp_sum + 8'd1;
                end
            end

            if (exp_sum >= 8'd31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if (exp_sum <= 8'd0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, exp_sum[4:0], mantissa[9:0]};
            end
        end
    end
endmodule