// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: src/regfile.v
// Descricao.....: Banco de 32 registradores de 32 bits: 2 leituras assincronas, 1 escrita sincrona, registrador 0 fixo em 0.
// =============================================================================

module regfile (
    input         Clock,       // sincroniza a escrita
    input         Reset,       // 1 = zera todos os registradores
    input  [4:0]  ReadAddr1,   // 1o registrador a ler (campo rs)
    input  [4:0]  ReadAddr2,   // 2o registrador a ler (campo rt)
    output [31:0] ReadData1,   // conteudo de R[ReadAddr1]
    output [31:0] ReadData2,   // conteudo de R[ReadAddr2]
    input  [4:0]  WriteAddr,   // registrador a escrever
    input  [31:0] WriteData,   // dado a escrever
    input         RegWrite     // habilita a escrita (na borda de subida)
);

    reg [31:0] R [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            R[i] = 32'h00000000;
    end

    // Escrita sincrona. Reset (assincrono) tem prioridade e zera tudo.
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            for (i = 0; i < 32; i = i + 1)
                R[i] <= 32'h00000000;
        end
        else if (RegWrite && (WriteAddr != 5'd0)) begin
            // $0 nunca e escrito: permanece sempre 0x00000000
            R[WriteAddr] <= WriteData;
        end
    end

    // Leituras assincronas (sem clock). Registrador 0 sempre le 0.
    assign ReadData1 = (ReadAddr1 == 5'd0) ? 32'h00000000 : R[ReadAddr1];
    assign ReadData2 = (ReadAddr2 == 5'd0) ? 32'h00000000 : R[ReadAddr2];

endmodule
