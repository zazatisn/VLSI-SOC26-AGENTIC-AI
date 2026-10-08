`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg sign;
    reg [4:0] ea, eb;
    reg [10:0] ma, mb;
    reg [21:0] prod;
    reg signed [7:0] exp_raw;
    reg [4:0] exp_final;
    reg [10:0] mant_shifted;
    reg [9:0] mant_final;
    reg g, r, s;
    reg round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        ea = a[14:10];
        eb = b[14:10];
        ma = {1'b1, a[9:0]};
        mb = {1'b1, b[9:0]};
        prod = ma * mb;

        // Default
        result = 16'd0;

        if (ea == 5'd0 || eb == 5'd0) begin
            result = {sign, 15'd0};
        end else if (ea == 5'd31 || eb == 5'd31) begin
            result = {sign, 5'b11111, 10'd0};
        end else begin
            exp_raw = $signed({1'b0, ea}) + $signed({1'b0, eb}) - 8'd15;
            
            if (prod[21]) begin
                exp_final = exp_raw[4:0];
                mant_shifted = prod[21:11];
                g = prod[10];
                r = prod[9];
                s = |prod[8:0];
            end else begin
                exp_final = exp_raw[4:0] - 5'd1;
                mant_shifted = prod[20:10];
                g = prod[9];
                r = prod[8];
                s = |prod[7:0];
            end

            round_up = g && (r || s || mant_shifted[0]);
            mant_final = mant_shifted[9:0] + round_up;
            
            if (mant_shifted[10] && round_up) begin
                exp_final = exp_final + 5'd1;
                mant_final = 10'd0;
            end

            if ($signed(exp_final) >= 31) begin
                result = {sign, 5'b11111, 10'd0};
            end else if ($signed(exp_final) <= 0) begin
                result = {sign, 15'd0};
            end else begin
                result = {sign, exp_final, mant_final};
            end
        end
    end
endmodule