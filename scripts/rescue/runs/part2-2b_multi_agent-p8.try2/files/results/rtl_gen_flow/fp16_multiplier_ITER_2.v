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
    reg [4:0] exp_sum;
    reg [10:0] norm_man;
    reg [4:0] norm_exp;
    reg guard, round, sticky;
    reg round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        exp_a = a[14:10];
        exp_b = b[14:10];
        man_a = {1'b1, a[9:0]};
        man_b = {1'b1, b[9:0]};
        prod = man_a * man_b;
        
        if (exp_a == 5'd0 || exp_b == 5'd0) begin
            result = {sign, 15'b0};
        end else begin
            exp_sum = exp_a + exp_b - 5'd15;
            
            if (prod[21]) begin
                norm_man = prod[21:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
                norm_exp = exp_sum + 5'd1;
            end else begin
                norm_man = prod[20:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
                norm_exp = exp_sum;
            end
            
            round_up = guard && (round || sticky || norm_man[0]);
            
            if (norm_exp >= 5'd31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if (norm_exp < 5'd1) begin
                result = {sign, 15'b0};
            end else begin
                if (round_up) begin
                    if (norm_man == 11'h7FF) begin
                        result = {sign, norm_exp + 5'd1, 10'b0};
                    end else begin
                        result = {sign, norm_exp, (norm_man[9:0] + 1'b1)};
                    end
                end else begin
                    result = {sign, norm_exp, norm_man[9:0]};
                end
            end
        end
    end
endmodule