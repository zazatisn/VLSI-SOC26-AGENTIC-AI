module sync_fifo (clk,
    empty,
    full,
    rd_en,
    reset,
    wr_en,
    din,
    dout);
 input clk;
 output empty;
 output full;
 input rd_en;
 input reset;
 input wr_en;
 input [7:0] din;
 output [7:0] dout;

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
 wire _031_;
 wire _032_;
 wire _033_;
 wire _035_;
 wire _036_;
 wire _037_;
 wire _039_;
 wire _040_;
 wire _041_;
 wire _042_;
 wire _043_;
 wire _044_;
 wire _045_;
 wire _046_;
 wire _047_;
 wire _051_;
 wire _052_;
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
 wire _078_;
 wire _079_;
 wire _080_;
 wire _081_;
 wire _082_;
 wire _083_;
 wire _084_;
 wire _085_;
 wire _086_;
 wire _087_;
 wire _088_;
 wire _089_;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net8;
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
 wire \mem[0][0] ;
 wire \mem[0][1] ;
 wire \mem[0][2] ;
 wire \mem[0][3] ;
 wire \mem[0][4] ;
 wire \mem[0][5] ;
 wire \mem[0][6] ;
 wire \mem[0][7] ;
 wire \mem[1][0] ;
 wire \mem[1][1] ;
 wire \mem[1][2] ;
 wire \mem[1][3] ;
 wire \mem[1][4] ;
 wire \mem[1][5] ;
 wire \mem[1][6] ;
 wire \mem[1][7] ;
 wire \mem[2][0] ;
 wire \mem[2][1] ;
 wire \mem[2][2] ;
 wire \mem[2][3] ;
 wire \mem[2][4] ;
 wire \mem[2][5] ;
 wire \mem[2][6] ;
 wire \mem[2][7] ;
 wire \mem[3][0] ;
 wire \mem[3][1] ;
 wire \mem[3][2] ;
 wire \mem[3][3] ;
 wire \mem[3][4] ;
 wire \mem[3][5] ;
 wire \mem[3][6] ;
 wire \mem[3][7] ;
 wire \mem[4][0] ;
 wire \mem[4][1] ;
 wire \mem[4][2] ;
 wire \mem[4][3] ;
 wire \mem[4][4] ;
 wire \mem[4][5] ;
 wire \mem[4][6] ;
 wire \mem[4][7] ;
 wire \mem[5][0] ;
 wire \mem[5][1] ;
 wire \mem[5][2] ;
 wire \mem[5][3] ;
 wire \mem[5][4] ;
 wire \mem[5][5] ;
 wire \mem[5][6] ;
 wire \mem[5][7] ;
 wire \mem[6][0] ;
 wire \mem[6][1] ;
 wire \mem[6][2] ;
 wire \mem[6][3] ;
 wire \mem[6][4] ;
 wire \mem[6][5] ;
 wire \mem[6][6] ;
 wire \mem[6][7] ;
 wire \mem[7][0] ;
 wire \mem[7][1] ;
 wire \mem[7][2] ;
 wire \mem[7][3] ;
 wire \mem[7][4] ;
 wire \mem[7][5] ;
 wire \mem[7][6] ;
 wire \mem[7][7] ;
 wire net9;
 wire \rd_ptr[0] ;
 wire \rd_ptr[1] ;
 wire \rd_ptr[2] ;
 wire \rd_ptr[3] ;
 wire net10;
 wire net11;
 wire \wr_ptr[0] ;
 wire \wr_ptr[1] ;
 wire \wr_ptr[2] ;
 wire \wr_ptr[3] ;
 wire net55;
 wire net52;
 wire net41;
 wire net51;
 wire net44;
 wire net42;
 wire net43;
 wire net45;
 wire net46;
 wire net47;
 wire net48;
 wire net49;
 wire net50;
 wire net53;
 wire net54;
 wire net56;
 wire net57;
 wire clknet_0_clk;
 wire net40;
 wire clknet_3_0__leaf_clk;
 wire clknet_3_1__leaf_clk;
 wire clknet_3_2__leaf_clk;
 wire clknet_3_3__leaf_clk;
 wire clknet_3_4__leaf_clk;
 wire clknet_3_5__leaf_clk;
 wire clknet_3_6__leaf_clk;
 wire clknet_3_7__leaf_clk;

 sky130_fd_sc_hd__inv_1 _090_ (.A(net51),
    .Y(_028_));
 sky130_fd_sc_hd__nor3_2 _092_ (.A(_028_),
    .B(net45),
    .C(_037_),
    .Y(_027_));
 sky130_fd_sc_hd__nor2b_1 _094_ (.A(net10),
    .B_N(net50),
    .Y(_039_));
 sky130_fd_sc_hd__nor2_1 _095_ (.A(net10),
    .B(net50),
    .Y(_040_));
 sky130_fd_sc_hd__mux2_1 _096_ (.A0(_039_),
    .A1(_040_),
    .S(_027_),
    .X(_019_));
 sky130_fd_sc_hd__xor2_1 _097_ (.A(net50),
    .B(net54),
    .X(_041_));
 sky130_fd_sc_hd__o41ai_4 _098_ (.A1(net49),
    .A2(net48),
    .A3(_041_),
    .A4(net47),
    .B1(net9),
    .Y(_042_));
 sky130_fd_sc_hd__nor2_1 _099_ (.A(net10),
    .B(_042_),
    .Y(_043_));
 sky130_fd_sc_hd__mux4_2 _100_ (.A0(\mem[0][1] ),
    .A1(\mem[1][1] ),
    .A2(\mem[2][1] ),
    .A3(\mem[3][1] ),
    .S0(net57),
    .S1(net56),
    .X(_044_));
 sky130_fd_sc_hd__mux4_2 _101_ (.A0(\mem[4][1] ),
    .A1(\mem[5][1] ),
    .A2(\mem[6][1] ),
    .A3(\mem[7][1] ),
    .S0(net57),
    .S1(net56),
    .X(_045_));
 sky130_fd_sc_hd__mux2_2 _103_ (.A0(_044_),
    .A1(_045_),
    .S(net55),
    .X(_046_));
 sky130_fd_sc_hd__and2b_1 _104_ (.A_N(net10),
    .B(_042_),
    .X(_047_));
 sky130_fd_sc_hd__a22o_1 _106_ (.A1(_043_),
    .A2(_046_),
    .B1(_047_),
    .B2(net13),
    .X(_018_));
 sky130_fd_sc_hd__mux4_2 _109_ (.A0(\mem[0][6] ),
    .A1(\mem[1][6] ),
    .A2(\mem[2][6] ),
    .A3(\mem[3][6] ),
    .S0(net57),
    .S1(net56),
    .X(_051_));
 sky130_fd_sc_hd__mux4_2 _110_ (.A0(\mem[4][6] ),
    .A1(\mem[5][6] ),
    .A2(\mem[6][6] ),
    .A3(\mem[7][6] ),
    .S0(net57),
    .S1(net56),
    .X(_052_));
 sky130_fd_sc_hd__mux2_2 _112_ (.A0(_051_),
    .A1(_052_),
    .S(net55),
    .X(_054_));
 sky130_fd_sc_hd__xor2_4 _113_ (.A(\rd_ptr[0] ),
    .B(\wr_ptr[0] ),
    .X(_031_));
 sky130_fd_sc_hd__a22o_1 _114_ (.A1(net18),
    .A2(_047_),
    .B1(_054_),
    .B2(net43),
    .X(_017_));
 sky130_fd_sc_hd__nor4_2 _115_ (.A(net49),
    .B(net48),
    .C(_033_),
    .D(net47),
    .Y(net21));
 sky130_fd_sc_hd__nor4_1 _116_ (.A(net49),
    .B(net48),
    .C(_041_),
    .D(net47),
    .Y(net20));
 sky130_fd_sc_hd__nand3_1 _117_ (.A(net55),
    .B(net56),
    .C(net57),
    .Y(_055_));
 sky130_fd_sc_hd__o21ai_0 _118_ (.A1(net46),
    .A2(_055_),
    .B1(net54),
    .Y(_056_));
 sky130_fd_sc_hd__or3_1 _119_ (.A(net54),
    .B(net46),
    .C(_055_),
    .X(_057_));
 sky130_fd_sc_hd__a21oi_1 _120_ (.A1(_056_),
    .A2(_057_),
    .B1(net10),
    .Y(_016_));
 sky130_fd_sc_hd__or2_2 _121_ (.A(_028_),
    .B(net45),
    .X(_058_));
 sky130_fd_sc_hd__nand2b_1 _122_ (.A_N(net53),
    .B(net52),
    .Y(_059_));
 sky130_fd_sc_hd__nor2_1 _123_ (.A(_058_),
    .B(_059_),
    .Y(_026_));
 sky130_fd_sc_hd__xor2_2 _124_ (.A(\rd_ptr[2] ),
    .B(\wr_ptr[2] ),
    .X(_032_));
 sky130_fd_sc_hd__mux4_2 _125_ (.A0(\mem[0][7] ),
    .A1(\mem[1][7] ),
    .A2(\mem[2][7] ),
    .A3(\mem[3][7] ),
    .S0(net57),
    .S1(net56),
    .X(_060_));
 sky130_fd_sc_hd__mux4_2 _126_ (.A0(\mem[4][7] ),
    .A1(\mem[5][7] ),
    .A2(\mem[6][7] ),
    .A3(\mem[7][7] ),
    .S0(net57),
    .S1(net56),
    .X(_061_));
 sky130_fd_sc_hd__mux2_2 _127_ (.A0(_060_),
    .A1(_061_),
    .S(net55),
    .X(_062_));
 sky130_fd_sc_hd__a22o_1 _128_ (.A1(net19),
    .A2(_047_),
    .B1(_062_),
    .B2(_043_),
    .X(_015_));
 sky130_fd_sc_hd__nand2b_1 _129_ (.A_N(_036_),
    .B(_028_),
    .Y(_063_));
 sky130_fd_sc_hd__nor3_4 _130_ (.A(net53),
    .B(net52),
    .C(_063_),
    .Y(_020_));
 sky130_fd_sc_hd__nand2b_1 _131_ (.A_N(net52),
    .B(net53),
    .Y(_064_));
 sky130_fd_sc_hd__nor2_2 _132_ (.A(_063_),
    .B(_064_),
    .Y(_021_));
 sky130_fd_sc_hd__nor2_1 _133_ (.A(_058_),
    .B(_064_),
    .Y(_025_));
 sky130_fd_sc_hd__nor2_2 _134_ (.A(_059_),
    .B(_063_),
    .Y(_022_));
 sky130_fd_sc_hd__xnor2_2 _135_ (.A(\wr_ptr[3] ),
    .B(\rd_ptr[3] ),
    .Y(_033_));
 sky130_fd_sc_hd__nor2_2 _136_ (.A(_037_),
    .B(_063_),
    .Y(_023_));
 sky130_fd_sc_hd__nor3_2 _137_ (.A(net53),
    .B(net52),
    .C(_058_),
    .Y(_024_));
 sky130_fd_sc_hd__mux4_2 _138_ (.A0(\mem[0][0] ),
    .A1(\mem[1][0] ),
    .A2(\mem[2][0] ),
    .A3(\mem[3][0] ),
    .S0(net57),
    .S1(net56),
    .X(_065_));
 sky130_fd_sc_hd__mux4_2 _139_ (.A0(\mem[4][0] ),
    .A1(\mem[5][0] ),
    .A2(\mem[6][0] ),
    .A3(\mem[7][0] ),
    .S0(net57),
    .S1(net56),
    .X(_066_));
 sky130_fd_sc_hd__mux2_2 _140_ (.A0(_065_),
    .A1(_066_),
    .S(net55),
    .X(_067_));
 sky130_fd_sc_hd__a22o_1 _141_ (.A1(net12),
    .A2(_047_),
    .B1(_067_),
    .B2(net43),
    .X(_014_));
 sky130_fd_sc_hd__mux4_2 _142_ (.A0(\mem[0][4] ),
    .A1(\mem[1][4] ),
    .A2(\mem[2][4] ),
    .A3(\mem[3][4] ),
    .S0(net57),
    .S1(net56),
    .X(_068_));
 sky130_fd_sc_hd__mux4_2 _143_ (.A0(\mem[4][4] ),
    .A1(\mem[5][4] ),
    .A2(\mem[6][4] ),
    .A3(\mem[7][4] ),
    .S0(net57),
    .S1(net56),
    .X(_069_));
 sky130_fd_sc_hd__mux2_2 _144_ (.A0(_068_),
    .A1(_069_),
    .S(net55),
    .X(_070_));
 sky130_fd_sc_hd__a22o_1 _145_ (.A1(net16),
    .A2(_047_),
    .B1(_070_),
    .B2(net43),
    .X(_013_));
 sky130_fd_sc_hd__xor2_1 _147_ (.A(net57),
    .B(net46),
    .X(_071_));
 sky130_fd_sc_hd__nor2_1 _148_ (.A(net10),
    .B(_071_),
    .Y(_012_));
 sky130_fd_sc_hd__mux2i_1 _149_ (.A0(_001_),
    .A1(net56),
    .S(net46),
    .Y(_072_));
 sky130_fd_sc_hd__nor2_1 _150_ (.A(net10),
    .B(_072_),
    .Y(_011_));
 sky130_fd_sc_hd__inv_1 _151_ (.A(_000_),
    .Y(_073_));
 sky130_fd_sc_hd__o21ai_0 _152_ (.A1(_073_),
    .A2(net46),
    .B1(net55),
    .Y(_074_));
 sky130_fd_sc_hd__or3_1 _153_ (.A(net55),
    .B(_073_),
    .C(net46),
    .X(_075_));
 sky130_fd_sc_hd__a21oi_1 _154_ (.A1(_074_),
    .A2(_075_),
    .B1(net10),
    .Y(_010_));
 sky130_fd_sc_hd__xor2_1 _155_ (.A(net53),
    .B(net45),
    .X(_076_));
 sky130_fd_sc_hd__nor2_1 _156_ (.A(net10),
    .B(_076_),
    .Y(_009_));
 sky130_fd_sc_hd__xor2_2 _157_ (.A(\rd_ptr[1] ),
    .B(\wr_ptr[1] ),
    .X(_035_));
 sky130_fd_sc_hd__mux2i_1 _158_ (.A0(_003_),
    .A1(net52),
    .S(net45),
    .Y(_077_));
 sky130_fd_sc_hd__nor2_1 _159_ (.A(net10),
    .B(_077_),
    .Y(_008_));
 sky130_fd_sc_hd__inv_1 _160_ (.A(_002_),
    .Y(_078_));
 sky130_fd_sc_hd__o21ai_0 _161_ (.A1(_078_),
    .A2(net45),
    .B1(net51),
    .Y(_079_));
 sky130_fd_sc_hd__or3_1 _162_ (.A(net51),
    .B(_078_),
    .C(net45),
    .X(_080_));
 sky130_fd_sc_hd__a21oi_1 _163_ (.A1(_079_),
    .A2(_080_),
    .B1(net10),
    .Y(_007_));
 sky130_fd_sc_hd__mux4_2 _164_ (.A0(\mem[0][5] ),
    .A1(\mem[1][5] ),
    .A2(\mem[2][5] ),
    .A3(\mem[3][5] ),
    .S0(net57),
    .S1(net56),
    .X(_081_));
 sky130_fd_sc_hd__mux4_2 _165_ (.A0(\mem[4][5] ),
    .A1(\mem[5][5] ),
    .A2(\mem[6][5] ),
    .A3(\mem[7][5] ),
    .S0(net57),
    .S1(net56),
    .X(_082_));
 sky130_fd_sc_hd__mux2_2 _166_ (.A0(_081_),
    .A1(_082_),
    .S(net55),
    .X(_083_));
 sky130_fd_sc_hd__a22o_1 _167_ (.A1(net17),
    .A2(_047_),
    .B1(_083_),
    .B2(net43),
    .X(_006_));
 sky130_fd_sc_hd__o41ai_4 _168_ (.A1(_031_),
    .A2(_032_),
    .A3(_033_),
    .A4(_035_),
    .B1(net11),
    .Y(_036_));
 sky130_fd_sc_hd__mux4_2 _169_ (.A0(\mem[0][3] ),
    .A1(\mem[1][3] ),
    .A2(\mem[2][3] ),
    .A3(\mem[3][3] ),
    .S0(net57),
    .S1(net56),
    .X(_084_));
 sky130_fd_sc_hd__mux4_2 _170_ (.A0(\mem[4][3] ),
    .A1(\mem[5][3] ),
    .A2(\mem[6][3] ),
    .A3(\mem[7][3] ),
    .S0(net57),
    .S1(net56),
    .X(_085_));
 sky130_fd_sc_hd__mux2_2 _171_ (.A0(_084_),
    .A1(_085_),
    .S(net55),
    .X(_086_));
 sky130_fd_sc_hd__a22o_1 _172_ (.A1(net15),
    .A2(_047_),
    .B1(_086_),
    .B2(net43),
    .X(_005_));
 sky130_fd_sc_hd__mux4_2 _173_ (.A0(\mem[0][2] ),
    .A1(\mem[1][2] ),
    .A2(\mem[2][2] ),
    .A3(\mem[3][2] ),
    .S0(net57),
    .S1(net56),
    .X(_087_));
 sky130_fd_sc_hd__mux4_2 _174_ (.A0(\mem[4][2] ),
    .A1(\mem[5][2] ),
    .A2(\mem[6][2] ),
    .A3(\mem[7][2] ),
    .S0(net57),
    .S1(net56),
    .X(_088_));
 sky130_fd_sc_hd__mux2_2 _175_ (.A0(_087_),
    .A1(_088_),
    .S(net55),
    .X(_089_));
 sky130_fd_sc_hd__a22o_1 _176_ (.A1(net14),
    .A2(_047_),
    .B1(_089_),
    .B2(net43),
    .X(_004_));
 sky130_fd_sc_hd__nand2_1 _177_ (.A(net53),
    .B(net52),
    .Y(_037_));
 sky130_fd_sc_hd__ha_1 _178_ (.A(net57),
    .B(net56),
    .COUT(_000_),
    .SUM(_001_));
 sky130_fd_sc_hd__ha_1 _179_ (.A(net53),
    .B(net52),
    .COUT(_002_),
    .SUM(_003_));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_0__f_clk (.A(clknet_0_clk),
    .X(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_1__f_clk (.A(clknet_0_clk),
    .X(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_2__f_clk (.A(clknet_0_clk),
    .X(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_3__f_clk (.A(clknet_0_clk),
    .X(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_4__f_clk (.A(clknet_0_clk),
    .X(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_5__f_clk (.A(clknet_0_clk),
    .X(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_6__f_clk (.A(clknet_0_clk),
    .X(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_3_7__f_clk (.A(clknet_0_clk),
    .X(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__clkbuf_1 clkload0 (.A(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__clkinv_2 clkload1 (.A(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__clkbuf_1 clkload2 (.A(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__clkbuf_1 clkload3 (.A(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__clkinv_2 clkload4 (.A(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__clkbuf_1 clkload5 (.A(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkload6 (.A(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[0]$_SDFFE_PP0P_  (.D(_014_),
    .Q(net12),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[1]$_SDFFE_PP0P_  (.D(_018_),
    .Q(net13),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[2]$_SDFFE_PP0P_  (.D(_004_),
    .Q(net14),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[3]$_SDFFE_PP0P_  (.D(_005_),
    .Q(net15),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[4]$_SDFFE_PP0P_  (.D(_013_),
    .Q(net16),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[5]$_SDFFE_PP0P_  (.D(_006_),
    .Q(net17),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[6]$_SDFFE_PP0P_  (.D(_017_),
    .Q(net18),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \dout[7]$_SDFFE_PP0P_  (.D(_015_),
    .Q(net19),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input1 (.A(din[0]),
    .X(net1));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input10 (.A(reset),
    .X(net10));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input11 (.A(wr_en),
    .X(net11));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input2 (.A(din[1]),
    .X(net2));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input3 (.A(din[2]),
    .X(net3));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input4 (.A(din[3]),
    .X(net4));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input5 (.A(din[4]),
    .X(net5));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input6 (.A(din[5]),
    .X(net6));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input7 (.A(din[6]),
    .X(net7));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input8 (.A(din[7]),
    .X(net8));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input9 (.A(rd_en),
    .X(net9));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][0]$_DFFE_PP_  (.D(net1),
    .DE(_020_),
    .Q(\mem[0][0] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][1]$_DFFE_PP_  (.D(net2),
    .DE(_020_),
    .Q(\mem[0][1] ),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][2]$_DFFE_PP_  (.D(net3),
    .DE(_020_),
    .Q(\mem[0][2] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][3]$_DFFE_PP_  (.D(net4),
    .DE(_020_),
    .Q(\mem[0][3] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][4]$_DFFE_PP_  (.D(net5),
    .DE(_020_),
    .Q(\mem[0][4] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][5]$_DFFE_PP_  (.D(net6),
    .DE(_020_),
    .Q(\mem[0][5] ),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][6]$_DFFE_PP_  (.D(net7),
    .DE(_020_),
    .Q(\mem[0][6] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[0][7]$_DFFE_PP_  (.D(net8),
    .DE(_020_),
    .Q(\mem[0][7] ),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][0]$_DFFE_PP_  (.D(net1),
    .DE(_021_),
    .Q(\mem[1][0] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][1]$_DFFE_PP_  (.D(net2),
    .DE(_021_),
    .Q(\mem[1][1] ),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][2]$_DFFE_PP_  (.D(net3),
    .DE(_021_),
    .Q(\mem[1][2] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][3]$_DFFE_PP_  (.D(net4),
    .DE(_021_),
    .Q(\mem[1][3] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][4]$_DFFE_PP_  (.D(net5),
    .DE(_021_),
    .Q(\mem[1][4] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][5]$_DFFE_PP_  (.D(net6),
    .DE(_021_),
    .Q(\mem[1][5] ),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][6]$_DFFE_PP_  (.D(net7),
    .DE(_021_),
    .Q(\mem[1][6] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[1][7]$_DFFE_PP_  (.D(net8),
    .DE(_021_),
    .Q(\mem[1][7] ),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][0]$_DFFE_PP_  (.D(net1),
    .DE(_022_),
    .Q(\mem[2][0] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][1]$_DFFE_PP_  (.D(net2),
    .DE(_022_),
    .Q(\mem[2][1] ),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][2]$_DFFE_PP_  (.D(net3),
    .DE(_022_),
    .Q(\mem[2][2] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][3]$_DFFE_PP_  (.D(net4),
    .DE(_022_),
    .Q(\mem[2][3] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][4]$_DFFE_PP_  (.D(net5),
    .DE(_022_),
    .Q(\mem[2][4] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][5]$_DFFE_PP_  (.D(net6),
    .DE(_022_),
    .Q(\mem[2][5] ),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][6]$_DFFE_PP_  (.D(net7),
    .DE(_022_),
    .Q(\mem[2][6] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[2][7]$_DFFE_PP_  (.D(net8),
    .DE(_022_),
    .Q(\mem[2][7] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][0]$_DFFE_PP_  (.D(net1),
    .DE(_023_),
    .Q(\mem[3][0] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][1]$_DFFE_PP_  (.D(net2),
    .DE(_023_),
    .Q(\mem[3][1] ),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][2]$_DFFE_PP_  (.D(net3),
    .DE(_023_),
    .Q(\mem[3][2] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][3]$_DFFE_PP_  (.D(net4),
    .DE(_023_),
    .Q(\mem[3][3] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][4]$_DFFE_PP_  (.D(net5),
    .DE(_023_),
    .Q(\mem[3][4] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][5]$_DFFE_PP_  (.D(net6),
    .DE(_023_),
    .Q(\mem[3][5] ),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][6]$_DFFE_PP_  (.D(net7),
    .DE(_023_),
    .Q(\mem[3][6] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[3][7]$_DFFE_PP_  (.D(net8),
    .DE(_023_),
    .Q(\mem[3][7] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][0]$_DFFE_PP_  (.D(net1),
    .DE(net40),
    .Q(\mem[4][0] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][1]$_DFFE_PP_  (.D(net2),
    .DE(net40),
    .Q(\mem[4][1] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][2]$_DFFE_PP_  (.D(net3),
    .DE(net40),
    .Q(\mem[4][2] ),
    .CLK(clknet_3_6__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][3]$_DFFE_PP_  (.D(net4),
    .DE(net40),
    .Q(\mem[4][3] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][4]$_DFFE_PP_  (.D(net5),
    .DE(net40),
    .Q(\mem[4][4] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][5]$_DFFE_PP_  (.D(net6),
    .DE(net40),
    .Q(\mem[4][5] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][6]$_DFFE_PP_  (.D(net7),
    .DE(net40),
    .Q(\mem[4][6] ),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[4][7]$_DFFE_PP_  (.D(net8),
    .DE(net40),
    .Q(\mem[4][7] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][0]$_DFFE_PP_  (.D(net1),
    .DE(net41),
    .Q(\mem[5][0] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][1]$_DFFE_PP_  (.D(net2),
    .DE(net41),
    .Q(\mem[5][1] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][2]$_DFFE_PP_  (.D(net3),
    .DE(net41),
    .Q(\mem[5][2] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][3]$_DFFE_PP_  (.D(net4),
    .DE(net41),
    .Q(\mem[5][3] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][4]$_DFFE_PP_  (.D(net5),
    .DE(net41),
    .Q(\mem[5][4] ),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][5]$_DFFE_PP_  (.D(net6),
    .DE(net41),
    .Q(\mem[5][5] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][6]$_DFFE_PP_  (.D(net7),
    .DE(net41),
    .Q(\mem[5][6] ),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[5][7]$_DFFE_PP_  (.D(net8),
    .DE(net41),
    .Q(\mem[5][7] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][0]$_DFFE_PP_  (.D(net1),
    .DE(net42),
    .Q(\mem[6][0] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][1]$_DFFE_PP_  (.D(net2),
    .DE(net42),
    .Q(\mem[6][1] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][2]$_DFFE_PP_  (.D(net3),
    .DE(net42),
    .Q(\mem[6][2] ),
    .CLK(clknet_3_3__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][3]$_DFFE_PP_  (.D(net4),
    .DE(net42),
    .Q(\mem[6][3] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][4]$_DFFE_PP_  (.D(net5),
    .DE(net42),
    .Q(\mem[6][4] ),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][5]$_DFFE_PP_  (.D(net6),
    .DE(net42),
    .Q(\mem[6][5] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][6]$_DFFE_PP_  (.D(net7),
    .DE(net42),
    .Q(\mem[6][6] ),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[6][7]$_DFFE_PP_  (.D(net8),
    .DE(net42),
    .Q(\mem[6][7] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][0]$_DFFE_PP_  (.D(net1),
    .DE(net44),
    .Q(\mem[7][0] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][1]$_DFFE_PP_  (.D(net2),
    .DE(net44),
    .Q(\mem[7][1] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][2]$_DFFE_PP_  (.D(net3),
    .DE(net44),
    .Q(\mem[7][2] ),
    .CLK(clknet_3_1__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][3]$_DFFE_PP_  (.D(net4),
    .DE(net44),
    .Q(\mem[7][3] ),
    .CLK(clknet_3_2__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][4]$_DFFE_PP_  (.D(net5),
    .DE(net44),
    .Q(\mem[7][4] ),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][5]$_DFFE_PP_  (.D(net6),
    .DE(net44),
    .Q(\mem[7][5] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][6]$_DFFE_PP_  (.D(net7),
    .DE(net44),
    .Q(\mem[7][6] ),
    .CLK(clknet_3_7__leaf_clk));
 sky130_fd_sc_hd__edfxtp_1 \mem[7][7]$_DFFE_PP_  (.D(net8),
    .DE(net44),
    .Q(\mem[7][7] ),
    .CLK(clknet_3_0__leaf_clk));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output12 (.A(net12),
    .X(dout[0]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output13 (.A(net13),
    .X(dout[1]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output14 (.A(net14),
    .X(dout[2]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output15 (.A(net15),
    .X(dout[3]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output16 (.A(net16),
    .X(dout[4]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output17 (.A(net17),
    .X(dout[5]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output18 (.A(net18),
    .X(dout[6]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output19 (.A(net19),
    .X(dout[7]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output20 (.A(net20),
    .X(empty));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output21 (.A(net21),
    .X(full));
 sky130_fd_sc_hd__buf_4 place40 (.A(_024_),
    .X(net40));
 sky130_fd_sc_hd__buf_4 place41 (.A(_025_),
    .X(net41));
 sky130_fd_sc_hd__buf_4 place42 (.A(_026_),
    .X(net42));
 sky130_fd_sc_hd__buf_4 place43 (.A(_043_),
    .X(net43));
 sky130_fd_sc_hd__buf_4 place44 (.A(_027_),
    .X(net44));
 sky130_fd_sc_hd__buf_4 place45 (.A(_036_),
    .X(net45));
 sky130_fd_sc_hd__buf_4 place46 (.A(_042_),
    .X(net46));
 sky130_fd_sc_hd__buf_4 place47 (.A(_035_),
    .X(net47));
 sky130_fd_sc_hd__buf_4 place48 (.A(_032_),
    .X(net48));
 sky130_fd_sc_hd__buf_4 place49 (.A(_031_),
    .X(net49));
 sky130_fd_sc_hd__buf_4 place50 (.A(\wr_ptr[3] ),
    .X(net50));
 sky130_fd_sc_hd__buf_4 place51 (.A(\wr_ptr[2] ),
    .X(net51));
 sky130_fd_sc_hd__buf_4 place52 (.A(\wr_ptr[1] ),
    .X(net52));
 sky130_fd_sc_hd__buf_4 place53 (.A(\wr_ptr[0] ),
    .X(net53));
 sky130_fd_sc_hd__buf_4 place54 (.A(\rd_ptr[3] ),
    .X(net54));
 sky130_fd_sc_hd__buf_4 place55 (.A(\rd_ptr[2] ),
    .X(net55));
 sky130_fd_sc_hd__buf_4 place56 (.A(\rd_ptr[1] ),
    .X(net56));
 sky130_fd_sc_hd__buf_8 place57 (.A(\rd_ptr[0] ),
    .X(net57));
 sky130_fd_sc_hd__dfxtp_1 \rd_ptr[0]$_SDFFE_PP0P_  (.D(_012_),
    .Q(\rd_ptr[0] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \rd_ptr[1]$_SDFFE_PP0P_  (.D(_011_),
    .Q(\rd_ptr[1] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \rd_ptr[2]$_SDFFE_PP0P_  (.D(_010_),
    .Q(\rd_ptr[2] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \rd_ptr[3]$_SDFFE_PP0P_  (.D(_016_),
    .Q(\rd_ptr[3] ),
    .CLK(clknet_3_5__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \wr_ptr[0]$_SDFFE_PP0P_  (.D(_009_),
    .Q(\wr_ptr[0] ),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \wr_ptr[1]$_SDFFE_PP0P_  (.D(_008_),
    .Q(\wr_ptr[1] ),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \wr_ptr[2]$_SDFFE_PP0P_  (.D(_007_),
    .Q(\wr_ptr[2] ),
    .CLK(clknet_3_4__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \wr_ptr[3]$_SDFFE_PP0P_  (.D(_019_),
    .Q(\wr_ptr[3] ),
    .CLK(clknet_3_5__leaf_clk));
endmodule
