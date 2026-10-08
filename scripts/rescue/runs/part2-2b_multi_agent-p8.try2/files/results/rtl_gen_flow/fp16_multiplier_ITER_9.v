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
    reg [10:0] m_res;
    reg [4:0]  e_res;
    reg        guard, round, sticky;
    reg        round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        ea = a[14:10];
        eb = b[14:10];
        ma = {1'b1, a[9:0]};
        mb = {1'b1, b[9:0]};
        prod = ma * mb;
        
        // Default result 0
        result = {sign, 15'b0};

        if ((ea == 5'd0) || (eb == 5'd0)) begin
            result = {sign, 15'b0};
        end else if ((ea == 5'd31) || (eb == 5'd31)) begin
            result = {sign, 5'b11111, 10'b0};
        end else begin
            exp_raw = $signed({1'b0, ea}) + $signed({1'b0, eb}) - 8'd15;
            
            if (prod[21]) begin
                m_res = prod[21:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
                e_res = exp_raw + 8'd1;
            end else begin
                m_res = prod[20:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
                e_res = exp_raw;
            end

            // Round to nearest even
            round_up = guard && (round || sticky || m_res[0]);

            if ($signed(e_res) >= 31) begin
                result = {sign, 5'b11111, 10'b0};
            end else if ($signed(e_res) <= 0) begin
                result = {sign, 15'b0};
            end else begin
                {e_res, m_res} = {e_res, m_res} + round_up;
                if (m_res[10]) begin
                    m_res = m_res >> 1;
                    e_res = e_res + 1'b1;
                end
                if ($signed(e_res) >= 31) begin
                    result = {sign, 5'b11111, 10'b0};
                end else if ($signed(e_res) <= 0) begin
                    result = {sign, 15'b0};
                end else begin
                    result = {sign, e_res[4:0], m_res[9:0]};
                end
            end
        end
    end
endmodule