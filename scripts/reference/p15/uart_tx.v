// Golden reference: uart_tx (p15). 8N1 transmitter, LSB first, CLKS_PER_BIT clock cycles per bit.
module uart_tx #(
    parameter CLKS_PER_BIT = 8
) (
    input            clk,
    input            reset,
    input            start,
    input      [7:0] data_in,
    output reg       tx,
    output reg       busy
);
    reg [9:0] frame;                       // {stop, data[7:0], start}
    reg [3:0] bit_idx;                     // 0 = start bit ... 9 = stop bit
    reg [$clog2(CLKS_PER_BIT)-1:0] cnt;    // cycles spent in the current bit

    always @(posedge clk) begin
        if (reset) begin
            tx <= 1'b1; busy <= 1'b0; frame <= 10'h3ff; bit_idx <= 4'd0; cnt <= 0;
        end else if (!busy) begin
            if (start) begin
                frame   <= {1'b1, data_in, 1'b0};
                tx      <= 1'b0;           // start bit begins at this edge
                busy    <= 1'b1;
                bit_idx <= 4'd0;
                cnt     <= 0;
            end
        end else if (cnt == CLKS_PER_BIT - 1) begin
            cnt <= 0;
            if (bit_idx == 4'd9) begin     // stop bit done: back to idle
                busy <= 1'b0;
                tx   <= 1'b1;
            end else begin
                bit_idx <= bit_idx + 4'd1;
                tx      <= frame[bit_idx + 4'd1];
            end
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule
