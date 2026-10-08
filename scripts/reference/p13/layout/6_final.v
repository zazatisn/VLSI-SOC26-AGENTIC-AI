module sliding_window_avg_8bit (clk,
    reset,
    data_in,
    data_out);
 input clk;
 input reset;
 input [7:0] data_in;
 output [7:0] data_out;

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
 wire _042_;
 wire _043_;
 wire _044_;
 wire _045_;
 wire _046_;
 wire _047_;
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
 wire _078_;
 wire _079_;
 wire _080_;
 wire _081_;
 wire _082_;
 wire _083_;
 wire _084_;
 wire _085_;
 wire _087_;
 wire _088_;
 wire _089_;
 wire _090_;
 wire _091_;
 wire _092_;
 wire _093_;
 wire _094_;
 wire _095_;
 wire _096_;
 wire _097_;
 wire _098_;
 wire _099_;
 wire _100_;
 wire _101_;
 wire _102_;
 wire _103_;
 wire _104_;
 wire _105_;
 wire _106_;
 wire _107_;
 wire _108_;
 wire _109_;
 wire _110_;
 wire _111_;
 wire _112_;
 wire _113_;
 wire _114_;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net8;
 wire net10;
 wire net11;
 wire net12;
 wire net13;
 wire net14;
 wire net15;
 wire net16;
 wire net17;
 wire net9;
 wire \s0[0] ;
 wire \s0[1] ;
 wire \s0[2] ;
 wire \s0[3] ;
 wire \s0[4] ;
 wire \s0[5] ;
 wire \s0[6] ;
 wire \s0[7] ;
 wire \s1[0] ;
 wire \s1[1] ;
 wire \s1[2] ;
 wire \s1[3] ;
 wire \s1[4] ;
 wire \s1[5] ;
 wire \s1[6] ;
 wire \s1[7] ;
 wire \s2[0] ;
 wire \s2[1] ;
 wire \s2[2] ;
 wire \s2[3] ;
 wire \s2[4] ;
 wire \s2[5] ;
 wire \s2[6] ;
 wire \s2[7] ;
 wire \total[2] ;
 wire net28;
 wire net29;
 wire net30;
 wire net32;
 wire net33;
 wire clknet_0_clk;
 wire net25;
 wire net27;
 wire net31;
 wire clknet_2_0__leaf_clk;
 wire clknet_2_1__leaf_clk;
 wire clknet_2_2__leaf_clk;
 wire clknet_2_3__leaf_clk;
 wire net34;
 wire net45;
 wire net39;
 wire net40;
 wire net44;

 sky130_fd_sc_hd__o31a_1 _117_ (.A1(_016_),
    .A2(_008_),
    .A3(_081_),
    .B1(_082_),
    .X(_083_));
 sky130_fd_sc_hd__nor2_1 _118_ (.A(_011_),
    .B(_010_),
    .Y(_084_));
 sky130_fd_sc_hd__nor2_1 _119_ (.A(net9),
    .B(_084_),
    .Y(_085_));
 sky130_fd_sc_hd__o31a_1 _120_ (.A1(_012_),
    .A2(_010_),
    .A3(_083_),
    .B1(_085_),
    .X(_046_));
 sky130_fd_sc_hd__nor2b_1 _121_ (.A(net33),
    .B_N(\s1[0] ),
    .Y(_045_));
 sky130_fd_sc_hd__nor2b_1 _123_ (.A(net33),
    .B_N(\s1[1] ),
    .Y(_044_));
 sky130_fd_sc_hd__nor2b_1 _124_ (.A(net33),
    .B_N(\s1[2] ),
    .Y(_043_));
 sky130_fd_sc_hd__nor2b_1 _125_ (.A(net33),
    .B_N(\s1[3] ),
    .Y(_042_));
 sky130_fd_sc_hd__nor2b_1 _126_ (.A(net9),
    .B_N(\s1[4] ),
    .Y(_041_));
 sky130_fd_sc_hd__nor2b_1 _127_ (.A(net9),
    .B_N(\s1[7] ),
    .Y(_049_));
 sky130_fd_sc_hd__nor2b_1 _128_ (.A(net9),
    .B_N(\s1[5] ),
    .Y(_040_));
 sky130_fd_sc_hd__nor2b_1 _129_ (.A(net9),
    .B_N(\s1[6] ),
    .Y(_039_));
 sky130_fd_sc_hd__nor2b_1 _130_ (.A(net33),
    .B_N(\s0[0] ),
    .Y(_038_));
 sky130_fd_sc_hd__nor2b_1 _131_ (.A(net33),
    .B_N(net44),
    .Y(_037_));
 sky130_fd_sc_hd__nor2b_1 _132_ (.A(net33),
    .B_N(\s0[2] ),
    .Y(_036_));
 sky130_fd_sc_hd__nor2b_1 _133_ (.A(net33),
    .B_N(\s0[3] ),
    .Y(_035_));
 sky130_fd_sc_hd__nor2b_1 _135_ (.A(net9),
    .B_N(\s0[4] ),
    .Y(_034_));
 sky130_fd_sc_hd__nor2b_1 _136_ (.A(net9),
    .B_N(\s0[5] ),
    .Y(_033_));
 sky130_fd_sc_hd__nor2b_1 _137_ (.A(net9),
    .B_N(\s0[6] ),
    .Y(_032_));
 sky130_fd_sc_hd__nor2b_1 _138_ (.A(net9),
    .B_N(\s0[7] ),
    .Y(_048_));
 sky130_fd_sc_hd__nor2b_1 _139_ (.A(net33),
    .B_N(net1),
    .Y(_031_));
 sky130_fd_sc_hd__nor2b_1 _140_ (.A(net33),
    .B_N(net2),
    .Y(_030_));
 sky130_fd_sc_hd__nor2b_1 _141_ (.A(net33),
    .B_N(net3),
    .Y(_029_));
 sky130_fd_sc_hd__nor2b_1 _142_ (.A(net33),
    .B_N(net4),
    .Y(_028_));
 sky130_fd_sc_hd__nor2b_1 _143_ (.A(net9),
    .B_N(net5),
    .Y(_027_));
 sky130_fd_sc_hd__nor2b_1 _144_ (.A(net9),
    .B_N(net6),
    .Y(_026_));
 sky130_fd_sc_hd__nor2b_1 _145_ (.A(net9),
    .B_N(net7),
    .Y(_025_));
 sky130_fd_sc_hd__nor2b_1 _146_ (.A(net33),
    .B_N(\total[2] ),
    .Y(_024_));
 sky130_fd_sc_hd__xnor2_1 _147_ (.A(net40),
    .B(net30),
    .Y(_051_));
 sky130_fd_sc_hd__nor2_1 _148_ (.A(net33),
    .B(_051_),
    .Y(_023_));
 sky130_fd_sc_hd__nor2b_1 _149_ (.A(net9),
    .B_N(net8),
    .Y(_047_));
 sky130_fd_sc_hd__a41o_1 _150_ (.A1(net34),
    .A2(_007_),
    .A3(\s2[0] ),
    .A4(_003_),
    .B1(_006_),
    .X(_052_));
 sky130_fd_sc_hd__a21oi_1 _151_ (.A1(net30),
    .A2(_052_),
    .B1(_014_),
    .Y(_053_));
 sky130_fd_sc_hd__xor2_1 _152_ (.A(net32),
    .B(_053_),
    .X(_054_));
 sky130_fd_sc_hd__nor2_1 _153_ (.A(net33),
    .B(_054_),
    .Y(_022_));
 sky130_fd_sc_hd__a21o_1 _154_ (.A1(net30),
    .A2(net40),
    .B1(_014_),
    .X(_055_));
 sky130_fd_sc_hd__a211oi_2 _155_ (.A1(net32),
    .A2(_055_),
    .B1(net28),
    .C1(_004_),
    .Y(_056_));
 sky130_fd_sc_hd__nor3_2 _156_ (.A(net33),
    .B(_056_),
    .C(net25),
    .Y(_021_));
 sky130_fd_sc_hd__nand4_1 _157_ (.A(net34),
    .B(_007_),
    .C(\s2[0] ),
    .D(_003_),
    .Y(_057_));
 sky130_fd_sc_hd__nor3_1 _158_ (.A(_006_),
    .B(_014_),
    .C(_004_),
    .Y(_058_));
 sky130_fd_sc_hd__nor3_1 _159_ (.A(_015_),
    .B(_014_),
    .C(_004_),
    .Y(_059_));
 sky130_fd_sc_hd__inv_1 _160_ (.A(_017_),
    .Y(_078_));
 sky130_fd_sc_hd__a2111oi_2 _161_ (.A1(_057_),
    .A2(_058_),
    .B1(_059_),
    .C1(_080_),
    .D1(_078_),
    .Y(_060_));
 sky130_fd_sc_hd__nor3_1 _162_ (.A(net31),
    .B(net29),
    .C(_060_),
    .Y(_061_));
 sky130_fd_sc_hd__o21ai_0 _163_ (.A1(net29),
    .A2(_060_),
    .B1(net31),
    .Y(_062_));
 sky130_fd_sc_hd__nor3b_2 _164_ (.A(net33),
    .B(_061_),
    .C_N(_062_),
    .Y(_020_));
 sky130_fd_sc_hd__o21ai_1 _165_ (.A1(net29),
    .A2(net25),
    .B1(net31),
    .Y(_063_));
 sky130_fd_sc_hd__nor2_1 _166_ (.A(_013_),
    .B(_008_),
    .Y(_064_));
 sky130_fd_sc_hd__a211oi_1 _167_ (.A1(_063_),
    .A2(_064_),
    .B1(_083_),
    .C1(net9),
    .Y(_019_));
 sky130_fd_sc_hd__a211oi_1 _168_ (.A1(net27),
    .A2(_058_),
    .B1(_059_),
    .C1(_080_),
    .Y(_065_));
 sky130_fd_sc_hd__a21oi_1 _169_ (.A1(_013_),
    .A2(_008_),
    .B1(_012_),
    .Y(_066_));
 sky130_fd_sc_hd__nor2_1 _170_ (.A(net9),
    .B(net29),
    .Y(_067_));
 sky130_fd_sc_hd__a211oi_2 _171_ (.A1(_015_),
    .A2(_001_),
    .B1(_014_),
    .C1(_004_),
    .Y(_079_));
 sky130_fd_sc_hd__nand3_1 _172_ (.A(_011_),
    .B(_066_),
    .C(_067_),
    .Y(_068_));
 sky130_fd_sc_hd__o211ai_1 _173_ (.A1(_016_),
    .A2(_017_),
    .B1(_013_),
    .C1(_009_),
    .Y(_069_));
 sky130_fd_sc_hd__nor3_1 _174_ (.A(net9),
    .B(_011_),
    .C(_069_),
    .Y(_070_));
 sky130_fd_sc_hd__nand2_1 _175_ (.A(_065_),
    .B(_070_),
    .Y(_071_));
 sky130_fd_sc_hd__and4b_1 _176_ (.A_N(net9),
    .B(_011_),
    .C(_066_),
    .D(_069_),
    .X(_072_));
 sky130_fd_sc_hd__nor3_1 _177_ (.A(net9),
    .B(_011_),
    .C(_066_),
    .Y(_073_));
 sky130_fd_sc_hd__nor4b_1 _178_ (.A(net9),
    .B(_011_),
    .C(_069_),
    .D_N(net29),
    .Y(_074_));
 sky130_fd_sc_hd__nor3_1 _179_ (.A(_072_),
    .B(_073_),
    .C(_074_),
    .Y(_075_));
 sky130_fd_sc_hd__o211ai_1 _180_ (.A1(_065_),
    .A2(_068_),
    .B1(_071_),
    .C1(_075_),
    .Y(_018_));
 sky130_fd_sc_hd__and3_4 _181_ (.A(_002_),
    .B(\s2[0] ),
    .C(_003_),
    .X(_000_));
 sky130_fd_sc_hd__nor2_1 _182_ (.A(_005_),
    .B(_004_),
    .Y(_080_));
 sky130_fd_sc_hd__nor3_2 _183_ (.A(_078_),
    .B(_079_),
    .C(_080_),
    .Y(_081_));
 sky130_fd_sc_hd__o21a_1 _184_ (.A1(_009_),
    .A2(_008_),
    .B1(_013_),
    .X(_082_));
 sky130_fd_sc_hd__fa_2 _185_ (.A(_087_),
    .B(_000_),
    .CIN(_088_),
    .COUT(_001_),
    .SUM(\total[2] ));
 sky130_fd_sc_hd__fa_1 _186_ (.A(\s2[7] ),
    .B(_089_),
    .CIN(_090_),
    .COUT(_091_),
    .SUM(_092_));
 sky130_fd_sc_hd__fa_1 _187_ (.A(\s2[6] ),
    .B(_093_),
    .CIN(_094_),
    .COUT(_095_),
    .SUM(_096_));
 sky130_fd_sc_hd__fa_1 _188_ (.A(\s2[5] ),
    .B(_097_),
    .CIN(_098_),
    .COUT(_099_),
    .SUM(_100_));
 sky130_fd_sc_hd__fa_1 _189_ (.A(\s2[4] ),
    .B(_101_),
    .CIN(_102_),
    .COUT(_103_),
    .SUM(_104_));
 sky130_fd_sc_hd__fa_1 _190_ (.A(\s2[3] ),
    .B(_105_),
    .CIN(_106_),
    .COUT(_107_),
    .SUM(_108_));
 sky130_fd_sc_hd__fa_1 _191_ (.A(\s2[2] ),
    .B(_109_),
    .CIN(_110_),
    .COUT(_111_),
    .SUM(_087_));
 sky130_fd_sc_hd__fa_1 _192_ (.A(\s2[1] ),
    .B(_113_),
    .CIN(_112_),
    .COUT(_088_),
    .SUM(_002_));
 sky130_fd_sc_hd__fa_1 _193_ (.A(net7),
    .B(\s0[6] ),
    .CIN(\s1[6] ),
    .COUT(_090_),
    .SUM(_093_));
 sky130_fd_sc_hd__fa_1 _194_ (.A(net6),
    .B(\s0[5] ),
    .CIN(\s1[5] ),
    .COUT(_094_),
    .SUM(_097_));
 sky130_fd_sc_hd__fa_1 _195_ (.A(net5),
    .B(\s0[4] ),
    .CIN(\s1[4] ),
    .COUT(_098_),
    .SUM(_101_));
 sky130_fd_sc_hd__fa_1 _196_ (.A(net4),
    .B(\s0[3] ),
    .CIN(\s1[3] ),
    .COUT(_102_),
    .SUM(_105_));
 sky130_fd_sc_hd__fa_1 _197_ (.A(net3),
    .B(\s0[2] ),
    .CIN(\s1[2] ),
    .COUT(_106_),
    .SUM(_109_));
 sky130_fd_sc_hd__fa_1 _198_ (.A(net2),
    .B(\s0[1] ),
    .CIN(\s1[1] ),
    .COUT(_110_),
    .SUM(_112_));
 sky130_fd_sc_hd__fa_1 _199_ (.A(net1),
    .B(\s0[0] ),
    .CIN(\s1[0] ),
    .COUT(_113_),
    .SUM(_003_));
 sky130_fd_sc_hd__fa_1 _200_ (.A(net8),
    .B(\s0[7] ),
    .CIN(\s1[7] ),
    .COUT(_114_),
    .SUM(_089_));
 sky130_fd_sc_hd__ha_1 _201_ (.A(_104_),
    .B(_107_),
    .COUT(_004_),
    .SUM(_005_));
 sky130_fd_sc_hd__ha_1 _202_ (.A(_087_),
    .B(_088_),
    .COUT(_006_),
    .SUM(_007_));
 sky130_fd_sc_hd__ha_1 _203_ (.A(_096_),
    .B(_099_),
    .COUT(_008_),
    .SUM(_009_));
 sky130_fd_sc_hd__ha_1 _204_ (.A(_114_),
    .B(_091_),
    .COUT(_010_),
    .SUM(_011_));
 sky130_fd_sc_hd__ha_1 _205_ (.A(_092_),
    .B(_095_),
    .COUT(_012_),
    .SUM(_013_));
 sky130_fd_sc_hd__ha_1 _206_ (.A(_108_),
    .B(_111_),
    .COUT(_014_),
    .SUM(_015_));
 sky130_fd_sc_hd__ha_1 _207_ (.A(_100_),
    .B(_103_),
    .COUT(_016_),
    .SUM(_017_));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_2_0__f_clk (.A(clknet_0_clk),
    .X(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_2_1__f_clk (.A(clknet_0_clk),
    .X(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_2_2__f_clk (.A(clknet_0_clk),
    .X(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_2_3__f_clk (.A(clknet_0_clk),
    .X(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__clkbuf_1 clkload0 (.A(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__clkinv_2 clkload1 (.A(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[0]$_SDFF_PP0_  (.D(_024_),
    .Q(net10),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[1]$_SDFF_PP0_  (.D(_023_),
    .Q(net11),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[2]$_SDFF_PP0_  (.D(_022_),
    .Q(net12),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[3]$_SDFF_PP0_  (.D(_021_),
    .Q(net13),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[4]$_SDFF_PP0_  (.D(_020_),
    .Q(net14),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[5]$_SDFF_PP0_  (.D(_019_),
    .Q(net15),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[6]$_SDFF_PP0_  (.D(_018_),
    .Q(net16),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \data_out[7]$_SDFF_PP0_  (.D(_046_),
    .Q(net17),
    .CLK(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input1 (.A(data_in[0]),
    .X(net1));
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
 sky130_fd_sc_hd__clkdlybuf4s50_1 output10 (.A(net10),
    .X(data_out[0]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output11 (.A(net11),
    .X(data_out[1]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output12 (.A(net12),
    .X(data_out[2]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output13 (.A(net13),
    .X(data_out[3]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output14 (.A(net14),
    .X(data_out[4]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output15 (.A(net15),
    .X(data_out[5]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output16 (.A(net16),
    .X(data_out[6]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output17 (.A(net17),
    .X(data_out[7]));
 sky130_fd_sc_hd__buf_4 place25 (.A(_081_),
    .X(net25));
 sky130_fd_sc_hd__buf_4 place27 (.A(_057_),
    .X(net27));
 sky130_fd_sc_hd__buf_4 place28 (.A(_017_),
    .X(net28));
 sky130_fd_sc_hd__buf_4 place29 (.A(_016_),
    .X(net29));
 sky130_fd_sc_hd__buf_4 place30 (.A(_015_),
    .X(net30));
 sky130_fd_sc_hd__buf_4 place31 (.A(_009_),
    .X(net31));
 sky130_fd_sc_hd__buf_4 place32 (.A(_005_),
    .X(net32));
 sky130_fd_sc_hd__buf_4 place33 (.A(net9),
    .X(net33));
 sky130_fd_sc_hd__buf_4 rebuffer34 (.A(net39),
    .X(net34));
 sky130_fd_sc_hd__buf_4 rebuffer39 (.A(_002_),
    .X(net39));
 sky130_fd_sc_hd__buf_6 rebuffer40 (.A(net45),
    .X(net40));
 sky130_fd_sc_hd__buf_4 rebuffer44 (.A(\s0[1] ),
    .X(net44));
 sky130_fd_sc_hd__buf_4 rebuffer45 (.A(_001_),
    .X(net45));
 sky130_fd_sc_hd__dfxtp_1 \s0[0]$_SDFF_PP0_  (.D(_031_),
    .Q(\s0[0] ),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_2 \s0[1]$_SDFF_PP0_  (.D(_030_),
    .Q(\s0[1] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s0[2]$_SDFF_PP0_  (.D(_029_),
    .Q(\s0[2] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s0[3]$_SDFF_PP0_  (.D(_028_),
    .Q(\s0[3] ),
    .CLK(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s0[4]$_SDFF_PP0_  (.D(_027_),
    .Q(\s0[4] ),
    .CLK(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s0[5]$_SDFF_PP0_  (.D(_026_),
    .Q(\s0[5] ),
    .CLK(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s0[6]$_SDFF_PP0_  (.D(_025_),
    .Q(\s0[6] ),
    .CLK(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s0[7]$_SDFF_PP0_  (.D(_047_),
    .Q(\s0[7] ),
    .CLK(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s1[0]$_SDFF_PP0_  (.D(_038_),
    .Q(\s1[0] ),
    .CLK(clknet_2_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_2 \s1[1]$_SDFF_PP0_  (.D(_037_),
    .Q(\s1[1] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s1[2]$_SDFF_PP0_  (.D(_036_),
    .Q(\s1[2] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s1[3]$_SDFF_PP0_  (.D(_035_),
    .Q(\s1[3] ),
    .CLK(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s1[4]$_SDFF_PP0_  (.D(_034_),
    .Q(\s1[4] ),
    .CLK(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s1[5]$_SDFF_PP0_  (.D(_033_),
    .Q(\s1[5] ),
    .CLK(clknet_2_2__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s1[6]$_SDFF_PP0_  (.D(_032_),
    .Q(\s1[6] ),
    .CLK(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s1[7]$_SDFF_PP0_  (.D(_048_),
    .Q(\s1[7] ),
    .CLK(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[0]$_SDFF_PP0_  (.D(_045_),
    .Q(\s2[0] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[1]$_SDFF_PP0_  (.D(_044_),
    .Q(\s2[1] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[2]$_SDFF_PP0_  (.D(_043_),
    .Q(\s2[2] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[3]$_SDFF_PP0_  (.D(_042_),
    .Q(\s2[3] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[4]$_SDFF_PP0_  (.D(_041_),
    .Q(\s2[4] ),
    .CLK(clknet_2_3__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[5]$_SDFF_PP0_  (.D(_040_),
    .Q(\s2[5] ),
    .CLK(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[6]$_SDFF_PP0_  (.D(_039_),
    .Q(\s2[6] ),
    .CLK(clknet_2_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \s2[7]$_SDFF_PP0_  (.D(_049_),
    .Q(\s2[7] ),
    .CLK(clknet_2_0__leaf_clk));
endmodule
