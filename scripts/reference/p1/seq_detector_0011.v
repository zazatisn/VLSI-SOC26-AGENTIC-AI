// Golden reference: seq_detector_0011 (p1). Moore FSM, overlapping detection.
module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);
    localparam S0 = 3'd0,  // nothing useful seen
               S1 = 3'd1,  // "0"
               S2 = 3'd2,  // "00"
               S3 = 3'd3,  // "001"
               S4 = 3'd4;  // "0011" -> detected
    reg [2:0] state, next_state;

    always @(posedge clk) begin
        if (reset) state <= S0;
        else       state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S0: next_state = data_in ? S0 : S1;
            S1: next_state = data_in ? S0 : S2;
            S2: next_state = data_in ? S3 : S2;
            S3: next_state = data_in ? S4 : S1;
            S4: next_state = data_in ? S0 : S1;
            default: next_state = S0;
        endcase
    end

    always @(*) begin
        detected = (state == S4);
    end
endmodule
