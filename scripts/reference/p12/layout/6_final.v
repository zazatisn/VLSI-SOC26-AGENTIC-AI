module registered_adder_8bit (clk,
    reset,
    a,
    b,
    sum);
 input clk;
 input reset;
 input [7:0] a;
 input [7:0] b;
 output [7:0] sum;

 wire _00_;
 wire _01_;
 wire _02_;
 wire _03_;
 wire _04_;
 wire _05_;
 wire _06_;
 wire _07_;
 wire _08_;
 wire _09_;
 wire _10_;
 wire _11_;
 wire _12_;
 wire _13_;
 wire _14_;
 wire _15_;
 wire _16_;
 wire _17_;
 wire _18_;
 wire _19_;
 wire _20_;
 wire _21_;
 wire _22_;
 wire _23_;
 wire _24_;
 wire _25_;
 wire _26_;
 wire _27_;
 wire _28_;
 wire _29_;
 wire _30_;
 wire _31_;
 wire _32_;
 wire _33_;
 wire _35_;
 wire _36_;
 wire _37_;
 wire _38_;
 wire _39_;
 wire _40_;
 wire _41_;
 wire _42_;
 wire _43_;
 wire _44_;
 wire _45_;
 wire _46_;
 wire _47_;
 wire _48_;
 wire _49_;
 wire _50_;
 wire _51_;
 wire _52_;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net8;
 wire net9;
 wire net10;
 wire net11;
 wire net12;
 wire net13;
 wire net14;
 wire net15;
 wire net16;
 wire net17;
 wire net18;
 wire net19;
 wire net20;
 wire net21;
 wire net22;
 wire net23;
 wire net24;
 wire net25;
 wire net38;
 wire net39;
 wire net40;
 wire net41;
 wire net42;
 wire net43;
 wire net44;
 wire net45;
 wire net46;
 wire net48;
 wire net49;
 wire net37;
 wire net47;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 sky130_fd_sc_hd__a211oi_2 _53_ (.A1(_07_),
    .A2(net44),
    .B1(_11_),
    .C1(_14_),
    .Y(_24_));
 sky130_fd_sc_hd__o21ai_0 _54_ (.A1(_14_),
    .A2(_15_),
    .B1(_10_),
    .Y(_25_));
 sky130_fd_sc_hd__a21oi_1 _56_ (.A1(_32_),
    .A2(_33_),
    .B1(net48),
    .Y(_23_));
 sky130_fd_sc_hd__nor2b_1 _57_ (.A(net48),
    .B_N(_08_),
    .Y(_22_));
 sky130_fd_sc_hd__nor2b_1 _58_ (.A(net48),
    .B_N(_02_),
    .Y(_21_));
 sky130_fd_sc_hd__xnor2_1 _59_ (.A(net39),
    .B(_01_),
    .Y(_35_));
 sky130_fd_sc_hd__nor2_1 _60_ (.A(net48),
    .B(_35_),
    .Y(_20_));
 sky130_fd_sc_hd__nor2_1 _61_ (.A(net38),
    .B(net37),
    .Y(_36_));
 sky130_fd_sc_hd__a21o_1 _62_ (.A1(net44),
    .A2(_07_),
    .B1(_11_),
    .X(_37_));
 sky130_fd_sc_hd__a211oi_1 _63_ (.A1(net39),
    .A2(_37_),
    .B1(net42),
    .C1(net40),
    .Y(_38_));
 sky130_fd_sc_hd__nor3_1 _64_ (.A(net48),
    .B(_36_),
    .C(_38_),
    .Y(_19_));
 sky130_fd_sc_hd__nand3_1 _65_ (.A(_06_),
    .B(net41),
    .C(net47),
    .Y(_26_));
 sky130_fd_sc_hd__a21o_1 _66_ (.A1(net39),
    .A2(_01_),
    .B1(net40),
    .X(_39_));
 sky130_fd_sc_hd__a21oi_2 _67_ (.A1(_39_),
    .A2(net42),
    .B1(net43),
    .Y(_40_));
 sky130_fd_sc_hd__xor2_1 _68_ (.A(net41),
    .B(_40_),
    .X(_41_));
 sky130_fd_sc_hd__nor2_1 _69_ (.A(net48),
    .B(_41_),
    .Y(_18_));
 sky130_fd_sc_hd__o21bai_1 _70_ (.A1(net38),
    .A2(net37),
    .B1_N(net43),
    .Y(_42_));
 sky130_fd_sc_hd__nand2b_1 _71_ (.A_N(_12_),
    .B(net45),
    .Y(_43_));
 sky130_fd_sc_hd__or3b_2 _72_ (.A(_06_),
    .B(net17),
    .C_N(_12_),
    .X(_44_));
 sky130_fd_sc_hd__o31a_2 _73_ (.A1(net48),
    .A2(net41),
    .A3(_43_),
    .B1(_44_),
    .X(_45_));
 sky130_fd_sc_hd__nor2_1 _74_ (.A(net45),
    .B(net48),
    .Y(_46_));
 sky130_fd_sc_hd__nand3_1 _75_ (.A(net41),
    .B(_42_),
    .C(_46_),
    .Y(_47_));
 sky130_fd_sc_hd__nor3_1 _76_ (.A(_24_),
    .B(_25_),
    .C(_26_),
    .Y(_27_));
 sky130_fd_sc_hd__o311ai_0 _77_ (.A1(net48),
    .A2(_42_),
    .A3(_43_),
    .B1(_45_),
    .C1(_47_),
    .Y(_17_));
 sky130_fd_sc_hd__a21oi_1 _78_ (.A1(_06_),
    .A2(_28_),
    .B1(net46),
    .Y(_48_));
 sky130_fd_sc_hd__nand4_1 _79_ (.A(net45),
    .B(net42),
    .C(net41),
    .D(_39_),
    .Y(_49_));
 sky130_fd_sc_hd__inv_1 _80_ (.A(net47),
    .Y(_50_));
 sky130_fd_sc_hd__a21oi_1 _81_ (.A1(_48_),
    .A2(_49_),
    .B1(_50_),
    .Y(_51_));
 sky130_fd_sc_hd__nand3_1 _82_ (.A(_50_),
    .B(_48_),
    .C(_49_),
    .Y(_52_));
 sky130_fd_sc_hd__nor3b_1 _83_ (.A(net48),
    .B(_51_),
    .C_N(_52_),
    .Y(_16_));
 sky130_fd_sc_hd__a21o_1 _84_ (.A1(_13_),
    .A2(_09_),
    .B1(_12_),
    .X(_28_));
 sky130_fd_sc_hd__a21o_1 _85_ (.A1(_04_),
    .A2(_05_),
    .B1(_03_),
    .X(_29_));
 sky130_fd_sc_hd__a31o_1 _86_ (.A1(_06_),
    .A2(_04_),
    .A3(_28_),
    .B1(_29_),
    .X(_30_));
 sky130_fd_sc_hd__xnor2_1 _87_ (.A(net8),
    .B(net16),
    .Y(_31_));
 sky130_fd_sc_hd__or3_1 _88_ (.A(_27_),
    .B(_30_),
    .C(_31_),
    .X(_32_));
 sky130_fd_sc_hd__o21ai_0 _89_ (.A1(_27_),
    .A2(_30_),
    .B1(_31_),
    .Y(_33_));
 sky130_fd_sc_hd__fa_2 _90_ (.A(net2),
    .B(net49),
    .CIN(_00_),
    .COUT(_01_),
    .SUM(_02_));
 sky130_fd_sc_hd__ha_1 _91_ (.A(net7),
    .B(net15),
    .COUT(_03_),
    .SUM(_04_));
 sky130_fd_sc_hd__ha_1 _92_ (.A(net6),
    .B(net14),
    .COUT(_05_),
    .SUM(_06_));
 sky130_fd_sc_hd__ha_1 _93_ (.A(net1),
    .B(net9),
    .COUT(_00_),
    .SUM(_08_));
 sky130_fd_sc_hd__ha_1 _94_ (.A(net4),
    .B(net12),
    .COUT(_09_),
    .SUM(_10_));
 sky130_fd_sc_hd__ha_1 _95_ (.A(net10),
    .B(net2),
    .COUT(_11_),
    .SUM(_07_));
 sky130_fd_sc_hd__ha_1 _96_ (.A(net5),
    .B(net13),
    .COUT(_12_),
    .SUM(_13_));
 sky130_fd_sc_hd__ha_1 _97_ (.A(net3),
    .B(net11),
    .COUT(_14_),
    .SUM(_15_));
 sky130_fd_sc_hd__clkbuf_4 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_4 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .X(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__clkbuf_4 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .X(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input1 (.A(a[0]),
    .X(net1));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input10 (.A(b[1]),
    .X(net10));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input11 (.A(b[2]),
    .X(net11));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input12 (.A(b[3]),
    .X(net12));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input13 (.A(b[4]),
    .X(net13));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input14 (.A(b[5]),
    .X(net14));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input15 (.A(b[6]),
    .X(net15));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input16 (.A(b[7]),
    .X(net16));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input17 (.A(reset),
    .X(net17));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input2 (.A(a[1]),
    .X(net2));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input3 (.A(a[2]),
    .X(net3));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input4 (.A(a[3]),
    .X(net4));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input5 (.A(a[4]),
    .X(net5));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input6 (.A(a[5]),
    .X(net6));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input7 (.A(a[6]),
    .X(net7));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input8 (.A(a[7]),
    .X(net8));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input9 (.A(b[0]),
    .X(net9));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output18 (.A(net18),
    .X(sum[0]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output19 (.A(net19),
    .X(sum[1]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output20 (.A(net20),
    .X(sum[2]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output21 (.A(net21),
    .X(sum[3]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output22 (.A(net22),
    .X(sum[4]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output23 (.A(net23),
    .X(sum[5]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output24 (.A(net24),
    .X(sum[6]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output25 (.A(net25),
    .X(sum[7]));
 sky130_fd_sc_hd__buf_4 place37 (.A(_25_),
    .X(net37));
 sky130_fd_sc_hd__buf_4 place38 (.A(_24_),
    .X(net38));
 sky130_fd_sc_hd__buf_4 place39 (.A(_15_),
    .X(net39));
 sky130_fd_sc_hd__buf_4 place40 (.A(_14_),
    .X(net40));
 sky130_fd_sc_hd__buf_4 place41 (.A(_13_),
    .X(net41));
 sky130_fd_sc_hd__buf_4 place42 (.A(_10_),
    .X(net42));
 sky130_fd_sc_hd__buf_4 place43 (.A(_09_),
    .X(net43));
 sky130_fd_sc_hd__buf_4 place44 (.A(_00_),
    .X(net44));
 sky130_fd_sc_hd__buf_4 place45 (.A(_06_),
    .X(net45));
 sky130_fd_sc_hd__buf_4 place46 (.A(_05_),
    .X(net46));
 sky130_fd_sc_hd__buf_4 place47 (.A(_04_),
    .X(net47));
 sky130_fd_sc_hd__buf_4 place48 (.A(net17),
    .X(net48));
 sky130_fd_sc_hd__buf_4 place49 (.A(net10),
    .X(net49));
 sky130_fd_sc_hd__dfxtp_1 \sum[0]$_SDFF_PP0_  (.D(_22_),
    .Q(net18),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \sum[1]$_SDFF_PP0_  (.D(_21_),
    .Q(net19),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \sum[2]$_SDFF_PP0_  (.D(_20_),
    .Q(net20),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \sum[3]$_SDFF_PP0_  (.D(_19_),
    .Q(net21),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \sum[4]$_SDFF_PP0_  (.D(_18_),
    .Q(net22),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \sum[5]$_SDFF_PP0_  (.D(_17_),
    .Q(net23),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \sum[6]$_SDFF_PP0_  (.D(_16_),
    .Q(net24),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \sum[7]$_SDFF_PP0_  (.D(_23_),
    .Q(net25),
    .CLK(clknet_1_1__leaf_clk));
endmodule
