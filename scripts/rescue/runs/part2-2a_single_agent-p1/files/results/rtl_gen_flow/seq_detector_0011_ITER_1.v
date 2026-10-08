`timescale 1ns/1ps

module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);
    localparam IDLE = 3'd0, S0 = 3'd1, S00 = 3'd2, S001 = 3'd3, SUCCESS = 3'd4;
    reg [2:0] state, next_state;

    always @(posedge clk) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        detected = 0;
        case (state)
            IDLE: next_state = (data_in == 0) ? S0 : IDLE;
            S0:   next_state = (data_in == 0) ? S00 : IDLE;
            S00:  next_state = (data_in == 0) ? S00 : S001;
            S001: next_state = (data_in == 0) ? S0 : SUCCESS;
            SUCCESS: begin
                detected = 1;
                next_state = (data_in == 0) ? S0 : IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule