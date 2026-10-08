// Golden reference: sliding_window_avg_8bit (p13). data_out = (data_in + 3 previous samples) >> 2.
module sliding_window_avg_8bit(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);
    reg [7:0] s0, s1, s2;                         // the 3 previous samples, s0 = most recent
    wire [9:0] total = data_in + s0 + s1 + s2;

    always @(posedge clk) begin
        if (reset) begin
            s0 <= 0; s1 <= 0; s2 <= 0; data_out <= 0;
        end else begin
            s2 <= s1; s1 <= s0; s0 <= data_in;
            data_out <= total[9:2];
        end
    end
endmodule
