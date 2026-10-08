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
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        detected = 0;
        case (state)
            IDLE: begin
                next_state = (data_in) ? IDLE : S0;
            end
            S0: begin
                next_state = (data_in) ? IDLE : S00;
            end
            S00: begin
                next_state = (data_in) ? S001 : S00;
            end
            S001: begin
                next_state = (data_in) ? S0011 : S0;
                if (next_state == S0011) detected = 1;
            end
            S0011: begin
                next_state = (data_in) ? S001 : S0;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule