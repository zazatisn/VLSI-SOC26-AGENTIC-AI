module simple_8bit_counter (clk,
    en,
    reset,
    count);
 input clk;
 input en;
 input reset;
 output [7:0] count;

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
 wire _11_;
 wire _12_;
 wire _13_;
 wire _14_;
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
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net8;
 wire net9;
 wire net10;
 wire net1;
 wire net2;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 sky130_fd_sc_hd__nand4_4 _31_ (.A(net5),
    .B(net4),
    .C(net3),
    .D(net1),
    .Y(_11_));
 sky130_fd_sc_hd__nor2_1 _32_ (.A(net2),
    .B(_17_),
    .Y(_07_));
 sky130_fd_sc_hd__nand2_1 _33_ (.A(_00_),
    .B(net1),
    .Y(_18_));
 sky130_fd_sc_hd__xor2_1 _34_ (.A(net5),
    .B(_18_),
    .X(_19_));
 sky130_fd_sc_hd__nor2_1 _35_ (.A(net2),
    .B(_19_),
    .Y(_06_));
 sky130_fd_sc_hd__xor2_1 _36_ (.A(net6),
    .B(_11_),
    .X(_20_));
 sky130_fd_sc_hd__nor2_1 _37_ (.A(net2),
    .B(_20_),
    .Y(_05_));
 sky130_fd_sc_hd__nand4_2 _38_ (.A(net5),
    .B(_00_),
    .C(net6),
    .D(net1),
    .Y(_21_));
 sky130_fd_sc_hd__xor2_1 _39_ (.A(net7),
    .B(_21_),
    .X(_22_));
 sky130_fd_sc_hd__nor2_1 _40_ (.A(net2),
    .B(_22_),
    .Y(_04_));
 sky130_fd_sc_hd__nand2_1 _41_ (.A(net5),
    .B(net1),
    .Y(_23_));
 sky130_fd_sc_hd__nand4_1 _42_ (.A(net9),
    .B(net8),
    .C(net7),
    .D(net6),
    .Y(_12_));
 sky130_fd_sc_hd__nand4_1 _43_ (.A(net4),
    .B(net3),
    .C(net7),
    .D(net6),
    .Y(_24_));
 sky130_fd_sc_hd__o21ai_0 _44_ (.A1(_23_),
    .A2(_24_),
    .B1(net8),
    .Y(_25_));
 sky130_fd_sc_hd__or3_1 _45_ (.A(net8),
    .B(_23_),
    .C(_24_),
    .X(_26_));
 sky130_fd_sc_hd__a21oi_1 _46_ (.A1(_25_),
    .A2(_26_),
    .B1(net2),
    .Y(_03_));
 sky130_fd_sc_hd__nand2_1 _47_ (.A(net8),
    .B(net7),
    .Y(_27_));
 sky130_fd_sc_hd__o21ai_0 _48_ (.A1(_27_),
    .A2(_21_),
    .B1(net9),
    .Y(_28_));
 sky130_fd_sc_hd__or3_1 _49_ (.A(net9),
    .B(_27_),
    .C(_21_),
    .X(_29_));
 sky130_fd_sc_hd__a21oi_1 _50_ (.A1(_28_),
    .A2(_29_),
    .B1(net2),
    .Y(_02_));
 sky130_fd_sc_hd__o21ai_0 _51_ (.A1(_11_),
    .A2(_12_),
    .B1(net10),
    .Y(_13_));
 sky130_fd_sc_hd__or3_1 _52_ (.A(net10),
    .B(_11_),
    .C(_12_),
    .X(_14_));
 sky130_fd_sc_hd__a21oi_1 _54_ (.A1(_13_),
    .A2(_14_),
    .B1(net2),
    .Y(_09_));
 sky130_fd_sc_hd__xnor2_1 _55_ (.A(net3),
    .B(net1),
    .Y(_16_));
 sky130_fd_sc_hd__nor2_1 _56_ (.A(net2),
    .B(_16_),
    .Y(_08_));
 sky130_fd_sc_hd__mux2i_1 _57_ (.A0(net4),
    .A1(_01_),
    .S(net1),
    .Y(_17_));
 sky130_fd_sc_hd__ha_1 _58_ (.A(net3),
    .B(net4),
    .COUT(_00_),
    .SUM(_01_));
 sky130_fd_sc_hd__clkbuf_4 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_4 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .X(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__clkbuf_4 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .X(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[0]$_SDFFE_PP0P_  (.D(_08_),
    .Q(net3),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[1]$_SDFFE_PP0P_  (.D(_07_),
    .Q(net4),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[2]$_SDFFE_PP0P_  (.D(_06_),
    .Q(net5),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[3]$_SDFFE_PP0P_  (.D(_05_),
    .Q(net6),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[4]$_SDFFE_PP0P_  (.D(_04_),
    .Q(net7),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[5]$_SDFFE_PP0P_  (.D(_03_),
    .Q(net8),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[6]$_SDFFE_PP0P_  (.D(_02_),
    .Q(net9),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \count[7]$_SDFFE_PP0P_  (.D(_09_),
    .Q(net10),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input1 (.A(en),
    .X(net1));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input2 (.A(reset),
    .X(net2));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output10 (.A(net10),
    .X(count[7]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output3 (.A(net3),
    .X(count[0]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output4 (.A(net4),
    .X(count[1]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output5 (.A(net5),
    .X(count[2]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output6 (.A(net6),
    .X(count[3]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output7 (.A(net7),
    .X(count[4]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output8 (.A(net8),
    .X(count[5]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output9 (.A(net9),
    .X(count[6]));
endmodule
