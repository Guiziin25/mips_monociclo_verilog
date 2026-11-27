// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/ula_ctrl.v
// Descricao.....: Controle da ULA: traduz ALUOp (da ctrl) + campo funct na operacao de 4 bits da ULA.
// =============================================================================

module ula_ctrl (
    input      [3:0] ALUOp,      // vindo da unidade de controle
    input      [5:0] funct,      // bits [5:0] da instrucao (so importa quando ALUOp = ALUOP_FUNCT)
    output reg [3:0] OP,         // operacao enviada a ULA
    output reg       shamt_sel   // 1 = In1 da ULA e o campo shamt (sll/srl/sra); 0 = R[rs]
);

    // Codigos de ALUOp (DEVEM ser os mesmos de ctrl.v)
    localparam ALUOP_ADD   = 4'b0000;  // lw, sw, addi
    localparam ALUOP_SUB   = 4'b0001;  // beq, bne
    localparam ALUOP_FUNCT = 4'b0010;  // tipo R: olha o funct
    localparam ALUOP_AND   = 4'b0011;  // andi
    localparam ALUOP_OR    = 4'b0100;  // ori
    localparam ALUOP_XOR   = 4'b0101;  // xori
    localparam ALUOP_SLT   = 4'b0110;  // slti
    localparam ALUOP_SLTU  = 4'b0111;  // sltiu
    localparam ALUOP_LUI   = 4'b1000;  // lui

    // Codigos da ULA (DEVEM ser os mesmos de ula.v)
    localparam OP_AND  = 4'b0000, OP_OR  = 4'b0001, OP_ADD  = 4'b0010, OP_XOR = 4'b0011,
               OP_NOR  = 4'b0100, OP_SLL = 4'b0101, OP_SUB  = 4'b0110, OP_SLT = 4'b0111,
               OP_SLTU = 4'b1000, OP_SRL = 4'b1001, OP_SRA  = 4'b1010, OP_LUI = 4'b1011;

    always @(*) begin
        shamt_sel = 1'b0;
        case (ALUOp)
            ALUOP_ADD:  OP = OP_ADD;
            ALUOP_SUB:  OP = OP_SUB;
            ALUOP_AND:  OP = OP_AND;
            ALUOP_OR:   OP = OP_OR;
            ALUOP_XOR:  OP = OP_XOR;
            ALUOP_SLT:  OP = OP_SLT;
            ALUOP_SLTU: OP = OP_SLTU;
            ALUOP_LUI:  OP = OP_LUI;
            ALUOP_FUNCT: begin
                // Tipo R: a operacao depende do campo funct
                case (funct)
                    6'b100000: OP = OP_ADD;                              // add
                    6'b100010: OP = OP_SUB;                              // sub
                    6'b100100: OP = OP_AND;                              // and
                    6'b100101: OP = OP_OR;                               // or
                    6'b100110: OP = OP_XOR;                              // xor
                    6'b100111: OP = OP_NOR;                              // nor
                    6'b101010: OP = OP_SLT;                              // slt
                    6'b101011: OP = OP_SLTU;                             // sltu
                    6'b000000: begin OP = OP_SLL; shamt_sel = 1'b1; end  // sll  (usa shamt)
                    6'b000010: begin OP = OP_SRL; shamt_sel = 1'b1; end  // srl  (usa shamt)
                    6'b000011: begin OP = OP_SRA; shamt_sel = 1'b1; end  // sra  (usa shamt)
                    6'b000100: OP = OP_SLL;                              // sllv (usa R[rs])
                    6'b000110: OP = OP_SRL;                              // srlv (usa R[rs])
                    6'b000111: OP = OP_SRA;                              // srav (usa R[rs])
                    6'b001000: OP = OP_ADD;                              // jr   (resultado da ULA nao e usado)
                    default:   OP = OP_ADD;
                endcase
            end
            default: OP = OP_ADD;
        endcase
    end

endmodule
