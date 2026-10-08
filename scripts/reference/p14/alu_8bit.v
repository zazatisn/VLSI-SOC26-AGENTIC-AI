// Golden reference: alu_8bit (p14). 8 operations, registered result + zero + carry flags, latency 1.
module alu_8bit(
    input            clk,
    input            reset,
    input      [7:0] a,
    input      [7:0] b,
    input      [2:0] op,
    output reg [7:0] result,
    output reg       zero,
    output reg       carry
);
    reg [7:0] r;
    reg       c;
    reg [8:0] t;

    always @(*) begin
        r = 8'd0; c = 1'b0; t = 9'd0;
        case (op)
            3'b000: begin t = {1'b0, a} + {1'b0, b}; r = t[7:0]; c = t[8];  end   // ADD
            3'b001: begin t = {1'b0, a} - {1'b0, b}; r = t[7:0]; c = t[8];  end   // SUB, carry = borrow
            3'b010: r = a & b;                                                  // AND
            3'b011: r = a | b;                                                  // OR
            3'b100: r = a ^ b;                                                  // XOR
            3'b101: begin r = {a[6:0], 1'b0}; c = a[7]; end                     // SHL
            3'b110: begin r = {1'b0, a[7:1]}; c = a[0]; end                     // SHR
            default: r = (a < b) ? 8'd1 : 8'd0;                                 // SLT (unsigned)
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            result <= 8'd0; zero <= 1'b0; carry <= 1'b0;
        end else begin
            result <= r; zero <= (r == 8'd0); carry <= c;
        end
    end
endmodule
