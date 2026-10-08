`timescale 1ns/1ps

module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);

    localparam [2:0] IDLE  = 3'b000;
    localparam [2:0] S0    = 3'b001;
    localparam [2:0] S00   = 3'b010;
    localparam [2:0] S001  = 3'b011;
    localparam [2:0] S0011 = 3'b100;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            detected <= 1'b0;
        end else begin
            state <= next_state;
            if (next_state == S0011) begin
                detected <= 1'b1;
            end else begin
                detected <= 1'b0;
            end
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (data_in == 1'b0) begin
                    next_state = S0;
                end else begin
                    next_state = IDLE;
                end
            end
            S0: begin
                if (data_in == 1'b0) begin
                    next_state = S00;
                end else begin
                    next_state = IDLE;
                end
            end
            S00: begin
                if (data_in == 1'b0) begin
                    next_state = S00;
                end else begin
                    next_state = S001;
                end
            end
            S001: begin
                if (data_in == 1'b0) begin
                    next_state = S0;
                end else begin
                    next_state = S0011;
                end
            end
            S0011: begin
                if (data_in == 1'b0) begin
                    next_state = S0;
                end else begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule