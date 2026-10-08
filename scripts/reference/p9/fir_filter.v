// Golden reference: fir_filter (p9). Transposed form, one multiply + one add per stage, latency 1.
module fir_filter #(
    parameter WIDTH = 16,
    parameter N = 8
) (
    input                        clk,
    input                        rst,
    input  signed [WIDTH-1:0]    x_in,
    input  signed [N*WIDTH-1:0]  h,
    output reg signed [2*WIDTH + $clog2(N) - 1 : 0] y_out
);
    localparam OW = 2*WIDTH + $clog2(N);
    reg signed [OW-1:0] z [1:N-1];
    integer j;

    always @(posedge clk) begin
        if (rst) begin
            for (j = 1; j < N; j = j + 1) z[j] <= 0;
            y_out <= 0;
        end else begin
            z[N-1] <= $signed(h[(N-1)*WIDTH +: WIDTH]) * x_in;
            for (j = 1; j < N-1; j = j + 1)
                z[j] <= z[j+1] + $signed(h[j*WIDTH +: WIDTH]) * x_in;
            y_out <= z[1] + $signed(h[0 +: WIDTH]) * x_in;
        end
    end
endmodule
