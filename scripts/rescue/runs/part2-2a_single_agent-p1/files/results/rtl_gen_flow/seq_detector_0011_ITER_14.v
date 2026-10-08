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
                     S001  = 3'd3,
                     MATCH = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = IDLE;
        detected = 1'b0;
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
                next_state = (data_in) ? MATCH : S0;
            end
            MATCH: begin
                detected = 1'b1;
                next_state = (data_in) ? IDLE : S0;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule