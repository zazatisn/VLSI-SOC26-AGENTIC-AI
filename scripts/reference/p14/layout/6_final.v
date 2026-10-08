module alu_8bit (carry,
    clk,
    reset,
    zero,
    a,
    b,
    op,
    result);
 output carry;
 input clk;
 input reset;
 output zero;
 input [7:0] a;
 input [7:0] b;
 input [2:0] op;
 output [7:0] result;

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
 wire _050_;
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
 wire _078_;
 wire _079_;
 wire _080_;
 wire _081_;
 wire _082_;
 wire _083_;
 wire _084_;
 wire _085_;
 wire _086_;
 wire _089_;
 wire _090_;
 wire _092_;
 wire _093_;
 wire _094_;
 wire _095_;
 wire _096_;
 wire _097_;
 wire _098_;
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
 wire _115_;
 wire _116_;
 wire _117_;
 wire _118_;
 wire _119_;
 wire _120_;
 wire _121_;
 wire _122_;
 wire _123_;
 wire _124_;
 wire _125_;
 wire _126_;
 wire _127_;
 wire _128_;
 wire _129_;
 wire _130_;
 wire _131_;
 wire _132_;
 wire _133_;
 wire _134_;
 wire _135_;
 wire _136_;
 wire _137_;
 wire _138_;
 wire _139_;
 wire _140_;
 wire _141_;
 wire _142_;
 wire _143_;
 wire _144_;
 wire _145_;
 wire _146_;
 wire _147_;
 wire _148_;
 wire _149_;
 wire _150_;
 wire _151_;
 wire _152_;
 wire _153_;
 wire _154_;
 wire _155_;
 wire _156_;
 wire _157_;
 wire _158_;
 wire _159_;
 wire _160_;
 wire _161_;
 wire _162_;
 wire _163_;
 wire _164_;
 wire _165_;
 wire _166_;
 wire _167_;
 wire _168_;
 wire _169_;
 wire _170_;
 wire _171_;
 wire _172_;
 wire _173_;
 wire _174_;
 wire _175_;
 wire _176_;
 wire _177_;
 wire _178_;
 wire _179_;
 wire _180_;
 wire _181_;
 wire _182_;
 wire _183_;
 wire _184_;
 wire _185_;
 wire _186_;
 wire _187_;
 wire _188_;
 wire _189_;
 wire _190_;
 wire _191_;
 wire _192_;
 wire _193_;
 wire _197_;
 wire _199_;
 wire _205_;
 wire _206_;
 wire _208_;
 wire _209_;
 wire _210_;
 wire _211_;
 wire _212_;
 wire _213_;
 wire _214_;
 wire _215_;
 wire _216_;
 wire _217_;
 wire _218_;
 wire _219_;
 wire _220_;
 wire _221_;
 wire _222_;
 wire _223_;
 wire _224_;
 wire _225_;
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
 wire net21;
 wire net17;
 wire net18;
 wire net19;
 wire net20;
 wire net22;
 wire net23;
 wire net24;
 wire net25;
 wire net26;
 wire net27;
 wire net28;
 wire net29;
 wire net30;
 wire net50;
 wire net49;
 wire net54;
 wire net55;
 wire net57;
 wire net56;
 wire net59;
 wire net60;
 wire net61;
 wire net62;
 wire net63;
 wire net67;
 wire net66;
 wire net68;
 wire net70;
 wire net69;
 wire net47;
 wire net48;
 wire net51;
 wire net52;
 wire net53;
 wire net58;
 wire net64;
 wire net65;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 sky130_fd_sc_hd__inv_1 _226_ (.A(net12),
    .Y(_015_));
 sky130_fd_sc_hd__nand2b_1 _229_ (.A_N(net62),
    .B(net63),
    .Y(_144_));
 sky130_fd_sc_hd__nand3b_1 _230_ (.A_N(net63),
    .B(net62),
    .C(net59),
    .Y(_145_));
 sky130_fd_sc_hd__o211a_1 _231_ (.A1(_010_),
    .A2(_144_),
    .B1(_145_),
    .C1(net17),
    .X(_146_));
 sky130_fd_sc_hd__a21oi_1 _232_ (.A1(_117_),
    .A2(_112_),
    .B1(_018_),
    .Y(_147_));
 sky130_fd_sc_hd__a221oi_1 _233_ (.A1(_140_),
    .A2(_143_),
    .B1(_146_),
    .B2(_147_),
    .C1(_118_),
    .Y(_148_));
 sky130_fd_sc_hd__nor2b_1 _234_ (.A(_147_),
    .B_N(_146_),
    .Y(_149_));
 sky130_fd_sc_hd__a311oi_1 _235_ (.A1(_138_),
    .A2(_139_),
    .A3(_143_),
    .B1(_149_),
    .C1(_011_),
    .Y(_150_));
 sky130_fd_sc_hd__o21ai_0 _236_ (.A1(_143_),
    .A2(_146_),
    .B1(_197_),
    .Y(_151_));
 sky130_fd_sc_hd__o21ai_0 _237_ (.A1(_148_),
    .A2(_150_),
    .B1(_151_),
    .Y(_152_));
 sky130_fd_sc_hd__inv_1 _238_ (.A(_079_),
    .Y(_153_));
 sky130_fd_sc_hd__a21oi_1 _240_ (.A1(_069_),
    .A2(_070_),
    .B1(_050_),
    .Y(_154_));
 sky130_fd_sc_hd__xnor2_1 _241_ (.A(_117_),
    .B(_154_),
    .Y(_155_));
 sky130_fd_sc_hd__nor2_1 _242_ (.A(net54),
    .B(net62),
    .Y(_156_));
 sky130_fd_sc_hd__a21oi_1 _243_ (.A1(net49),
    .A2(_208_),
    .B1(_051_),
    .Y(_157_));
 sky130_fd_sc_hd__mux2_2 _244_ (.A0(_156_),
    .A1(net54),
    .S(_157_),
    .X(_158_));
 sky130_fd_sc_hd__nor2_1 _245_ (.A(net63),
    .B(net17),
    .Y(_159_));
 sky130_fd_sc_hd__nor2b_1 _246_ (.A(_016_),
    .B_N(net17),
    .Y(_160_));
 sky130_fd_sc_hd__a21oi_1 _247_ (.A1(_019_),
    .A2(_078_),
    .B1(_160_),
    .Y(_161_));
 sky130_fd_sc_hd__nor2b_1 _248_ (.A(net17),
    .B_N(net18),
    .Y(_162_));
 sky130_fd_sc_hd__a222oi_1 _249_ (.A1(net60),
    .A2(_085_),
    .B1(_162_),
    .B2(net58),
    .C1(_159_),
    .C2(net54),
    .Y(_163_));
 sky130_fd_sc_hd__nand3_1 _250_ (.A(net54),
    .B(_011_),
    .C(_051_),
    .Y(_205_));
 sky130_fd_sc_hd__o22ai_1 _251_ (.A1(_144_),
    .A2(_161_),
    .B1(_163_),
    .B2(_093_),
    .Y(_164_));
 sky130_fd_sc_hd__a221oi_4 _252_ (.A1(_153_),
    .A2(_155_),
    .B1(_158_),
    .B2(_159_),
    .C1(_164_),
    .Y(_165_));
 sky130_fd_sc_hd__nor2b_1 _253_ (.A(net62),
    .B_N(_006_),
    .Y(_166_));
 sky130_fd_sc_hd__xnor2_1 _254_ (.A(net49),
    .B(_166_),
    .Y(_167_));
 sky130_fd_sc_hd__mux2i_1 _255_ (.A0(_051_),
    .A1(net59),
    .S(net62),
    .Y(_168_));
 sky130_fd_sc_hd__mux2i_1 _256_ (.A0(_167_),
    .A1(_168_),
    .S(net63),
    .Y(_169_));
 sky130_fd_sc_hd__inv_1 _257_ (.A(net2),
    .Y(_000_));
 sky130_fd_sc_hd__xor2_1 _258_ (.A(net50),
    .B(_002_),
    .X(_170_));
 sky130_fd_sc_hd__a21oi_1 _259_ (.A1(_048_),
    .A2(net65),
    .B1(net62),
    .Y(_171_));
 sky130_fd_sc_hd__o21ai_0 _260_ (.A1(net65),
    .A2(_170_),
    .B1(_171_),
    .Y(_172_));
 sky130_fd_sc_hd__a21oi_1 _261_ (.A1(_011_),
    .A2(_019_),
    .B1(_013_),
    .Y(_206_));
 sky130_fd_sc_hd__o311ai_0 _262_ (.A1(_000_),
    .A2(_093_),
    .A3(net65),
    .B1(net66),
    .C1(_172_),
    .Y(_173_));
 sky130_fd_sc_hd__o21ai_0 _263_ (.A1(net66),
    .A2(_169_),
    .B1(_173_),
    .Y(_174_));
 sky130_fd_sc_hd__inv_1 _264_ (.A(net3),
    .Y(_046_));
 sky130_fd_sc_hd__nand2_1 _265_ (.A(net66),
    .B(_027_),
    .Y(_175_));
 sky130_fd_sc_hd__o211ai_1 _266_ (.A1(_029_),
    .A2(net66),
    .B1(_175_),
    .C1(_093_),
    .Y(_176_));
 sky130_fd_sc_hd__o31ai_1 _267_ (.A1(_046_),
    .A2(_093_),
    .A3(net66),
    .B1(_176_),
    .Y(_177_));
 sky130_fd_sc_hd__mux2i_1 _268_ (.A0(net53),
    .A1(net70),
    .S(net66),
    .Y(_178_));
 sky130_fd_sc_hd__nor3_1 _269_ (.A(_093_),
    .B(net65),
    .C(_178_),
    .Y(_179_));
 sky130_fd_sc_hd__nor2_1 _270_ (.A(_007_),
    .B(net66),
    .Y(_180_));
 sky130_fd_sc_hd__a211oi_1 _271_ (.A1(net66),
    .A2(_003_),
    .B1(_197_),
    .C1(_180_),
    .Y(_181_));
 sky130_fd_sc_hd__a211oi_1 _273_ (.A1(net65),
    .A2(_177_),
    .B1(_179_),
    .C1(_181_),
    .Y(_182_));
 sky130_fd_sc_hd__and4b_1 _274_ (.A_N(net20),
    .B(_165_),
    .C(_174_),
    .D(_182_),
    .X(_183_));
 sky130_fd_sc_hd__nand4_1 _275_ (.A(_132_),
    .B(_137_),
    .C(net47),
    .D(_183_),
    .Y(_184_));
 sky130_fd_sc_hd__nor4_1 _276_ (.A(_098_),
    .B(_109_),
    .C(_128_),
    .D(_184_),
    .Y(_060_));
 sky130_fd_sc_hd__a22o_1 _277_ (.A1(net8),
    .A2(_085_),
    .B1(_162_),
    .B2(net69),
    .X(_185_));
 sky130_fd_sc_hd__nand3b_1 _278_ (.A_N(_025_),
    .B(net66),
    .C(_024_),
    .Y(_186_));
 sky130_fd_sc_hd__a21oi_1 _279_ (.A1(_089_),
    .A2(_186_),
    .B1(_197_),
    .Y(_187_));
 sky130_fd_sc_hd__a21oi_1 _280_ (.A1(net62),
    .A2(_185_),
    .B1(_187_),
    .Y(_188_));
 sky130_fd_sc_hd__o21ai_0 _281_ (.A1(net52),
    .A2(_113_),
    .B1(_082_),
    .Y(_189_));
 sky130_fd_sc_hd__a2111o_1 _282_ (.A1(_073_),
    .A2(_189_),
    .B1(_079_),
    .C1(_025_),
    .D1(_044_),
    .X(_190_));
 sky130_fd_sc_hd__a21o_1 _283_ (.A1(net55),
    .A2(_020_),
    .B1(_029_),
    .X(_208_));
 sky130_fd_sc_hd__a21oi_1 _284_ (.A1(net52),
    .A2(_120_),
    .B1(_039_),
    .Y(_191_));
 sky130_fd_sc_hd__nor2_1 _285_ (.A(_073_),
    .B(_191_),
    .Y(_192_));
 sky130_fd_sc_hd__o211ai_1 _286_ (.A1(_045_),
    .A2(_192_),
    .B1(_199_),
    .C1(_024_),
    .Y(_193_));
 sky130_fd_sc_hd__a31oi_1 _287_ (.A1(_188_),
    .A2(_190_),
    .A3(_193_),
    .B1(net20),
    .Y(_059_));
 sky130_fd_sc_hd__inv_1 _288_ (.A(net1),
    .Y(_030_));
 sky130_fd_sc_hd__inv_1 _289_ (.A(net9),
    .Y(_031_));
 sky130_fd_sc_hd__inv_1 _290_ (.A(net14),
    .Y(_035_));
 sky130_fd_sc_hd__a21oi_1 _291_ (.A1(_132_),
    .A2(_137_),
    .B1(net20),
    .Y(_058_));
 sky130_fd_sc_hd__nor2_1 _292_ (.A(net20),
    .B(_182_),
    .Y(_057_));
 sky130_fd_sc_hd__nor2_1 _293_ (.A(net20),
    .B(net48),
    .Y(_056_));
 sky130_fd_sc_hd__nand4_1 _294_ (.A(net49),
    .B(net54),
    .C(_011_),
    .D(_208_),
    .Y(_209_));
 sky130_fd_sc_hd__nor2_1 _295_ (.A(net20),
    .B(_165_),
    .Y(_055_));
 sky130_fd_sc_hd__nor2_1 _296_ (.A(net20),
    .B(net47),
    .Y(_054_));
 sky130_fd_sc_hd__nor2b_1 _297_ (.A(net20),
    .B_N(_109_),
    .Y(_053_));
 sky130_fd_sc_hd__nor2b_1 _298_ (.A(net20),
    .B_N(_128_),
    .Y(_052_));
 sky130_fd_sc_hd__inv_1 _299_ (.A(net4),
    .Y(_014_));
 sky130_fd_sc_hd__inv_1 _300_ (.A(net6),
    .Y(_034_));
 sky130_fd_sc_hd__inv_1 _301_ (.A(net16),
    .Y(_022_));
 sky130_fd_sc_hd__inv_1 _302_ (.A(net8),
    .Y(_021_));
 sky130_fd_sc_hd__inv_1 _303_ (.A(net13),
    .Y(_009_));
 sky130_fd_sc_hd__inv_1 _304_ (.A(net5),
    .Y(_008_));
 sky130_fd_sc_hd__nand3_1 _305_ (.A(_205_),
    .B(_206_),
    .C(_209_),
    .Y(_062_));
 sky130_fd_sc_hd__inv_1 _306_ (.A(net7),
    .Y(_040_));
 sky130_fd_sc_hd__inv_1 _307_ (.A(net11),
    .Y(_047_));
 sky130_fd_sc_hd__inv_1 _308_ (.A(net15),
    .Y(_041_));
 sky130_fd_sc_hd__inv_1 _309_ (.A(net10),
    .Y(_004_));
 sky130_fd_sc_hd__a21o_1 _310_ (.A1(_039_),
    .A2(net51),
    .B1(_045_),
    .X(_063_));
 sky130_fd_sc_hd__a31oi_1 _311_ (.A1(net52),
    .A2(net51),
    .A3(_062_),
    .B1(_063_),
    .Y(_064_));
 sky130_fd_sc_hd__xnor2_1 _313_ (.A(_024_),
    .B(_064_),
    .Y(_065_));
 sky130_fd_sc_hd__nor2_2 _314_ (.A(_017_),
    .B(_011_),
    .Y(_066_));
 sky130_fd_sc_hd__nor2b_1 _315_ (.A(_011_),
    .B_N(_018_),
    .Y(_067_));
 sky130_fd_sc_hd__a211o_1 _316_ (.A1(_050_),
    .A2(_066_),
    .B1(_067_),
    .C1(_012_),
    .X(_068_));
 sky130_fd_sc_hd__inv_1 _317_ (.A(net49),
    .Y(_069_));
 sky130_fd_sc_hd__o21bai_1 _318_ (.A1(net53),
    .A2(_001_),
    .B1_N(_028_),
    .Y(_070_));
 sky130_fd_sc_hd__and3_1 _319_ (.A(_069_),
    .B(_066_),
    .C(_070_),
    .X(_071_));
 sky130_fd_sc_hd__or2_4 _320_ (.A(_068_),
    .B(_071_),
    .X(_072_));
 sky130_fd_sc_hd__inv_2 _321_ (.A(_043_),
    .Y(_073_));
 sky130_fd_sc_hd__a21o_1 _322_ (.A1(_073_),
    .A2(_038_),
    .B1(_044_),
    .X(_074_));
 sky130_fd_sc_hd__or3_1 _324_ (.A(_024_),
    .B(_072_),
    .C(_074_),
    .X(_075_));
 sky130_fd_sc_hd__nor2_1 _325_ (.A(net52),
    .B(net51),
    .Y(_076_));
 sky130_fd_sc_hd__nand3_2 _326_ (.A(_024_),
    .B(_072_),
    .C(_076_),
    .Y(_077_));
 sky130_fd_sc_hd__inv_1 _327_ (.A(net17),
    .Y(_078_));
 sky130_fd_sc_hd__or2_2 _328_ (.A(_078_),
    .B(_197_),
    .X(_079_));
 sky130_fd_sc_hd__a21oi_1 _329_ (.A1(_075_),
    .A2(_077_),
    .B1(_079_),
    .Y(_080_));
 sky130_fd_sc_hd__and2_0 _330_ (.A(_024_),
    .B(_074_),
    .X(_081_));
 sky130_fd_sc_hd__inv_1 _331_ (.A(_038_),
    .Y(_082_));
 sky130_fd_sc_hd__a21oi_1 _332_ (.A1(net52),
    .A2(_082_),
    .B1(_043_),
    .Y(_083_));
 sky130_fd_sc_hd__nor3_1 _333_ (.A(_024_),
    .B(_044_),
    .C(_083_),
    .Y(_084_));
 sky130_fd_sc_hd__or2_1 _334_ (.A(net19),
    .B(net18),
    .X(_197_));
 sky130_fd_sc_hd__nor2b_1 _335_ (.A(net18),
    .B_N(net17),
    .Y(_085_));
 sky130_fd_sc_hd__o21ai_0 _336_ (.A1(_081_),
    .A2(_084_),
    .B1(_085_),
    .Y(_086_));
 sky130_fd_sc_hd__nand2_1 _339_ (.A(_026_),
    .B(_078_),
    .Y(_089_));
 sky130_fd_sc_hd__o21ai_0 _340_ (.A1(_078_),
    .A2(_023_),
    .B1(_089_),
    .Y(_090_));
 sky130_fd_sc_hd__a21oi_1 _342_ (.A1(net65),
    .A2(_090_),
    .B1(net62),
    .Y(_092_));
 sky130_fd_sc_hd__inv_1 _343_ (.A(net19),
    .Y(_093_));
 sky130_fd_sc_hd__mux2i_1 _344_ (.A0(_024_),
    .A1(net57),
    .S(net66),
    .Y(_094_));
 sky130_fd_sc_hd__nor2_1 _346_ (.A(net65),
    .B(_094_),
    .Y(_095_));
 sky130_fd_sc_hd__nor2_1 _347_ (.A(_093_),
    .B(_095_),
    .Y(_096_));
 sky130_fd_sc_hd__a21oi_1 _348_ (.A1(_086_),
    .A2(_092_),
    .B1(_096_),
    .Y(_097_));
 sky130_fd_sc_hd__a211o_1 _349_ (.A1(_199_),
    .A2(_065_),
    .B1(_080_),
    .C1(_097_),
    .X(_098_));
 sky130_fd_sc_hd__and2b_1 _350_ (.A_N(net20),
    .B(_098_),
    .X(_061_));
 sky130_fd_sc_hd__nand2_1 _352_ (.A(net67),
    .B(_036_),
    .Y(_100_));
 sky130_fd_sc_hd__o211ai_1 _353_ (.A1(_039_),
    .A2(net67),
    .B1(_100_),
    .C1(net64),
    .Y(_101_));
 sky130_fd_sc_hd__o21ai_0 _354_ (.A1(_068_),
    .A2(_071_),
    .B1(net67),
    .Y(_102_));
 sky130_fd_sc_hd__o21ai_0 _355_ (.A1(net67),
    .A2(_062_),
    .B1(_102_),
    .Y(_103_));
 sky130_fd_sc_hd__nor2_1 _356_ (.A(net66),
    .B(_197_),
    .Y(_199_));
 sky130_fd_sc_hd__xor2_1 _357_ (.A(net52),
    .B(_103_),
    .X(_104_));
 sky130_fd_sc_hd__mux2i_1 _358_ (.A0(net52),
    .A1(net57),
    .S(net64),
    .Y(_105_));
 sky130_fd_sc_hd__nand2_1 _359_ (.A(net58),
    .B(_085_),
    .Y(_106_));
 sky130_fd_sc_hd__o21ai_0 _360_ (.A1(net67),
    .A2(_105_),
    .B1(_106_),
    .Y(_107_));
 sky130_fd_sc_hd__nand2_1 _361_ (.A(net62),
    .B(_107_),
    .Y(_108_));
 sky130_fd_sc_hd__o221ai_1 _362_ (.A1(net62),
    .A2(_101_),
    .B1(_104_),
    .B2(_197_),
    .C1(_108_),
    .Y(_109_));
 sky130_fd_sc_hd__nand2_1 _363_ (.A(net66),
    .B(_042_),
    .Y(_110_));
 sky130_fd_sc_hd__o211ai_1 _364_ (.A1(_045_),
    .A2(net66),
    .B1(_110_),
    .C1(net64),
    .Y(_111_));
 sky130_fd_sc_hd__o21bai_1 _365_ (.A1(_049_),
    .A2(_002_),
    .B1_N(_050_),
    .Y(_112_));
 sky130_fd_sc_hd__a211oi_1 _366_ (.A1(_066_),
    .A2(_112_),
    .B1(_012_),
    .C1(_067_),
    .Y(_113_));
 sky130_fd_sc_hd__nor3_1 _368_ (.A(net52),
    .B(_078_),
    .C(_113_),
    .Y(_114_));
 sky130_fd_sc_hd__or3_1 _369_ (.A(_037_),
    .B(_039_),
    .C(net67),
    .X(_115_));
 sky130_fd_sc_hd__o21ai_0 _370_ (.A1(_082_),
    .A2(_078_),
    .B1(_115_),
    .Y(_116_));
 sky130_fd_sc_hd__inv_1 _371_ (.A(_017_),
    .Y(_117_));
 sky130_fd_sc_hd__inv_1 _372_ (.A(_011_),
    .Y(_118_));
 sky130_fd_sc_hd__a21oi_1 _373_ (.A1(_049_),
    .A2(_006_),
    .B1(_051_),
    .Y(_119_));
 sky130_fd_sc_hd__o31ai_1 _374_ (.A1(_117_),
    .A2(_118_),
    .A3(_119_),
    .B1(_206_),
    .Y(_120_));
 sky130_fd_sc_hd__nor3_1 _375_ (.A(_039_),
    .B(net67),
    .C(_120_),
    .Y(_121_));
 sky130_fd_sc_hd__nor3_1 _376_ (.A(_114_),
    .B(_116_),
    .C(_121_),
    .Y(_122_));
 sky130_fd_sc_hd__xnor2_1 _377_ (.A(net51),
    .B(_122_),
    .Y(_123_));
 sky130_fd_sc_hd__mux2i_1 _379_ (.A0(net51),
    .A1(net8),
    .S(net64),
    .Y(_124_));
 sky130_fd_sc_hd__nand2_1 _380_ (.A(net6),
    .B(_085_),
    .Y(_125_));
 sky130_fd_sc_hd__o21ai_0 _381_ (.A1(net67),
    .A2(_124_),
    .B1(_125_),
    .Y(_126_));
 sky130_fd_sc_hd__nand2_1 _382_ (.A(net62),
    .B(_126_),
    .Y(_127_));
 sky130_fd_sc_hd__o221ai_1 _383_ (.A1(net62),
    .A2(_111_),
    .B1(_123_),
    .B2(_197_),
    .C1(_127_),
    .Y(_128_));
 sky130_fd_sc_hd__a21oi_1 _384_ (.A1(_072_),
    .A2(_076_),
    .B1(_074_),
    .Y(_129_));
 sky130_fd_sc_hd__nand2_1 _385_ (.A(net62),
    .B(net66),
    .Y(_130_));
 sky130_fd_sc_hd__nor3b_1 _386_ (.A(_130_),
    .B(_025_),
    .C_N(net65),
    .Y(_131_));
 sky130_fd_sc_hd__o21ai_0 _387_ (.A1(_024_),
    .A2(_129_),
    .B1(_131_),
    .Y(_132_));
 sky130_fd_sc_hd__mux2_2 _388_ (.A0(net55),
    .A1(net61),
    .S(net62),
    .X(_133_));
 sky130_fd_sc_hd__nand2_1 _390_ (.A(net66),
    .B(_032_),
    .Y(_134_));
 sky130_fd_sc_hd__o21ai_0 _391_ (.A1(net66),
    .A2(_133_),
    .B1(_134_),
    .Y(_135_));
 sky130_fd_sc_hd__nand2_1 _392_ (.A(net65),
    .B(_135_),
    .Y(_136_));
 sky130_fd_sc_hd__o211ai_1 _393_ (.A1(_033_),
    .A2(net65),
    .B1(_130_),
    .C1(_136_),
    .Y(_137_));
 sky130_fd_sc_hd__a21oi_1 _394_ (.A1(net54),
    .A2(_051_),
    .B1(_019_),
    .Y(_138_));
 sky130_fd_sc_hd__nand3_1 _395_ (.A(_049_),
    .B(net54),
    .C(_006_),
    .Y(_139_));
 sky130_fd_sc_hd__nand2_1 _396_ (.A(_138_),
    .B(_139_),
    .Y(_140_));
 sky130_fd_sc_hd__mux2i_1 _397_ (.A0(_011_),
    .A1(net6),
    .S(net18),
    .Y(_141_));
 sky130_fd_sc_hd__nor2_1 _398_ (.A(_093_),
    .B(_141_),
    .Y(_142_));
 sky130_fd_sc_hd__a311oi_2 _399_ (.A1(_013_),
    .A2(_093_),
    .A3(net18),
    .B1(net67),
    .C1(_142_),
    .Y(_143_));
 sky130_fd_sc_hd__fa_1 _400_ (.A(_000_),
    .B(net68),
    .CIN(_001_),
    .COUT(_002_),
    .SUM(_003_));
 sky130_fd_sc_hd__fa_1 _401_ (.A(net61),
    .B(net68),
    .CIN(_005_),
    .COUT(_006_),
    .SUM(_007_));
 sky130_fd_sc_hd__ha_1 _402_ (.A(_008_),
    .B(_009_),
    .COUT(_010_),
    .SUM(_011_));
 sky130_fd_sc_hd__ha_1 _403_ (.A(net58),
    .B(_009_),
    .COUT(_012_),
    .SUM(_210_));
 sky130_fd_sc_hd__ha_1 _404_ (.A(net58),
    .B(net13),
    .COUT(_013_),
    .SUM(_211_));
 sky130_fd_sc_hd__ha_1 _405_ (.A(_014_),
    .B(_015_),
    .COUT(_016_),
    .SUM(_017_));
 sky130_fd_sc_hd__ha_1 _406_ (.A(net59),
    .B(_015_),
    .COUT(_018_),
    .SUM(_212_));
 sky130_fd_sc_hd__ha_1 _407_ (.A(net59),
    .B(net12),
    .COUT(_019_),
    .SUM(_213_));
 sky130_fd_sc_hd__ha_1 _408_ (.A(_021_),
    .B(_022_),
    .COUT(_023_),
    .SUM(_024_));
 sky130_fd_sc_hd__ha_1 _409_ (.A(net8),
    .B(_022_),
    .COUT(_025_),
    .SUM(_214_));
 sky130_fd_sc_hd__ha_1 _410_ (.A(net8),
    .B(net16),
    .COUT(_026_),
    .SUM(_215_));
 sky130_fd_sc_hd__ha_1 _411_ (.A(_000_),
    .B(_004_),
    .COUT(_027_),
    .SUM(_020_));
 sky130_fd_sc_hd__ha_1 _412_ (.A(net61),
    .B(_004_),
    .COUT(_028_),
    .SUM(_216_));
 sky130_fd_sc_hd__ha_1 _413_ (.A(net61),
    .B(net68),
    .COUT(_029_),
    .SUM(_217_));
 sky130_fd_sc_hd__ha_1 _414_ (.A(net56),
    .B(_031_),
    .COUT(_032_),
    .SUM(_033_));
 sky130_fd_sc_hd__ha_1 _415_ (.A(_030_),
    .B(net9),
    .COUT(_001_),
    .SUM(_218_));
 sky130_fd_sc_hd__ha_1 _416_ (.A(net1),
    .B(net9),
    .COUT(_005_),
    .SUM(_219_));
 sky130_fd_sc_hd__ha_1 _417_ (.A(_034_),
    .B(_035_),
    .COUT(_036_),
    .SUM(_037_));
 sky130_fd_sc_hd__ha_1 _418_ (.A(net6),
    .B(_035_),
    .COUT(_038_),
    .SUM(_220_));
 sky130_fd_sc_hd__ha_1 _419_ (.A(net6),
    .B(net14),
    .COUT(_039_),
    .SUM(_221_));
 sky130_fd_sc_hd__ha_1 _420_ (.A(_040_),
    .B(_041_),
    .COUT(_042_),
    .SUM(_043_));
 sky130_fd_sc_hd__ha_1 _421_ (.A(net57),
    .B(_041_),
    .COUT(_044_),
    .SUM(_222_));
 sky130_fd_sc_hd__ha_1 _422_ (.A(net57),
    .B(net15),
    .COUT(_045_),
    .SUM(_223_));
 sky130_fd_sc_hd__ha_1 _423_ (.A(_046_),
    .B(_047_),
    .COUT(_048_),
    .SUM(_049_));
 sky130_fd_sc_hd__ha_1 _424_ (.A(net60),
    .B(_047_),
    .COUT(_050_),
    .SUM(_224_));
 sky130_fd_sc_hd__ha_1 _425_ (.A(net60),
    .B(net11),
    .COUT(_051_),
    .SUM(_225_));
 sky130_fd_sc_hd__dfxtp_1 \carry$_SDFF_PP0_  (.D(_059_),
    .Q(net21),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .X(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .X(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__clkbuf_8 clkload0 (.A(clknet_1_0__leaf_clk));
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
 sky130_fd_sc_hd__clkdlybuf4s50_1 input17 (.A(op[0]),
    .X(net17));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input18 (.A(op[1]),
    .X(net18));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input19 (.A(op[2]),
    .X(net19));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input2 (.A(a[1]),
    .X(net2));
 sky130_fd_sc_hd__clkdlybuf4s50_1 input20 (.A(reset),
    .X(net20));
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
 sky130_fd_sc_hd__clkdlybuf4s50_1 output21 (.A(net21),
    .X(carry));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output22 (.A(net22),
    .X(result[0]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output23 (.A(net23),
    .X(result[1]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output24 (.A(net24),
    .X(result[2]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output25 (.A(net25),
    .X(result[3]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output26 (.A(net26),
    .X(result[4]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output27 (.A(net27),
    .X(result[5]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output28 (.A(net28),
    .X(result[6]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output29 (.A(net29),
    .X(result[7]));
 sky130_fd_sc_hd__clkdlybuf4s50_1 output30 (.A(net30),
    .X(zero));
 sky130_fd_sc_hd__buf_4 place47 (.A(_152_),
    .X(net47));
 sky130_fd_sc_hd__buf_4 place48 (.A(_174_),
    .X(net48));
 sky130_fd_sc_hd__buf_4 place49 (.A(_049_),
    .X(net49));
 sky130_fd_sc_hd__buf_4 place50 (.A(_049_),
    .X(net50));
 sky130_fd_sc_hd__buf_4 place51 (.A(_043_),
    .X(net51));
 sky130_fd_sc_hd__buf_4 place52 (.A(_037_),
    .X(net52));
 sky130_fd_sc_hd__buf_4 place53 (.A(_020_),
    .X(net53));
 sky130_fd_sc_hd__buf_4 place54 (.A(_017_),
    .X(net54));
 sky130_fd_sc_hd__buf_4 place55 (.A(_005_),
    .X(net55));
 sky130_fd_sc_hd__buf_4 place56 (.A(_030_),
    .X(net56));
 sky130_fd_sc_hd__buf_4 place57 (.A(net7),
    .X(net57));
 sky130_fd_sc_hd__buf_4 place58 (.A(net5),
    .X(net58));
 sky130_fd_sc_hd__buf_4 place59 (.A(net4),
    .X(net59));
 sky130_fd_sc_hd__buf_4 place60 (.A(net3),
    .X(net60));
 sky130_fd_sc_hd__buf_4 place61 (.A(net2),
    .X(net61));
 sky130_fd_sc_hd__buf_4 place62 (.A(net19),
    .X(net62));
 sky130_fd_sc_hd__buf_4 place63 (.A(net18),
    .X(net63));
 sky130_fd_sc_hd__buf_4 place64 (.A(net18),
    .X(net64));
 sky130_fd_sc_hd__buf_4 place65 (.A(net18),
    .X(net65));
 sky130_fd_sc_hd__buf_4 place66 (.A(net17),
    .X(net66));
 sky130_fd_sc_hd__buf_4 place67 (.A(net17),
    .X(net67));
 sky130_fd_sc_hd__buf_4 place68 (.A(net10),
    .X(net68));
 sky130_fd_sc_hd__buf_4 place69 (.A(net1),
    .X(net69));
 sky130_fd_sc_hd__buf_4 place70 (.A(net1),
    .X(net70));
 sky130_fd_sc_hd__dfxtp_1 \result[0]$_SDFF_PP0_  (.D(_058_),
    .Q(net22),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \result[1]$_SDFF_PP0_  (.D(_057_),
    .Q(net23),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \result[2]$_SDFF_PP0_  (.D(_056_),
    .Q(net24),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \result[3]$_SDFF_PP0_  (.D(_055_),
    .Q(net25),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \result[4]$_SDFF_PP0_  (.D(_054_),
    .Q(net26),
    .CLK(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \result[5]$_SDFF_PP0_  (.D(_053_),
    .Q(net27),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \result[6]$_SDFF_PP0_  (.D(_052_),
    .Q(net28),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \result[7]$_SDFF_PP0_  (.D(_061_),
    .Q(net29),
    .CLK(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__dfxtp_1 \zero$_SDFF_PP0_  (.D(_060_),
    .Q(net30),
    .CLK(clknet_1_1__leaf_clk));
endmodule
