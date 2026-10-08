// Golden reference: simple_8bit_counter (p11).
module simple_8bit_counter(
    input clk,
    input reset,
    input en,
    output reg [7:0] count
);
    always @(posedge clk) begin
        if (reset)   count <= 8'd0;
        else if (en) count <= count + 8'd1;
    end
endmodule
