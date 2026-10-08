// Golden reference: fp16_multiplier (p8). Combinational, round to nearest even, no subnormals.
module fp16_multiplier(
    input      [15:0] a,
    input      [15:0] b,
    output reg [15:0] result
);
    reg        sign, guard, sticky;
    reg [21:0] prod;
    reg [10:0] mant;          // one extra bit to catch the rounding carry
    reg signed [7:0] exp;

    always @(*) begin
        sign   = a[15] ^ b[15];
        prod   = {1'b1, a[9:0]} * {1'b1, b[9:0]};
        result = {sign, 15'b0};
        mant = 0; guard = 0; sticky = 0; exp = 0;
        if (a[14:10] != 0 && b[14:10] != 0) begin
            exp = $signed({3'b0, a[14:10]}) + $signed({3'b0, b[14:10]}) - 8'sd15;
            if (prod[21]) begin
                mant = {1'b0, prod[20:11]}; guard = prod[10]; sticky = |prod[9:0]; exp = exp + 8'sd1;
            end else begin
                mant = {1'b0, prod[19:10]}; guard = prod[9];  sticky = |prod[8:0];
            end
            if (guard && (sticky || mant[0])) mant = mant + 11'd1;
            if (mant[10]) begin mant = 11'd0; exp = exp + 8'sd1; end
            if (exp >= 8'sd31)     result = {sign, 5'b11111, 10'b0};
            else if (exp < 8'sd1)  result = {sign, 15'b0};
            else                   result = {sign, exp[4:0], mant[9:0]};
        end
    end
endmodule
