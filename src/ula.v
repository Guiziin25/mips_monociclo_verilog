// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/ula.v
// Descricao.....: Unidade Logica e Aritmetica de 32 bits com 12 operacoes e flag Zero.
// =============================================================================

module ula (
    input      [31:0] In1,        // operando 1 (R[rs] ou shamt)
    input      [31:0] In2,        // operando 2 (R[rt] ou imediato)
    input      [3:0]  OP,         // operacao (gerada pela ula_ctrl)
    output reg [31:0] result,     // resultado
    output            Zero_flag   // 1 quando result == 0
);

    // Codificacao das operacoes (DEVE ser a mesma de ula_ctrl.v)
    localparam OP_AND  = 4'b0000;  // In1 &  In2
    localparam OP_OR   = 4'b0001;  // In1 |  In2
    localparam OP_ADD  = 4'b0010;  // In1 +  In2
    localparam OP_XOR  = 4'b0011;  // In1 ^  In2
    localparam OP_NOR  = 4'b0100;  // ~(In1 | In2)
    localparam OP_SLL  = 4'b0101;  // In2 << In1[4:0]   (logico, esquerda)
    localparam OP_SUB  = 4'b0110;  // In1 -  In2
    localparam OP_SLT  = 4'b0111;  // In1 <  In2 (com sinal)
    localparam OP_SLTU = 4'b1000;  // In1 <  In2 (sem sinal)
    localparam OP_SRL  = 4'b1001;  // In2 >> In1[4:0]   (logico, direita)
    localparam OP_SRA  = 4'b1010;  // In2 >>> In1[4:0]  (aritmetico, direita)
    localparam OP_LUI  = 4'b1011;  // {In2[15:0], 16'b0}

    // Copias "com sinal" para as comparacoes signed e para o SRA
    wire signed [31:0] s1 = In1;
    wire signed [31:0] s2 = In2;

    always @(*) begin
        case (OP)
            OP_AND:  result = In1 & In2;
            OP_OR:   result = In1 | In2;
            OP_ADD:  result = In1 + In2;
            OP_XOR:  result = In1 ^ In2;
            OP_NOR:  result = ~(In1 | In2);
            OP_SLL:  result = In2 << In1[4:0];
            OP_SUB:  result = In1 - In2;
            OP_SLT:  result = (s1 < s2) ? 32'd1 : 32'd0;
            OP_SLTU: result = (In1 < In2) ? 32'd1 : 32'd0;
            OP_SRL:  result = In2 >> In1[4:0];
            OP_SRA:  result = s2 >>> In1[4:0];
            OP_LUI:  result = {In2[15:0], 16'h0000};
            default: result = 32'h00000000;
        endcase
    end

    // Flag Zero: usada pelo desvio (beq/bne)
    assign Zero_flag = (result == 32'h00000000);

endmodule
