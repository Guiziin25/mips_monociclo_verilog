// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/d_mem.v
// Descricao.....: Memoria de dados (RAM): leitura assincrona com saida em alta impedancia; escrita na borda de subida.
// =============================================================================

module d_mem #(
    parameter ADDR_BITS = 8                     // 2^ADDR_BITS palavras (256 palavras = 1 KiB)
)(
    input         clock,       // usado SOMENTE para sincronizar a escrita (ver nota abaixo)
    input  [31:0] Address,     // endereco em BYTES, fornecido pela ULA
    input  [31:0] WriteData,   // dado a gravar (R[rt], vindo do regfile)
    input         MemWrite,    // 1 = grava WriteData em Address
    input         MemRead,     // 1 = ReadData recebe o dado; 0 = alta impedancia
    output [31:0] ReadData     // dado lido
);

    reg [31:0] mem [0:(1<<ADDR_BITS)-1];
    integer i;

    initial begin
        for (i = 0; i < (1<<ADDR_BITS); i = i + 1)
            mem[i] = 32'h00000000;
    end

    // NOTA DE PROJETO: a leitura e totalmente assincrona (como pede o enunciado).
    // A escrita e feita na borda de subida do clock. Uma escrita puramente
    // combinacional poderia gravar lixo em outra posicao por causa de "glitches"
    // nos sinais de controle/endereco quando o PC muda. Escrever na borda grava
    // apenas os valores estaveis do fim do ciclo.
    always @(posedge clock) begin
        if (MemWrite)
            mem[Address[ADDR_BITS+1:2]] <= WriteData;
    end

    assign ReadData = MemRead ? mem[Address[ADDR_BITS+1:2]] : 32'hzzzzzzzz;

endmodule
