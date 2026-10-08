// Golden reference: sync_fifo (p16). DEPTH x WIDTH synchronous FIFO, registered read data.
module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
) (
    input                  clk,
    input                  reset,
    input                  wr_en,
    input                  rd_en,
    input      [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout,
    output                 full,
    output                 empty
);
    localparam AW = $clog2(DEPTH);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0] wr_ptr, rd_ptr;             // one extra bit tells full from empty

    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);

    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    always @(posedge clk) begin
        if (do_wr) mem[wr_ptr[AW-1:0]] <= din;
    end

    always @(posedge clk) begin
        if (reset) begin
            wr_ptr <= 0; rd_ptr <= 0; dout <= 0;
        end else begin
            if (do_wr) wr_ptr <= wr_ptr + 1'b1;
            if (do_rd) begin
                rd_ptr <= rd_ptr + 1'b1;
                dout   <= mem[rd_ptr[AW-1:0]];
            end
        end
    end
endmodule
