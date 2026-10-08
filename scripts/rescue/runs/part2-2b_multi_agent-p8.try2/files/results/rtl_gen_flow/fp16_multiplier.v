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
    reg [7:0]  exp_sum;
    reg [10:0] m_final;
    reg [4:0]  e_final;
    reg        guard, round, sticky;
    reg        round_up;

    always @(*) begin
        sign = a[15] ^ b[15];
        ea = a[14:10];
        eb = b[14:10];
        ma = {1'b1, a[9:0]};
        mb = {1'b1, b[9:0]};
        prod = ma * mb;
        
        // Default
        result = {sign, 15'b0};

        if ((ea == 5'd0) || (eb == 5'd0)) begin
            result = {sign, 15'b0};
        end else if ((ea == 5'h1F) || (eb == 5'h1F)) begin
            result = {sign, 5'h1F, 10'b0};
        end else begin
            exp_sum = ea + eb - 8'd15;
            
            if (prod[21]) begin
                e_final = exp_sum + 1'b1;
                m_final = prod[21:11];
                guard = prod[10];
                round = prod[9];
                sticky = |prod[8:0];
            end else begin
                e_final = exp_sum;
                m_final = prod[20:10];
                guard = prod[9];
                round = prod[8];
                sticky = |prod[7:0];
            end

            round_up = guard && (round || sticky || m_final[0]);

            if (round_up) begin
                {e_final, m_final} = {e_final, m_final} + 1'b1;
                if (m_final[10]) begin
                    m_final = m_final >> 1;
                    e_final = e_final + 1'b1;
                end
            end

            if (e_final >= 5'd31) begin
                result = {sign, 5'h1F, 10'b0};
            end else if (e_final[7:5] != 0 || e_final == 0) begin
                result = {sign, 15'b0};
            end else begin
                result = {sign, e_final[4:0], m_final[9:0]};
            end
        end
    end
endmodule