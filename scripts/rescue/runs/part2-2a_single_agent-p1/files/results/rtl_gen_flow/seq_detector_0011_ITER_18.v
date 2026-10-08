`timescale 1ns/1ps

module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);

    localparam [2:0] IDLE  = 3'd0,
                     S0    = 3'd1,
                     S00   = 3'd2,
                     S001  = 3'd3;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            detected <= 1'b0;
        end else begin
            state <= next_state;
            detected <= (next_state == S001 && data_in == 1'b1);
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: next_state = (data_in == 1'b0) ? S0 : IDLE;
            S0:   next_state = (data_in == 1'b0) ? S00 : IDLE;
            S00:  next_state = (data_in == 1'b0) ? S00 : S001;
            S001: next_state = (data_in == 1'b0) ? S0 : IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule