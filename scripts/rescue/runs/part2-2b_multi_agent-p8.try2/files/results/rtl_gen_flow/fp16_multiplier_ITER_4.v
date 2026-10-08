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
    reg [5:0] exp_sum;
    reg [10:0] m;
    reg [4:0] e;
    reg guard, round_bit, sticky;
    reg round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        man_a = {1'b1, a[9:0]};
        man_b = {1'b1, b[9:0]};
        prod = man_a * man_b;

        if ((exp_a == 5'd0) || (exp_b == 5'd0)) begin
            result = {sign, 15'd0};
        end else if ((exp_a == 5'd31) || (exp_b == 5'd31)) begin
            result = {sign, 5'b11111, 10'd0};
        end else begin
            exp_sum = exp_a + exp_b - 5'd15;
            
            if (prod[21]) begin
                m = prod[21:11];
                guard = prod[10];
                round_bit = prod[9];
                sticky = |prod[8:0];
                e = exp_sum + 1'b1;
            end else begin
                m = prod[20:10];
                guard = prod[9];
                round_bit = prod[8];
                sticky = |prod[7:0];
                e = exp_sum;
            end

            round_up = guard && (round_bit || sticky || m[0]);
            if (round_up) begin
                m = m + 1'b1;
                if (m[10]) begin
                    m = 11'b10000000000;
                    e = e + 1'b1;
                end
            end

            if (e >= 5'd31) begin
                result = {sign, 5'b11111, 10'd0};
            end else if ($signed(e) <= 0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, e, m[9:0]};
            end
        end
    end
endmodule