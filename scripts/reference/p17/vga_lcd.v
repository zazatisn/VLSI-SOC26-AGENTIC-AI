// Golden RTL of p17 (vga_lcd): scaled-down VGA/LCD controller.
// Timing generator + 4-bit framebuffer + 16 x 12-bit palette + 2 register stages.
`timescale 1ns/1ps
module vga_lcd #(
    parameter H_ACTIVE = 16,
    parameter H_FP     = 2,
    parameter H_SYNC   = 3,
    parameter H_BP     = 3,
    parameter V_ACTIVE = 8,
    parameter V_FP     = 1,
    parameter V_SYNC   = 2,
    parameter V_BP     = 2
) (
    input             clk,
    input             reset,
    input             enable,
    input             fb_we,
    input      [6:0]  fb_addr,
    input      [3:0]  fb_wdata,
    input             pal_we,
    input      [3:0]  pal_addr,
    input      [11:0] pal_wdata,
    output reg        hsync_n,
    output reg        vsync_n,
    output reg        de,
    output reg [11:0] rgb,
    output reg        frame_start
);
    localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
    localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;

    reg [4:0]  h_cnt;
    reg [3:0]  v_cnt;
    reg [3:0]  fb  [0:127];
    reg [11:0] pal [0:15];

    // stage 1: the sampled position
    reg        s1_de, s1_hs, s1_vs, s1_fs;
    reg [3:0]  s1_idx;

    wire act    = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    wire hs_now = (h_cnt >= H_ACTIVE + H_FP) && (h_cnt < H_ACTIVE + H_FP + H_SYNC);
    wire vs_now = (v_cnt >= V_ACTIVE + V_FP) && (v_cnt < V_ACTIVE + V_FP + V_SYNC);
    wire [6:0] rd_addr = {v_cnt[2:0], h_cnt[3:0]};

    integer i;
    always @(posedge clk) begin
        if (reset) begin
            h_cnt <= 0; v_cnt <= 0;
            s1_de <= 0; s1_hs <= 0; s1_vs <= 0; s1_fs <= 0; s1_idx <= 0;
            hsync_n <= 1; vsync_n <= 1; de <= 0; rgb <= 0; frame_start <= 0;
            for (i = 0; i < 128; i = i + 1) fb[i] <= 0;
            for (i = 0; i < 16; i = i + 1) pal[i] <= 0;
        end else begin
            if (fb_we)  fb[fb_addr]   <= fb_wdata;
            if (pal_we) pal[pal_addr] <= pal_wdata;
            // stage 2: outputs of the position sampled at the previous edge
            hsync_n     <= ~s1_hs;
            vsync_n     <= ~s1_vs;
            de          <= s1_de;
            rgb         <= s1_de ? pal[s1_idx] : 12'h000;
            frame_start <= s1_fs;
            // stage 1 + counters
            if (enable) begin
                s1_de  <= act;
                s1_hs  <= hs_now;
                s1_vs  <= vs_now;
                s1_fs  <= (h_cnt == 0) && (v_cnt == 0);
                s1_idx <= act ? fb[rd_addr] : 4'd0;
                if (h_cnt == H_TOTAL - 1) begin
                    h_cnt <= 0;
                    v_cnt <= (v_cnt == V_TOTAL - 1) ? 4'd0 : v_cnt + 1'b1;
                end else begin
                    h_cnt <= h_cnt + 1'b1;
                end
            end else begin
                s1_de <= 0; s1_hs <= 0; s1_vs <= 0; s1_fs <= 0; s1_idx <= 0;
            end
        end
    end
endmodule
