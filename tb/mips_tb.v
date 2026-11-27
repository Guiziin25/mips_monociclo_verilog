// =============================================================================
// Grupo.........: Guilherme Augusto (grupo de 1 integrante)
// Atividade.....: Projeto 02 - 2a VA - MIPS monociclo (subconjunto da ISA) em Verilog
// Disciplina....: Arquitetura e Organizacao de Computadores - UFRPE
// Professor.....: Vitor A. Coutinho
// Semestre......: 2026.2
// Arquivo.......: tb/mips_tb.v
// Descricao.....: Testbench auto-verificavel. Roda o programa instructions.list (7 testes) e,
//                 a cada ciclo, compara PC e saida da ULA com o trace esperado
//                 (tb/expected_trace.vh, gerado por sim/golden_model.py). No fim confere
//                 registradores e memoria de dados. Imprime PASSOU / FALHOU.
// Como rodar (na raiz do projeto, onde esta instructions.list):
//     iverilog -g2005 -I tb -o sim/mips.vvp src/*.v tb/mips_tb.v
//     vvp sim/mips.vvp            (gera tambem mips_tb.vcd para o GTKWave)
// =============================================================================
`timescale 1ns/1ps

module mips_tb;

    localparam NCYC = 72;                 // ciclos ate o programa terminar (ver golden_model.py)

    reg         clock = 1'b0;
    reg         reset = 1'b0;
    wire [31:0] pc_out, alu_out, dmem_out;

    // Dispositivo sob teste
    mips_top #(.IMEM_FILE("instructions.list")) dut (
        .clock(clock), .reset(reset),
        .pc_out(pc_out), .alu_out(alu_out), .dmem_out(dmem_out)
    );

    // Clock de 10 ns (borda de subida em 5, 15, 25, ...)
    always #5 clock = ~clock;

    // Pulso de reset do regfile antes da primeira borda de subida
    initial begin
        #1 reset = 1'b1;
        #2 reset = 1'b0;
    end

    // Valores esperados por ciclo
    reg [31:0] exp_pc  [0:NCYC-1];
    reg [31:0] exp_alu [0:NCYC-1];
    reg        exp_chk [0:NCYC-1];        // 1 = compara tambem a ULA (j/jal/jr: nao compara)
    initial begin
        `include "expected_trace.vh"
    end

    integer cyc    = 0;
    integer errors = 0;

    // Amostra os sinais na borda de subida: os elementos sequenciais usam atribuicao
    // nao-bloqueante, entao aqui ainda se enxergam os valores do ciclo que termina.
    always @(posedge clock) begin
        if (cyc < NCYC) begin
            $display("ciclo %3d | PC = %4d (0x%08h) | instr = %b | ULA = %11d (0x%08h) | d_mem = 0x%08h",
                     cyc, pc_out, pc_out, dut.instr, $signed(alu_out), alu_out, dmem_out);
            if (pc_out !== exp_pc[cyc]) begin
                errors = errors + 1;
                $display("   >>> ERRO: PC esperado = %0d", exp_pc[cyc]);
            end
            if (exp_chk[cyc] && (alu_out !== exp_alu[cyc])) begin
                errors = errors + 1;
                $display("   >>> ERRO: ULA esperada = 0x%08h", exp_alu[cyc]);
            end
            cyc = cyc + 1;
        end
    end

    task check_val(input [255:0] nome, input [31:0] obtido, input [31:0] esperado);
        begin
            if (obtido !== esperado) begin
                errors = errors + 1;
                $display("   >>> ERRO: %0s obtido=0x%08h esperado=0x%08h", nome, obtido, esperado);
            end
        end
    endtask

    // Conferencia final do estado de registradores e da memoria de dados
    initial begin
        $dumpfile("mips_tb.vcd");
        $dumpvars(0, mips_tb);
        wait (cyc == NCYC);
        #2;
        $display("---- Conferencia final ----");
        check_val("$t9 (contador de testes)", dut.u_regfile.R[25], 32'd1024007);
        check_val("$t3 (30)",                  dut.u_regfile.R[11], 32'd30);
        check_val("$t4 (70)",                  dut.u_regfile.R[12], 32'd70);
        check_val("$t0 (-4)",                  dut.u_regfile.R[8],  32'hFFFFFFFC);
        check_val("$ra (228)",                 dut.u_regfile.R[31], 32'd228);
        check_val("$0 sempre zero",            dut.u_regfile.R[0],  32'd0);
        check_val("mem[12] = 10",              dut.u_d_mem.mem[3],  32'd10);
        check_val("mem[16] = 20",              dut.u_d_mem.mem[4],  32'd20);
        check_val("mem[48] = 30",              dut.u_d_mem.mem[12], 32'd30);
        check_val("mem[52] = 40",              dut.u_d_mem.mem[13], 32'd40);
        if (errors == 0) $display("RESULTADO: PASSOU - todos os testes conferem.");
        else             $display("RESULTADO: FALHOU - %0d erro(s).", errors);
        $finish;
    end

endmodule
