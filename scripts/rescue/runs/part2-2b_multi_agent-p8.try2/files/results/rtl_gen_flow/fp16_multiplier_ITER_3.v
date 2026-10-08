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
    reg [5:0] exp_sum_wide;
    reg [4:0] norm_exp;
    reg [10:0] norm_man;
    reg guard, round_bit, sticky;
    reg round_up;
    reg [10:0] rounded_man;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        man_a = {1'b1, a[9:0]};
        man_b = {1'b1, b[9:0]};
        prod = man_a * man_b;
        
        // Zero detection
        if ((exp_a == 5'd0) || (exp_b == 5'd0)) begin
            result = {sign, 15'b0};
        end else begin
            exp_sum_wide = exp_a + exp_b - 5'd15;
            
            if (prod[21]) begin
                norm_man = prod[21:11];
                guard = prod[10];
                round_bit = prod[9];
                sticky = |prod[8:0];
                norm_exp = exp_sum_wide + 1'b1;
            end else begin
                norm_man = prod[20:10];
                guard = prod[9];
                round_bit = prod[8];
                sticky = |prod[7:0];
                norm_exp = exp_sum_wide;
            end
            
            round_up = guard && (round_bit || sticky || norm_man[0]);
            rounded_man = norm_man + (round_up ? 1'b1 : 1'b0);
            
            if (rounded_man[10]) begin
                norm_man = {1'b1, 10'b0};
                norm_exp = norm_exp + 1'b1;
            end else begin
                norm_man = rounded_man;
            end
            
            if (norm_exp >= 5'd31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if ($signed(norm_exp) <= 0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, norm_exp, norm_man[9:0]};
            end
        end
    end
endmodule