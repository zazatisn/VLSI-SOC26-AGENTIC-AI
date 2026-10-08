// Golden reference: dot_product (p5). Stage 1: N products, stage 2: sum. Latency 2.
module dot_product #(
    parameter N = 8,
    parameter WIDTH = 8
) (
    input                           clk,
    input                           rst,
    input      signed [N*WIDTH-1:0] A,
    input      signed [N*WIDTH-1:0] B,
    output reg signed [2*WIDTH+3:0] dot_out
);
    reg signed [2*WIDTH-1:0] prod [0:N-1];
    reg signed [2*WIDTH+3:0] sum;
    integer i;

    always @(posedge clk) begin
        for (i = 0; i < N; i = i + 1) begin
            if (rst) prod[i] <= 0;
            else     prod[i] <= $signed(A[i*WIDTH +: WIDTH]) * $signed(B[i*WIDTH +: WIDTH]);
        end
    end

    always @(*) begin
        sum = 0;
        for (i = 0; i < N; i = i + 1)
            sum = sum + prod[i];
    end

    always @(posedge clk) begin
        if (rst) dot_out <= 0;
        else     dot_out <= sum;
    end
endmodule
