// Golden RTL of p18 (rv32i_core): single-cycle RV32I core (no CSR / FENCE / ECALL / EBREAK).
// Instruction and data memories are outside the core (combinational read, written at the edge).
// The registered retire port reports every executed instruction (in the style of RVFI).
`timescale 1ns/1ps
module rv32i_core #(
    parameter RESET_PC = 32'h00000000
) (
    input             clk,
    input             reset,
    output     [31:0] imem_addr,
    input      [31:0] imem_rdata,
    output     [31:0] dmem_addr,
    output            dmem_re,
    output     [3:0]  dmem_wstrb,
    output     [31:0] dmem_wdata,
    input      [31:0] dmem_rdata,
    output reg        retire_valid,
    output reg [31:0] retire_pc,
    output reg [31:0] retire_insn,
    output reg [4:0]  retire_rd,
    output reg [31:0] retire_rd_wdata,
    output reg [31:0] retire_mem_addr,
    output reg [3:0]  retire_mem_wstrb,
    output reg [31:0] retire_mem_wdata
);
    reg [31:0] pc;
    reg [31:0] x [1:31];

    wire [31:0] insn   = imem_rdata;
    wire [6:0]  opcode = insn[6:0];
    wire [4:0]  rd     = insn[11:7];
    wire [2:0]  funct3 = insn[14:12];
    wire [4:0]  rs1    = insn[19:15];
    wire [4:0]  rs2    = insn[24:20];
    wire        f7b5   = insn[30];

    wire [31:0] imm_i = {{20{insn[31]}}, insn[31:20]};
    wire [31:0] imm_s = {{20{insn[31]}}, insn[31:25], insn[11:7]};
    wire [31:0] imm_b = {{19{insn[31]}}, insn[31], insn[7], insn[30:25], insn[11:8], 1'b0};
    wire [31:0] imm_u = {insn[31:12], 12'b0};
    wire [31:0] imm_j = {{11{insn[31]}}, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};

    wire [31:0] a = (rs1 == 5'd0) ? 32'd0 : x[rs1];
    wire [31:0] b = (rs2 == 5'd0) ? 32'd0 : x[rs2];

    localparam OP_LUI = 7'b0110111, OP_AUIPC = 7'b0010111, OP_JAL = 7'b1101111, OP_JALR = 7'b1100111,
               OP_BR  = 7'b1100011, OP_LOAD  = 7'b0000011, OP_STORE = 7'b0100011,
               OP_IMM = 7'b0010011, OP_REG   = 7'b0110011;

    // ALU (register-immediate and register-register)
    wire        is_reg = (opcode == OP_REG);
    wire [31:0] op2    = is_reg ? b : imm_i;
    wire [4:0]  shamt  = op2[4:0];
    reg  [31:0] alu;
    always @(*) begin
        case (funct3)
            3'b000: alu = (is_reg && f7b5) ? a - op2 : a + op2;
            3'b001: alu = a << shamt;
            3'b010: alu = ($signed(a) < $signed(op2)) ? 32'd1 : 32'd0;
            3'b011: alu = (a < op2) ? 32'd1 : 32'd0;
            3'b100: alu = a ^ op2;
            3'b101: if (f7b5) alu = $signed(a) >>> shamt;   // not in a ?: (that would make it unsigned)
                    else      alu = a >> shamt;
            3'b110: alu = a | op2;
            default: alu = a & op2;
        endcase
    end

    // branches
    reg take;
    always @(*) begin
        case (funct3)
            3'b000: take = (a == b);
            3'b001: take = (a != b);
            3'b100: take = ($signed(a) < $signed(b));
            3'b101: take = ($signed(a) >= $signed(b));
            3'b110: take = (a < b);
            3'b111: take = (a >= b);
            default: take = 1'b0;
        endcase
    end

    // memory
    wire        is_load  = (opcode == OP_LOAD);
    wire        is_store = (opcode == OP_STORE);
    wire [31:0] ea       = a + (is_store ? imm_s : imm_i);
    wire [1:0]  off      = ea[1:0];
    assign dmem_addr  = (is_load || is_store) ? {ea[31:2], 2'b00} : 32'd0;
    assign dmem_re    = is_load && !reset;
    reg  [3:0]  wstrb;
    always @(*) begin
        case (funct3[1:0])
            2'b00:   wstrb = 4'b0001 << off;
            2'b01:   wstrb = off[1] ? 4'b1100 : 4'b0011;
            default: wstrb = 4'b1111;
        endcase
    end
    assign dmem_wstrb = (is_store && !reset) ? wstrb : 4'b0000;
    assign dmem_wdata = is_store ? (funct3[1:0] == 2'b00 ? {4{b[7:0]}} :
                                    funct3[1:0] == 2'b01 ? {2{b[15:0]}} : b) : 32'd0;
    wire [31:0] lshift = dmem_rdata >> {off, 3'b000};
    reg  [31:0] load_val;
    always @(*) begin
        case (funct3)
            3'b000:  load_val = {{24{lshift[7]}}, lshift[7:0]};
            3'b001:  load_val = {{16{lshift[15]}}, lshift[15:0]};
            3'b100:  load_val = {24'd0, lshift[7:0]};
            3'b101:  load_val = {16'd0, lshift[15:0]};
            default: load_val = dmem_rdata;
        endcase
    end

    // write-back and next pc
    reg        wen;
    reg [31:0] wval;
    reg [31:0] next_pc;
    always @(*) begin
        wen = 1'b0; wval = 32'd0; next_pc = pc + 32'd4;
        case (opcode)
            OP_LUI:   begin wen = 1'b1; wval = imm_u; end
            OP_AUIPC: begin wen = 1'b1; wval = pc + imm_u; end
            OP_JAL:   begin wen = 1'b1; wval = pc + 32'd4; next_pc = pc + imm_j; end
            OP_JALR:  begin wen = 1'b1; wval = pc + 32'd4; next_pc = (a + imm_i) & 32'hFFFFFFFE; end
            OP_BR:    begin if (take) next_pc = pc + imm_b; end
            OP_LOAD:  begin wen = 1'b1; wval = load_val; end
            OP_IMM:   begin wen = 1'b1; wval = alu; end
            OP_REG:   begin wen = 1'b1; wval = alu; end
            default:  ;
        endcase
        if (rd == 5'd0) begin wen = 1'b0; wval = 32'd0; end
    end

    assign imem_addr = pc;

    integer i;
    always @(posedge clk) begin
        if (reset) begin
            pc <= RESET_PC;
            for (i = 1; i < 32; i = i + 1) x[i] <= 32'd0;
            retire_valid <= 1'b0; retire_pc <= 32'd0; retire_insn <= 32'd0; retire_rd <= 5'd0;
            retire_rd_wdata <= 32'd0; retire_mem_addr <= 32'd0; retire_mem_wstrb <= 4'd0; retire_mem_wdata <= 32'd0;
        end else begin
            pc <= next_pc;
            if (wen) x[rd] <= wval;
            retire_valid     <= 1'b1;
            retire_pc        <= pc;
            retire_insn      <= insn;
            retire_rd        <= wen ? rd : 5'd0;
            retire_rd_wdata  <= wval;
            retire_mem_addr  <= (is_load || is_store) ? ea : 32'd0;
            retire_mem_wstrb <= dmem_wstrb;
            retire_mem_wdata <= dmem_wdata & {{8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}}} & {32{is_store}};
        end
    end
endmodule
