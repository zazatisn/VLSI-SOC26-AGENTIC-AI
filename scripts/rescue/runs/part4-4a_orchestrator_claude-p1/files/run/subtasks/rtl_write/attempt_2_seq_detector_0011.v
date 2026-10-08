`timescale 1ns/1ps

module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);

    localparam S0 = 3'd0;
    localparam S1 = 3'd1;
    localparam S2 = 3'd2;
    localparam S3 = 3'd3;
    localparam S4 = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;
    reg detected_next;

    // Block 1: Sequential state update
    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Block 2: Combinational next state logic
    always @(*) begin
        next_state = state;
        case (state)
            S0: begin
                if (data_in == 1'b0)
                    next_state = S1;
                else
                    next_state = S0;
            end
            S1: begin
                if (data_in == 1'b0)
                    next_state = S2;
                else
                    next_state = S0;
            end
            S2: begin
                if (data_in == 1'b0)
                    next_state = S2;
                else
                    next_state = S3;
            end
            S3: begin
                if (data_in == 1'b0)
                    next_state = S1;
                else
                    next_state = S4;
            end
            S4: begin
                if (data_in == 1'b0)
                    next_state = S1;
                else
                    next_state = S0;
            end
            default: begin
                next_state = S0;
            end
        endcase
    end

    // Block 3: Combinational Moore output logic
    always @(*) begin
        detected_next = 1'b0;
        if (state == S4)
            detected_next = 1'b1;
    end

    // Block 4: Registered detected output
    always @(posedge clk) begin
        if (reset)
            detected <= 1'b0;
        else
            detected <= detected_next;
    end

endmodule