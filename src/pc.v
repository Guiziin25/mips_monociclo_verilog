// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/pc.v
// Descricao.....: Contador de Programa (PC): registrador de 32 bits atualizado na borda de subida do clock.
// =============================================================================

module pc (
    input             clock,   // atualiza o PC na borda de subida
    input      [31:0] nextPC,  // proximo valor do PC (vindo do mux de selecao de PC)
    output reg [31:0] PC       // endereco da instrucao atual (vai para a i_mem)
);

    // O PC comeca em 0x00000000 (primeira instrucao da ROM).
    // A interface do modulo, conforme o enunciado, nao possui reset proprio;
    // o valor inicial e dado por 'initial' (simulacao e sintese em FPGA).
    initial PC = 32'h00000000;

    // Em todo ciclo, na borda de subida, o PC recebe o endereco da proxima instrucao
    always @(posedge clock) begin
        PC <= nextPC;
    end

endmodule
