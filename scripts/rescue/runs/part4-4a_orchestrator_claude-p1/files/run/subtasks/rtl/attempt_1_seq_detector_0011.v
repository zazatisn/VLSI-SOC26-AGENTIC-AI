`timescale 1ns/1ps

module seq_detector_0011(
    input clk,
    input reset,
    input data_in,
    output reg detected
);

  localparam [2:0] S0 = 3'd0,
                   S1 = 3'd1,
                   S2 = 3'd2,
                   S3 = 3'd3,
                   S4 = 3'd4;

  reg [2:0] state, next_state;

  // Sequential block: state update on posedge clk
  always @(posedge clk) begin
    if (reset)
      state <= S0;
    else
      state <= next_state;
  end

  // Combinational block: next_state and detected logic
  always @(*) begin
    next_state = state;
    detected = 1'b0;

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
        detected = 1'b1;
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

endmodule