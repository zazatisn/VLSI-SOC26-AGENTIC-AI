// Reference testbench for vga_lcd (p17), default parameters (16 x 8 active pixels).
// A behavioural model in the testbench predicts every output after every rising edge.
// Drives on falling edges, checks on the next falling edge. Tests: palette and framebuffer
// programming with the timing stopped, 3 full frames, writes while the picture is displayed
// (same-cycle read/write), enable pauses, reset in the middle of a frame, random traffic.
`timescale 1ns/1ps

module tb_vga_lcd;
    localparam HA = 16, HFP = 2, HS = 3, HBP = 3, VA = 8, VFP = 1, VS = 2, VBP = 2;
    localparam HT = HA + HFP + HS + HBP, VT = VA + VFP + VS + VBP;

    reg clk, reset, enable, fb_we, pal_we;
    reg [6:0]  fb_addr;
    reg [3:0]  fb_wdata, pal_addr;
    reg [11:0] pal_wdata;
    wire hsync_n, vsync_n, de, frame_start;
    wire [11:0] rgb;

    vga_lcd dut(.clk(clk), .reset(reset), .enable(enable), .fb_we(fb_we), .fb_addr(fb_addr),
                .fb_wdata(fb_wdata), .pal_we(pal_we), .pal_addr(pal_addr), .pal_wdata(pal_wdata),
                .hsync_n(hsync_n), .vsync_n(vsync_n), .de(de), .rgb(rgb), .frame_start(frame_start));

    // model
    reg [3:0]  m_fb  [0:127];
    reg [11:0] m_pal [0:15];
    integer h, v, i, k, errors, checks;
    reg p_valid;                       // a position was sampled at the previous edge
    integer p_h, p_v;
    reg [3:0] p_idx;
    reg e_hs_n, e_vs_n, e_de, e_fs;
    reg [11:0] e_rgb;

    initial clk = 0;
    always #5 clk = ~clk;

    task step;
        input r, en, fw;
        input [6:0] fa;
        input [3:0] fd;
        input pw;
        input [3:0] pa;
        input [11:0] pd;
        begin
            reset = r; enable = en; fb_we = fw; fb_addr = fa; fb_wdata = fd;
            pal_we = pw; pal_addr = pa; pal_wdata = pd;
            @(negedge clk);
            // expected values after this rising edge
            if (r) begin
                for (k = 0; k < 128; k = k + 1) m_fb[k] = 0;
                for (k = 0; k < 16; k = k + 1) m_pal[k] = 0;
                h = 0; v = 0; p_valid = 0;
                e_hs_n = 1; e_vs_n = 1; e_de = 0; e_rgb = 0; e_fs = 0;
            end else begin
                if (p_valid) begin
                    e_de   = (p_h < HA) && (p_v < VA);
                    e_hs_n = !((p_h >= HA + HFP) && (p_h < HA + HFP + HS));
                    e_vs_n = !((p_v >= VA + VFP) && (p_v < VA + VFP + VS));
                    e_fs   = (p_h == 0) && (p_v == 0);
                    e_rgb  = e_de ? m_pal[p_idx] : 12'h000;      // palette BEFORE this edge's write
                end else begin
                    e_hs_n = 1; e_vs_n = 1; e_de = 0; e_rgb = 0; e_fs = 0;
                end
                if (en) begin                                  // sample the current position
                    p_valid = 1; p_h = h; p_v = v;
                    p_idx = ((h < HA) && (v < VA)) ? m_fb[v * HA + h] : 4'd0;   // framebuffer BEFORE this edge's write
                    h = h + 1;
                    if (h == HT) begin h = 0; v = (v == VT - 1) ? 0 : v + 1; end
                end else
                    p_valid = 0;
                if (fw) m_fb[fa] = fd;
                if (pw) m_pal[pa] = pd;
            end
            checks = checks + 1;
            if (hsync_n !== e_hs_n || vsync_n !== e_vs_n || de !== e_de || rgb !== e_rgb || frame_start !== e_fs) begin
                if (errors < 20)
                    $display("ERROR: cycle %0d (sampled h=%0d v=%0d valid=%0d): hsync_n=%b vsync_n=%b de=%b rgb=%h frame_start=%b, expected %b %b %b %h %b",
                             checks, p_h, p_v, p_valid, hsync_n, vsync_n, de, rgb, frame_start, e_hs_n, e_vs_n, e_de, e_rgb, e_fs);
                errors = errors + 1;
            end
        end
    endtask

    task idle_en; input en; begin step(0, en, 0, 0, 0, 0, 0, 0); end endtask

    initial begin
        errors = 0; checks = 0; p_valid = 0; h = 0; v = 0; p_h = 0; p_v = 0; p_idx = 0;
        reset = 1; enable = 0; fb_we = 0; pal_we = 0; fb_addr = 0; fb_wdata = 0; pal_addr = 0; pal_wdata = 0;
        @(negedge clk);
        step(1, 0, 0, 0, 0, 0, 0, 0);
        step(1, 1, 1, 7'd3, 4'd5, 1, 4'd5, 12'hABC);           // writes during reset are ignored
        // 1. program the palette and the framebuffer with the timing stopped
        for (i = 0; i < 16; i = i + 1) step(0, 0, 0, 0, 0, 1, i, (i * 12'h111) ^ 12'h5A3);
        for (i = 0; i < 128; i = i + 1) step(0, 0, 1, i, (i * 7 + i / 16) % 16, 0, 0, 0);
        // 2. three frames
        for (i = 0; i < 3 * HT * VT; i = i + 1) idle_en(1);
        // 3. writes while the picture is displayed (also to the pixel being read)
        for (i = 0; i < 2 * HT * VT; i = i + 1)
            step(0, 1, ($random & 3) == 0, (i % HT < HA) ? ((i / HT) % VT) * HA + (i % HT) : $random,
                 $random, ($random & 7) == 0, $random, $random);
        // 4. enable pauses
        for (i = 0; i < 400; i = i + 1) step(0, ($random & 3) != 0, ($random & 7) == 0, $random, $random, 0, 0, 0);
        // 5. reset in the middle of a frame, then start again
        for (i = 0; i < 37; i = i + 1) idle_en(1);
        step(1, 1, 0, 0, 0, 0, 0, 0);
        for (i = 0; i < 4; i = i + 1) step(0, 0, 0, 0, 0, 1, i, 12'hF00 >> (4 * i));
        step(0, 0, 1, 7'd0, 4'd1, 0, 0, 0);
        step(0, 0, 1, 7'd17, 4'd2, 0, 0, 0);
        for (i = 0; i < HT * VT + 30; i = i + 1) idle_en(1);
        // 6. random traffic
        for (i = 0; i < 1500; i = i + 1)
            step(($random % 300) == 0, ($random & 7) != 0, $random, $random, $random, $random, $random, $random);
        if (errors == 0) $display("Test PASSED! (%0d cycles checked)", checks);
        else             $display("Test FAILED: %0d errors found.", errors);
        $finish;
    end
endmodule
