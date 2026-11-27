// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/ctrl.v
// Descricao.....: Unidade de controle principal: decodifica o opcode e gera todos os sinais de controle.
// =============================================================================

module ctrl (
    input      [5:0] opcode,     // bits [31:26] da instrucao
    output reg       RegWrite,   // habilita escrita no regfile
    output reg [1:0] RegDst,     // registrador destino: 00 = rt, 01 = rd, 10 = $31 ($ra, jal)
    output reg       ALUSrc,     // 0 = In2 da ULA e R[rt]; 1 = In2 e o imediato
    output reg       ZeroExt,    // 1 = imediato com extensao de zero (andi/ori/xori); 0 = extensao de sinal
    output reg [1:0] MemtoReg,   // dado escrito no reg: 00 = ULA, 01 = d_mem, 10 = PC+4 (jal)
    output reg       MemRead,    // habilita leitura da d_mem (lw)
    output reg       MemWrite,   // habilita escrita na d_mem (sw)
    output reg       Branch,     // beq: desvia se Zero = 1
    output reg       BranchNE,   // bne: desvia se Zero = 0
    output reg       Jump,       // j / jal: salto pseudo-absoluto
    output reg [3:0] ALUOp       // codigo enviado a ula_ctrl
);

    // Opcodes (exatamente os do MIPS)
    localparam OPC_RTYPE = 6'b000000;
    localparam OPC_J     = 6'b000010;
    localparam OPC_JAL   = 6'b000011;
    localparam OPC_BEQ   = 6'b000100;
    localparam OPC_BNE   = 6'b000101;
    localparam OPC_ADDI  = 6'b001000;
    localparam OPC_SLTI  = 6'b001010;
    localparam OPC_SLTIU = 6'b001011;
    localparam OPC_ANDI  = 6'b001100;
    localparam OPC_ORI   = 6'b001101;
    localparam OPC_XORI  = 6'b001110;
    localparam OPC_LUI   = 6'b001111;
    localparam OPC_LW    = 6'b100011;
    localparam OPC_SW    = 6'b101011;

    // Codigos de ALUOp (mesmos de ula_ctrl.v)
    localparam ALUOP_ADD  = 4'b0000, ALUOP_SUB  = 4'b0001, ALUOP_FUNCT = 4'b0010,
               ALUOP_AND  = 4'b0011, ALUOP_OR   = 4'b0100, ALUOP_XOR   = 4'b0101,
               ALUOP_SLT  = 4'b0110, ALUOP_SLTU = 4'b0111, ALUOP_LUI   = 4'b1000;

    always @(*) begin
        // Valores padrao: nada acontece (NOP / opcode desconhecido)
        RegWrite = 1'b0;  RegDst   = 2'b00;  ALUSrc   = 1'b0;  ZeroExt = 1'b0;
        MemtoReg = 2'b00; MemRead  = 1'b0;   MemWrite = 1'b0;
        Branch   = 1'b0;  BranchNE = 1'b0;   Jump     = 1'b0;  ALUOp   = ALUOP_ADD;

        case (opcode)
            OPC_RTYPE: begin  // add, sub, and, or, xor, nor, slt, sltu, sll, srl, sra, sllv, srlv, srav, jr
                RegWrite = 1'b1;  RegDst = 2'b01;  ALUOp = ALUOP_FUNCT;
            end
            OPC_ADDI:  begin RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = ALUOP_ADD;  end
            OPC_SLTI:  begin RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = ALUOP_SLT;  end
            OPC_SLTIU: begin RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = ALUOP_SLTU; end  // imediato com sinal, comparacao sem sinal
            OPC_ANDI:  begin RegWrite = 1'b1; ALUSrc = 1'b1; ZeroExt = 1'b1; ALUOp = ALUOP_AND; end
            OPC_ORI:   begin RegWrite = 1'b1; ALUSrc = 1'b1; ZeroExt = 1'b1; ALUOp = ALUOP_OR;  end
            OPC_XORI:  begin RegWrite = 1'b1; ALUSrc = 1'b1; ZeroExt = 1'b1; ALUOp = ALUOP_XOR; end
            OPC_LUI:   begin RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = ALUOP_LUI; end
            OPC_LW: begin
                RegWrite = 1'b1; ALUSrc = 1'b1; MemRead = 1'b1; MemtoReg = 2'b01; ALUOp = ALUOP_ADD;
            end
            OPC_SW: begin
                ALUSrc = 1'b1; MemWrite = 1'b1; ALUOp = ALUOP_ADD;
            end
            OPC_BEQ: begin Branch   = 1'b1; ALUOp = ALUOP_SUB; end
            OPC_BNE: begin BranchNE = 1'b1; ALUOp = ALUOP_SUB; end
            OPC_J:   begin Jump = 1'b1; end
            OPC_JAL: begin
                Jump = 1'b1; RegWrite = 1'b1; RegDst = 2'b10; MemtoReg = 2'b10;
            end
            default: ;  // mantem os valores padrao
        endcase
    end

endmodule
