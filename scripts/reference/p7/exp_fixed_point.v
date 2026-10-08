// Golden reference: exp_fixed_point (p7). exp_out = round(2^7 * (1 + x + x^2/2 + x^3/6)), x = x_in/2^7.
// Stage 1 samples x_in and x_in^2, stage 2 computes the Taylor sum. Latency 2. Max error 1 LSB.
module exp_fixed_point #(
    parameter WIDTH = 8
) (
    input                    clk,
    input                    rst,
    input                    enable,
    input        [WIDTH-1:0] x_in,
    output reg [2*WIDTH-1:0] exp_out
);
    // For WIDTH = 8:  98304 * exp = 12582912 + 98304 x + 384 x^2 + x^3, then divide by 98304 = 3 * 2^15
    reg [WIDTH-1:0]   x_r;
    reg [2*WIDTH-1:0] x2_r;
    wire [3*WIDTH-1:0] x3 = x2_r * x_r;
    wire [31:0] t = 32'd12582912 + 32'd98304 * x_r + 32'd384 * x2_r + x3 + 32'd49152;   // + half for rounding
    wire [47:0] q = t * 48'd43691;                                                      // ~ 2^32 / 98304

    always @(posedge clk) begin
        if (rst) begin
            x_r <= 0; x2_r <= 0; exp_out <= 0;
        end else if (enable) begin
            x_r     <= x_in;
            x2_r    <= x_in * x_in;
            exp_out <= q[47:32];
        end
    end
endmodule
