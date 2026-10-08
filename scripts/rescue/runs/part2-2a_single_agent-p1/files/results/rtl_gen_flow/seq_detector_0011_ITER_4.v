`timescale 1ns/1ps

module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);

    localparam [2:0] IDLE  = 3'b000,
                     S0    = 3'b001,
                     S00   = 3'b010,
                     S001  = 3'b011,
                     S0011 = 3'b100;

    reg [2:0] state, next_state;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            detected <= 1'b0;
        end else begin
            state <= next_state;
            detected <= (next_state == S0011);
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  next_state = (data_in) ? IDLE : S0;
            S0:    next_state = (data_in) ? IDLE : S00;
            S00:   next_state = (data_in) ? S001 : S00;
            S001:  next_state = (data_in) ? S0011 : S0;
            S0011: next_state = (data_in) ? IDLE : S0;
            default: next_state = IDLE;
        endcase
    end
endmodule