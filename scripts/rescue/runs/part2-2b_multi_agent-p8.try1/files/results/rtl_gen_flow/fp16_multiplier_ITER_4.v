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
    reg [5:0]  exp_sum;
    reg        guard, round, sticky;
    reg        round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        sig_a = {1'b1, a[9:0]};
        sig_b = {1'b1, b[9:0]};

        if (exp_a == 5'd0 || exp_b == 5'd0) begin
            result = {sign, 15'd0};
        end else begin
            prod = sig_a * sig_b;
            // exp_a + exp_b - 15
            exp_sum = (exp_a + exp_b) - 5'd15;

            if (prod[21]) begin
                mantissa = prod[21:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
                exp_sum = exp_sum + 6'd1;
            end else begin
                mantissa = prod[20:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
            end

            round_up = guard && (round || sticky || mantissa[0]);

            if (round_up) begin
                mantissa = mantissa + 1'b1;
                if (mantissa[10]) begin
                    mantissa = {1'b1, 10'd0};
                    exp_sum = exp_sum + 6'd1;
                end
            end

            if (exp_sum >= 6'd31) begin
                result = {sign, 5'd31, 10'd0};
            end else if (exp_sum[5] || exp_sum == 6'd0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, exp_sum[4:0], mantissa[9:0]};
            end
        end
    end
endmodule