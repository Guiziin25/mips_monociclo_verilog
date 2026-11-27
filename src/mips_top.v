// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/mips_top.v
// Descricao.....: Nucleo MIPS monociclo (top-level): integra PC, i_mem, regfile, ula, ula_ctrl, ctrl, d_mem e os multiplexadores.
// =============================================================================

module mips_top #(
    parameter IMEM_FILE = "instructions.list"   // programa a ser carregado na ROM
)(
    input         clock,         // clock do sistema
    input         reset,         // reseta o regfile
    output [31:0] pc_out,        // valor atual do PC
    output [31:0] alu_out,       // valor atual da saida da ULA
    output [31:0] dmem_out       // valor atual da saida da memoria de dados (z quando MemRead = 0)
);

    // ------------------------------------------------------------------
    // Sinais internos
    // ------------------------------------------------------------------
    wire [31:0] PC, pc_plus4, nextPC;
    wire [31:0] instr;

    // Campos da instrucao
    wire [5:0]  opcode = instr[31:26];
    wire [4:0]  rs     = instr[25:21];
    wire [4:0]  rt     = instr[20:16];
    wire [4:0]  rd     = instr[15:11];
    wire [4:0]  shamt  = instr[10:6];
    wire [5:0]  funct  = instr[5:0];
    wire [15:0] imm    = instr[15:0];
    wire [25:0] jaddr  = instr[25:0];

    // Sinais de controle
    wire       RegWrite, ALUSrc, ZeroExt, MemRead, MemWrite, Branch, BranchNE, Jump;
    wire [1:0] RegDst, MemtoReg;
    wire [3:0] ALUOp, ula_op;
    wire       shamt_sel;

    // Dados
    wire [31:0] rd1, rd2, imm_sext, imm_ext, alu_in1, alu_in2, alu_result;
    wire        zero;
    wire [31:0] dmem_rdata;
    reg  [31:0] wb_data;
    reg  [4:0]  wr_addr;

    // jr e tipo R (opcode 0) com funct = 001000. A ctrl so recebe o opcode,
    // entao o jr e detectado aqui, olhando tambem o funct.
    wire is_jr = (opcode == 6'b000000) && (funct == 6'b001000);

    // ------------------------------------------------------------------
    // Busca: PC, PC+4 e memoria de instrucoes
    // ------------------------------------------------------------------
    pc u_pc (.clock(clock), .nextPC(nextPC), .PC(PC));

    assign pc_plus4 = PC + 32'd4;

    i_mem #(.FILE(IMEM_FILE)) u_i_mem (.address(PC), .i_out(instr));

    // ------------------------------------------------------------------
    // Controle
    // ------------------------------------------------------------------
    ctrl u_ctrl (
        .opcode(opcode),
        .RegWrite(RegWrite), .RegDst(RegDst), .ALUSrc(ALUSrc), .ZeroExt(ZeroExt),
        .MemtoReg(MemtoReg), .MemRead(MemRead), .MemWrite(MemWrite),
        .Branch(Branch), .BranchNE(BranchNE), .Jump(Jump), .ALUOp(ALUOp)
    );

    ula_ctrl u_ula_ctrl (.ALUOp(ALUOp), .funct(funct), .OP(ula_op), .shamt_sel(shamt_sel));

    // ------------------------------------------------------------------
    // Banco de registradores
    // ------------------------------------------------------------------
    // Mux RegDst: rt (00), rd (01) ou $31 (10, usado pelo jal)
    always @(*) begin
        case (RegDst)
            2'b00:   wr_addr = rt;
            2'b01:   wr_addr = rd;
            default: wr_addr = 5'd31;
        endcase
    end

    // Mux MemtoReg: ULA (00), d_mem (01) ou PC+4 (10, usado pelo jal)
    always @(*) begin
        case (MemtoReg)
            2'b00:   wb_data = alu_result;
            2'b01:   wb_data = dmem_rdata;
            default: wb_data = pc_plus4;
        endcase
    end

    regfile u_regfile (
        .Clock(clock), .Reset(reset),
        .ReadAddr1(rs), .ReadAddr2(rt), .ReadData1(rd1), .ReadData2(rd2),
        .WriteAddr(wr_addr), .WriteData(wb_data),
        .RegWrite(RegWrite & ~is_jr)      // jr e tipo R mas nao escreve registrador
    );

    // ------------------------------------------------------------------
    // Extensao do imediato (sinal ou zero)
    // ------------------------------------------------------------------
    assign imm_sext = {{16{imm[15]}}, imm};
    assign imm_ext  = ZeroExt ? {16'h0000, imm} : imm_sext;

    // ------------------------------------------------------------------
    // ULA
    // ------------------------------------------------------------------
    assign alu_in1 = shamt_sel ? {27'b0, shamt} : rd1;   // sll/srl/sra usam shamt; demais usam R[rs]
    assign alu_in2 = ALUSrc    ? imm_ext        : rd2;   // imediato ou R[rt]

    ula u_ula (.In1(alu_in1), .In2(alu_in2), .OP(ula_op), .result(alu_result), .Zero_flag(zero));

    // ------------------------------------------------------------------
    // Memoria de dados
    // ------------------------------------------------------------------
    d_mem u_d_mem (
        .clock(clock), .Address(alu_result), .WriteData(rd2),
        .MemWrite(MemWrite), .MemRead(MemRead), .ReadData(dmem_rdata)
    );

    // ------------------------------------------------------------------
    // Selecao do proximo PC
    //   prioridade: jr > j/jal > desvio tomado > PC+4
    // ------------------------------------------------------------------
    wire        branch_taken  = (Branch & zero) | (BranchNE & ~zero);
    wire [31:0] branch_target = pc_plus4 + {imm_sext[29:0], 2'b00};          // PC+4 + (SignExt(imm) << 2)
    wire [31:0] jump_target   = {pc_plus4[31:28], jaddr, 2'b00};             // pseudo-absoluto

    assign nextPC = is_jr        ? rd1           :
                    Jump         ? jump_target   :
                    branch_taken ? branch_target :
                                   pc_plus4;

    // ------------------------------------------------------------------
    // Saidas do modulo
    // ------------------------------------------------------------------
    assign pc_out   = PC;
    assign alu_out  = alu_result;
    assign dmem_out = dmem_rdata;

endmodule
