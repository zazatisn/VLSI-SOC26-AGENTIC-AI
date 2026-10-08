module uart_tx (busy,
    clk,
    reset,
    start,
    tx,
    data_in);
 output busy;
 input clk;
 input reset;
 input start;
 output tx;
 input [7:0] data_in;

 wire _000_;
 wire _001_;
 wire _002_;
 wire _003_;
 wire _004_;
 wire _005_;
 wire _006_;
 wire _007_;
 wire _008_;
 wire _009_;
 wire _010_;
 wire _011_;
 wire _012_;
 wire _013_;
 wire _014_;
 wire _015_;
 wire _016_;
 wire _017_;
 wire _018_;
 wire _019_;
 wire _020_;
 wire _021_;
 wire _022_;
 wire _023_;
 wire _024_;
 wire _025_;
 wire _026_;
 wire _027_;
 wire _028_;
 wire _029_;
 wire _030_;
 wire _031_;
 wire _032_;
 wire _033_;
 wire _034_;
 wire _035_;
 wire _036_;
 wire _037_;
 wire _038_;
 wire _039_;
 wire _040_;
 wire _041_;
 wire _043_;
 wire _045_;
 wire _046_;
 wire _048_;
 wire _049_;
 wire _051_;
 wire _052_;
 wire _053_;
 wire _054_;
 wire _055_;
 wire _056_;
 wire _057_;
 wire _058_;
 wire _059_;
 wire _060_;
 wire _061_;
 wire _062_;
 wire _063_;
 wire _064_;
 wire _065_;
 wire _066_;
 wire _067_;
 wire _068_;
 wire _069_;
 wire _070_;
 wire _071_;
 wire _072_;
 wire _073_;
 wire _074_;
 wire _075_;
 wire _076_;
 wire _077_;
 wire \bit_idx[0] ;
 wire \bit_idx[1] ;
 wire \bit_idx[2] ;
 wire \bit_idx[3] ;
 wire net11;
 wire \cnt[0] ;
 wire \cnt[1] ;
 wire \cnt[2] ;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net8;
 wire \frame[0] ;
 wire \frame[1] ;
 wire \frame[2] ;
 wire \frame[3] ;
 wire \frame[4] ;
 wire \frame[5] ;
 wire \frame[6] ;
 wire \frame[7] ;
 wire \frame[8] ;
 wire net9;
 wire net10;
 wire net12;
 wire net15;
 wire net14;
 wire net16;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 sky130_fd_sc_hd__inv_1 _078_ (.A(\frame[8] ),
    .Y(_040_));
 sky130_fd_sc_hd__nor2b_1 _079_ (.A(net15),
    .B_N(net10),
    .Y(_041_));
 sky130_fd_sc_hd__inv_1 _080_ (.A(_048_),
    .Y(_049_));
 sky130_fd_sc_hd__nor2_1 _082_ (.A(net15),
    .B(net10),
    .Y(_051_));
 sky130_fd_sc_hd__a211oi_1 _083_ (.A1(_046_),
    .A2(_049_),
    .B1(_051_),
    .C1(net16),
    .Y(_023_));
 sky130_fd_sc_hd__nand2b_1 _084_ (.A_N(net15),
    .B(net10),
    .Y(_052_));
 sky130_fd_sc_hd__a21oi_1 _085_ (.A1(net12),
    .A2(_052_),
    .B1(_046_),
    .Y(_053_));
 sky130_fd_sc_hd__nand3_1 _086_ (.A(\bit_idx[0] ),
    .B(\bit_idx[2] ),
    .C(\bit_idx[1] ),
    .Y(_054_));
 sky130_fd_sc_hd__xnor2_1 _087_ (.A(\bit_idx[3] ),
    .B(_054_),
    .Y(_055_));
 sky130_fd_sc_hd__xor2_2 _088_ (.A(\bit_idx[2] ),
    .B(_003_),
    .X(_056_));
 sky130_fd_sc_hd__a21oi_1 _089_ (.A1(\bit_idx[0] ),
    .A2(_040_),
    .B1(_056_),
    .Y(_057_));
 sky130_fd_sc_hd__nand2_1 _091_ (.A(_046_),
    .B(_048_),
    .Y(_058_));
 sky130_fd_sc_hd__a31oi_1 _092_ (.A1(_002_),
    .A2(_055_),
    .A3(_057_),
    .B1(_058_),
    .Y(_059_));
 sky130_fd_sc_hd__mux4_1 _093_ (.A0(\frame[3] ),
    .A1(\frame[2] ),
    .A2(\frame[1] ),
    .A3(\frame[0] ),
    .S0(\bit_idx[0] ),
    .S1(_002_),
    .X(_060_));
 sky130_fd_sc_hd__mux4_1 _094_ (.A0(\frame[7] ),
    .A1(\frame[6] ),
    .A2(\frame[5] ),
    .A3(\frame[4] ),
    .S0(\bit_idx[0] ),
    .S1(_002_),
    .X(_061_));
 sky130_fd_sc_hd__mux2i_1 _095_ (.A0(_060_),
    .A1(_061_),
    .S(_056_),
    .Y(_062_));
 sky130_fd_sc_hd__or3b_1 _096_ (.A(_062_),
    .B(_055_),
    .C_N(_046_),
    .X(_063_));
 sky130_fd_sc_hd__o211ai_2 _097_ (.A1(_053_),
    .A2(_059_),
    .B1(_045_),
    .C1(_063_),
    .Y(_022_));
 sky130_fd_sc_hd__a21oi_1 _098_ (.A1(_046_),
    .A2(_048_),
    .B1(net14),
    .Y(_064_));
 sky130_fd_sc_hd__nand2_1 _099_ (.A(\bit_idx[3] ),
    .B(_064_),
    .Y(_065_));
 sky130_fd_sc_hd__nand4_1 _100_ (.A(net15),
    .B(_046_),
    .C(_048_),
    .D(_055_),
    .Y(_066_));
 sky130_fd_sc_hd__nand2_1 _101_ (.A(net8),
    .B(net14),
    .Y(_043_));
 sky130_fd_sc_hd__a21oi_1 _102_ (.A1(_065_),
    .A2(_066_),
    .B1(net16),
    .Y(_021_));
 sky130_fd_sc_hd__nor3b_1 _103_ (.A(_004_),
    .B(_006_),
    .C_N(\cnt[2] ),
    .Y(_067_));
 sky130_fd_sc_hd__nor2b_1 _104_ (.A(\cnt[2] ),
    .B_N(_006_),
    .Y(_068_));
 sky130_fd_sc_hd__o21ai_0 _105_ (.A1(_067_),
    .A2(_068_),
    .B1(net15),
    .Y(_069_));
 sky130_fd_sc_hd__nand2_1 _106_ (.A(\cnt[2] ),
    .B(_051_),
    .Y(_070_));
 sky130_fd_sc_hd__a21oi_1 _107_ (.A1(_069_),
    .A2(_070_),
    .B1(net16),
    .Y(_020_));
 sky130_fd_sc_hd__nand2_1 _108_ (.A(\frame[0] ),
    .B(_052_),
    .Y(_071_));
 sky130_fd_sc_hd__nand2_1 _109_ (.A(_045_),
    .B(_071_),
    .Y(_019_));
 sky130_fd_sc_hd__mux2i_1 _110_ (.A0(\frame[1] ),
    .A1(net1),
    .S(net14),
    .Y(_072_));
 sky130_fd_sc_hd__nand2_1 _111_ (.A(_045_),
    .B(_072_),
    .Y(_018_));
 sky130_fd_sc_hd__mux2i_1 _113_ (.A0(\frame[2] ),
    .A1(net2),
    .S(net14),
    .Y(_073_));
 sky130_fd_sc_hd__nand2_1 _114_ (.A(_045_),
    .B(_073_),
    .Y(_017_));
 sky130_fd_sc_hd__mux2i_1 _115_ (.A0(\frame[3] ),
    .A1(net3),
    .S(net14),
    .Y(_074_));
 sky130_fd_sc_hd__nand2_1 _116_ (.A(_045_),
    .B(_074_),
    .Y(_016_));
 sky130_fd_sc_hd__mux2i_1 _117_ (.A0(\frame[4] ),
    .A1(net4),
    .S(net14),
    .Y(_075_));
 sky130_fd_sc_hd__nand2_1 _118_ (.A(_045_),
    .B(_075_),
    .Y(_015_));
 sky130_fd_sc_hd__mux2i_1 _119_ (.A0(\frame[5] ),
    .A1(net5),
    .S(net14),
    .Y(_025_));
 sky130_fd_sc_hd__nand2_1 _120_ (.A(_045_),
    .B(_025_),
    .Y(_014_));
 sky130_fd_sc_hd__mux2i_1 _121_ (.A0(\frame[6] ),
    .A1(net6),
    .S(net14),
    .Y(_026_));
 sky130_fd_sc_hd__nand2_1 _122_ (.A(_045_),
    .B(_026_),
    .Y(_013_));
 sky130_fd_sc_hd__clkinv_1 _123_ (.A(net9),
    .Y(_045_));
 sky130_fd_sc_hd__mux2i_1 _124_ (.A0(\frame[7] ),
    .A1(net7),
    .S(net14),
    .Y(_027_));
 sky130_fd_sc_hd__nand2_1 _125_ (.A(_045_),
    .B(_027_),
    .Y(_012_));
 sky130_fd_sc_hd__nand4b_1 _126_ (.A_N(\bit_idx[0] ),
    .B(_046_),
    .C(_048_),
    .D(net15),
    .Y(_028_));
 sky130_fd_sc_hd__nand2_1 _127_ (.A(\bit_idx[0] ),
    .B(_064_),
    .Y(_029_));
 sky130_fd_sc_hd__a21oi_1 _128_ (.A1(_028_),
    .A2(_029_),
    .B1(net16),
    .Y(_011_));
 sky130_fd_sc_hd__nand2_1 _129_ (.A(\bit_idx[1] ),
    .B(_064_),
    .Y(_030_));
 sky130_fd_sc_hd__nand4b_1 _130_ (.A_N(_002_),
    .B(_046_),
    .C(_048_),
    .D(net15),
    .Y(_031_));
 sky130_fd_sc_hd__a21oi_1 _131_ (.A1(_030_),
    .A2(_031_),
    .B1(net16),
    .Y(_010_));
 sky130_fd_sc_hd__nand3_1 _132_ (.A(_003_),
    .B(_046_),
    .C(_048_),
    .Y(_032_));
 sky130_fd_sc_hd__or3b_1 _133_ (.A(\bit_idx[2] ),
    .B(_032_),
    .C_N(net15),
    .X(_033_));
 sky130_fd_sc_hd__o211ai_1 _134_ (.A1(_040_),
    .A2(net14),
    .B1(_043_),
    .C1(_045_),
    .Y(_024_));
 sky130_fd_sc_hd__nand3_1 _135_ (.A(net15),
    .B(\bit_idx[2] ),
    .C(_032_),
    .Y(_034_));
 sky130_fd_sc_hd__nand3b_1 _136_ (.A_N(net10),
    .B(\bit_idx[2] ),
    .C(_058_),
    .Y(_035_));
 sky130_fd_sc_hd__a31oi_1 _137_ (.A1(_033_),
    .A2(_034_),
    .A3(_035_),
    .B1(net16),
    .Y(_009_));
 sky130_fd_sc_hd__a21oi_1 _138_ (.A1(_004_),
    .A2(\cnt[2] ),
    .B1(\cnt[0] ),
    .Y(_036_));
 sky130_fd_sc_hd__a22oi_1 _139_ (.A1(\cnt[0] ),
    .A2(_051_),
    .B1(_036_),
    .B2(net15),
    .Y(_037_));
 sky130_fd_sc_hd__nor2_1 _140_ (.A(net16),
    .B(_037_),
    .Y(_008_));
 sky130_fd_sc_hd__nand2_1 _141_ (.A(_004_),
    .B(\cnt[2] ),
    .Y(_038_));
 sky130_fd_sc_hd__a32oi_1 _142_ (.A1(net15),
    .A2(_005_),
    .A3(_038_),
    .B1(_051_),
    .B2(\cnt[1] ),
    .Y(_039_));
 sky130_fd_sc_hd__nor2_1 _143_ (.A(net16),
    .B(_039_),
    .Y(_007_));
 sky130_fd_sc_hd__inv_1 _144_ (.A(\bit_idx[1] ),
    .Y(_000_));
 sky130_fd_sc_hd__and3_1 _145_ (.A(net11),
    .B(_004_),
    .C(\cnt[2] ),
    .X(_046_));
 sky130_fd_sc_hd__nand3b_2 _147_ (.A_N(\bit_idx[2] ),
    .B(_001_),
    .C(\bit_idx[3] ),
    .Y(_048_));
 sky130_fd_sc_hd__ha_1 _148_ (.A(\bit_idx[0] ),
    .B(_000_),
    .COUT(_001_),
    .SUM(_002_));
 sky130_fd_sc_hd__ha_1 _149_ (.A(\bit_idx[0] ),
    .B(\bit_idx[1] ),
    .COUT(_003_),
    .SUM(_076_));
 sky130_fd_sc_hd__ha_1 _150_ (.A(\cnt[0] ),
    .B(\cnt[1] ),
    .COUT(_004_),
    .SUM(_005_));
 sky130_fd_sc_hd__ha_1 _151_ (.A(\cnt[0] ),
    .B(\cnt[1] ),
    .COUT(_006_),
    .SUM(_077_));
 sky130_fd_sc_hd__dfxtp_1 \bit_idx[0]$_SDFFE_PP0P_  (.D(_011_),
    .Q(\bit_idx[0] ),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \bit_idx[1]$_SDFFE_PP0P_  (.D(_010_),
    .Q(\bit_idx[1] ),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \bit_idx[2]$_SDFFE_PP0P_  (.D(_009_),
    .Q(\bit_idx[2] ),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \bit_idx[3]$_SDFFE_PP0P_  (.D(_021_),
    .Q(\bit_idx[3] ),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \busy$_SDFF_PP0_  (.D(_023_),
    .Q(net11),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .X(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .X(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \cnt[0]$_SDFFE_PP0P_  (.D(_008_),
    .Q(\cnt[0] ),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \cnt[1]$_SDFFE_PP0P_  (.D(_007_),
    .Q(\cnt[1] ),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \cnt[2]$_SDFFE_PP0P_  (.D(_020_),
    .Q(\cnt[2] ),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[0]$_SDFFE_PP1P_  (.D(_019_),
    .Q(\frame[0] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[1]$_SDFFE_PP1P_  (.D(_018_),
    .Q(\frame[1] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[2]$_SDFFE_PP1P_  (.D(_017_),
    .Q(\frame[2] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[3]$_SDFFE_PP1P_  (.D(_016_),
    .Q(\frame[3] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[4]$_SDFFE_PP1P_  (.D(_015_),
    .Q(\frame[4] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[5]$_SDFFE_PP1P_  (.D(_014_),
    .Q(\frame[5] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[6]$_SDFFE_PP1P_  (.D(_013_),
    .Q(\frame[6] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[7]$_SDFFE_PP1P_  (.D(_012_),
    .Q(\frame[7] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \frame[8]$_SDFFE_PP1P_  (.D(_024_),
    .Q(\frame[8] ),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input1 (.A(data_in[0]),
    .X(net1));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input10 (.A(start),
    .X(net10));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input2 (.A(data_in[1]),
    .X(net2));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input3 (.A(data_in[2]),
    .X(net3));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input4 (.A(data_in[3]),
    .X(net4));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input5 (.A(data_in[4]),
    .X(net5));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input6 (.A(data_in[5]),
    .X(net6));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input7 (.A(data_in[6]),
    .X(net7));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input8 (.A(data_in[7]),
    .X(net8));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input9 (.A(reset),
    .X(net9));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output11 (.A(net15),
    .X(busy));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output12 (.A(net12),
    .X(tx));
 sky130_fd_sc_hd__buf_4 place14 (.A(_041_),
    .X(net14));
 sky130_fd_sc_hd__buf_4 place15 (.A(net11),
    .X(net15));
 sky130_fd_sc_hd__buf_4 place16 (.A(net9),
    .X(net16));
 sky130_fd_sc_hd__dfxtp_1 \tx$_SDFFE_PP1P_  (.D(_022_),
    .Q(net12),
    .CLK(clknet_1_1__leaf_clk));
endmodule
