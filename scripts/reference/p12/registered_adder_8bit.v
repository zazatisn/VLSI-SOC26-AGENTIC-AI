// Golden reference: registered_adder_8bit (p12).
module registered_adder_8bit(
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] sum
);
    always @(posedge clk) begin
        if (reset) sum <= 8'd0;
        else       sum <= a + b;
    end
endmodule
