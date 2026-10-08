`timescale 1ns/1ps

module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);

    localparam S_IDLE = 3'b000;
    localparam S_0    = 3'b001;
    localparam S_00   = 3'b010;
    localparam S_001  = 3'b011;
    localparam S_0011 = 3'b100;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            detected <= 1'b0;
        end else begin
            state <= next_state;
            detected <= (next_state == S_0011);
        end
    end

    always @(*) begin
        next_state = S_IDLE;
        case (state)
            S_IDLE: begin
                if (data_in == 1'b0) begin
                    next_state = S_0;
                end else begin
                    next_state = S_IDLE;
                end
            end
            S_0: begin
                if (data_in == 1'b0) begin
                    next_state = S_00;
                end else begin
                    next_state = S_IDLE;
                end
            end
            S_00: begin
                if (data_in == 1'b0) begin
                    next_state = S_00;
                end else begin
                    next_state = S_001;
                end
            end
            S_001: begin
                if (data_in == 1'b0) begin
                    next_state = S_0;
                end else begin
                    next_state = S_0011;
                end
            end
            S_0011: begin
                if (data_in == 1'b0) begin
                    next_state = S_0;
                end else begin
                    next_state = S_IDLE;
                end
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

endmodule