`timescale 1ns/1ps

module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);

    reg        sign;
    reg [4:0]  ea, eb;
    reg [10:0] ma, mb;
    reg [21:0] prod;
    reg signed [7:0] exp_raw;
    reg [10:0] mant_norm;
    reg [9:0]  mant_final;
    reg [4:0]  exp_final;
    reg        round_bit;

    always @(*) begin
        // Defaults
        sign = a[15] ^ b[15];
        ea = a[14:10];
        eb = b[14:10];
        ma = {1'b1, a[9:0]};
        mb = {1'b1, b[9:0]};
        prod = ma * mb;
        result = 16'b0;

        if (ea == 5'd0 || eb == 5'd0) begin
            result = {sign, 15'b0};
        end else if (ea == 5'd31 || eb == 5'd31) begin
            result = {sign, 5'b11111, 10'b0};
        end else begin
            exp_raw = $signed({1'b0, ea}) + $signed({1'b0, eb}) - 8'd15;
            
            if (prod[21]) begin
                mant_norm = prod[21:11];
                exp_final = exp_raw + 8'd1;
                round_bit = prod[10] && (prod[9] || (|prod[8:0]) || prod[11]);
            end else begin
                mant_norm = prod[20:10];
                exp_final = exp_raw;
                round_bit = prod[9] && (prod[8] || (|prod[7:0]) || prod[10]);
            end

            mant_final = mant_norm[9:0] + round_bit;

            // Handle overflow of mantissa into exponent
            if (mant_norm[9:0] == 10'b1111111111 && round_bit) begin
                exp_final = exp_final + 8'd1;
                mant_final = 10'b0;
            end

            if ($signed(exp_final) >= 31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if ($signed(exp_final) <= 0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, exp_final, mant_final};
            end
        end
    end
endmodule