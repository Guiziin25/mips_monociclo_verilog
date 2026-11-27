// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/i_mem.v
// Descricao.....: Memoria de instrucoes (ROM assincrona, tamanho parametrizavel) carregada de arquivo texto.
// =============================================================================

module i_mem #(
    parameter ADDR_BITS = 8,                    // 2^ADDR_BITS palavras (256 palavras = 1 KiB)
    parameter FILE      = "instructions.list"   // 1 instrucao binaria (32 bits) por linha
)(
    input  [31:0] address,  // endereco em BYTES, fornecido pelo PC
    output [31:0] i_out     // instrucao armazenada nesse endereco
);

    reg [31:0] rom [0:(1<<ADDR_BITS)-1];
    integer i;

    initial begin
        // Posicoes nao preenchidas ficam 0x00000000 = "sll $0,$0,0" (NOP):
        // se o PC passar do fim do programa, nada e alterado.
        for (i = 0; i < (1<<ADDR_BITS); i = i + 1)
            rom[i] = 32'h00000000;
        // Carrega o programa (binario em texto, uma instrucao por linha)
        $readmemb(FILE, rom);
    end

    // Leitura assincrona (sem clock). Instrucoes alinhadas em 4 bytes:
    // descartamos address[1:0] e usamos address[ADDR_BITS+1:2] como indice.
    assign i_out = rom[address[ADDR_BITS+1:2]];

endmodule
