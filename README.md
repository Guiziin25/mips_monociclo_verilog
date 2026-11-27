# Projeto 02 — MIPS monociclo (subconjunto da ISA) em Verilog

**Aluno:** Guilherme Augusto (grupo de 1) · **Disciplina:** Arquitetura e Organização de Computadores — UFRPE, 2026.2 · **Prof.:** Vítor A. Coutinho

## Estrutura

```
instructions.list        programa de teste em binário (carregado na ROM pela i_mem)
prog/                    cópia do .list e do .asm (só para conferência humana)
src/pc.v                 Contador de Programa
src/i_mem.v              ROM de instruções (assíncrona, parametrizável, $readmemb)
src/d_mem.v              RAM de dados (leitura assíncrona, z quando MemRead=0)
src/regfile.v            32 x 32 bits, 2 leituras assíncronas, escrita síncrona, $0 = 0
src/ula.v                ULA de 12 operações + Zero_flag
src/ula_ctrl.v           ALUOp + funct  ->  OP (4 bits) da ULA
src/ctrl.v               Unidade de controle (opcode -> sinais de controle)
src/mips_top.v           Top-level (clock, reset -> pc_out, alu_out, dmem_out)
tb/mips_tb.v             Testbench auto-verificável
tb/expected_trace.vh     Trace esperado (PC e ULA por ciclo), gerado pelo modelo Python
sim/golden_model.py      Modelo de referência em Python (mesma tabela de controle)
Makefile                 make -> compila e simula com Icarus
```

## Como simular

Na **raiz do projeto** (o `instructions.list` é lido do diretório atual):

```
iverilog -g2005 -I tb -o sim/mips.vvp src/*.v tb/mips_tb.v
vvp sim/mips.vvp          # imprime 1 linha por ciclo e "RESULTADO: PASSOU"
gtkwave mips_tb.vcd       # opcional: formas de onda
```

- **Quartus/ModelSim:** crie o projeto com todos os `src/*.v` + `tb/mips_tb.v`, top-level de simulação `mips_tb`, adicione `tb/` ao include path e rode a simulação com o diretório de trabalho contendo `instructions.list`.
- **EDA Playground:** envie `instructions.list` e `expected_trace.vh` como arquivos do projeto; cole `src/*.v` + testbench e escolha Icarus Verilog.
- O enunciado cita `instruction.list`; o arquivo recebido se chama `instructions.list`. O nome é o parâmetro `IMEM_FILE` do `mips_top` (e `FILE` da `i_mem`), então basta trocá-lo se preferir.

## Instruções e codificação (idênticas ao MIPS real)

| Tipo | Opcode | Instruções |
|---|---|---|
| R | `000000` | add 20h, sub 22h, and 24h, or 25h, xor 26h, nor 27h, slt 2Ah, sltu 2Bh, sll 00h, srl 02h, sra 03h, sllv 04h, srlv 06h, srav 07h, jr 08h |
| I | 08 addi · 0A slti · 0B sltiu · 0C andi · 0D ori · 0E xori · 0F lui · 04 beq · 05 bne · 23 lw · 2B sw | |
| J | 02 j · 03 jal | |

## Sinais de controle (`ctrl.v`)

| Instrução | RegWrite | RegDst | ALUSrc | ZeroExt | MemtoReg | MemRead | MemWrite | Branch | BranchNE | Jump | ALUOp |
|---|---|---|---|---|---|---|---|---|---|---|---|
| tipo R | 1 | 01 (rd) | 0 | 0 | 00 | 0 | 0 | 0 | 0 | 0 | FUNCT |
| addi / slti / sltiu | 1 | 00 (rt) | 1 | 0 | 00 | 0 | 0 | 0 | 0 | 0 | ADD / SLT / SLTU |
| andi / ori / xori | 1 | 00 | 1 | **1** | 00 | 0 | 0 | 0 | 0 | 0 | AND / OR / XOR |
| lui | 1 | 00 | 1 | 0 | 00 | 0 | 0 | 0 | 0 | 0 | LUI |
| lw | 1 | 00 | 1 | 0 | 01 (mem) | 1 | 0 | 0 | 0 | 0 | ADD |
| sw | 0 | – | 1 | 0 | – | 0 | 1 | 0 | 0 | 0 | ADD |
| beq | 0 | – | 0 | 0 | – | 0 | 0 | 1 | 0 | 0 | SUB |
| bne | 0 | – | 0 | 0 | – | 0 | 0 | 0 | 1 | 0 | SUB |
| j | 0 | – | – | – | – | 0 | 0 | 0 | 0 | 1 | – |
| jal | 1 | 10 ($31) | – | – | 10 (PC+4) | 0 | 0 | 0 | 0 | 1 | – |

Sinais **extras** além do exemplo do enunciado (o enunciado diz que o projetista deve identificá-los): `ZeroExt` (andi/ori/xori), `BranchNE` (bne), `RegDst` e `MemtoReg` com 2 bits (para o `jal` gravar `PC+4` em `$31`), `Jump`, e `shamt_sel` (saída da `ula_ctrl`, escolhe `shamt` como operando 1 em sll/srl/sra). O `jr` é detectado no top-level (`opcode==0 && funct==001000`), porque a `ctrl` só recebe o opcode; ele escolhe `R[rs]` como próximo PC e bloqueia `RegWrite`.

## Operações da ULA (`OP`, 4 bits)

`0000 AND · 0001 OR · 0010 ADD · 0011 XOR · 0100 NOR · 0101 SLL · 0110 SUB · 0111 SLT · 1000 SLTU · 1001 SRL · 1010 SRA · 1011 LUI`

Convenção dos deslocamentos: `result = In2 << In1[4:0]` (e análogos). Em sll/srl/sra, `In1 = shamt`; em sllv/srlv/srav, `In1 = R[rs]`; `In2 = R[rt]` nos dois casos.

## Próximo PC (prioridade)

`jr → R[rs]`  >  `j/jal → {(PC+4)[31:28], addr26, 00}`  >  `desvio tomado → PC+4 + (SignExt(imm) << 2)`  >  `PC+4`

## Decisões de projeto (úteis na apresentação)

1. **Escrita da `d_mem` na borda de subida.** A tabela do enunciado não lista `clock` na d_mem, mas escrita puramente combinacional pode gravar lixo por *glitches* quando o PC muda e os sinais de controle/endereço se atualizam em ordem diferente. Adicionei a entrada `clock` só para a escrita; a **leitura continua assíncrona**. Se o professor exigir a interface exata, basta me avisar que dá para trocar.
2. **PC sem reset.** A interface do PC no enunciado só tem `clock`, `nextPC` e `PC`; o valor inicial 0 vem de um `initial`. O `reset` do top-level zera só o regfile (como pedido).
3. **ROM inicializada com zeros.** Depois da última instrução do teste o PC segue por NOPs (`0x00000000 = sll $0,$0,0`) sem alterar o estado.
4. **`sltiu`** usa imediato com extensão de **sinal** e comparação **sem sinal** (como o MIPS real e o enunciado).
5. **`lui`** usa a ULA (`{imm, 16'b0}`) em vez de hardware dedicado.

## Roteiro dos 7 testes (programa `instructions.list`, 72 ciclos)

| Teste | O que exercita | Onde observar na `alu_out` |
|---|---|---|
| prefixo | `lui`+`ori`+`add` montam 1024000 em `$t9` | 0x000F0000 → 0x000FA000 → 1024000 |
| 1 | add, sub, addi, and, or, xor, nor | 35, 5, 40, 4, 31, 27, −32; contador = 1024001 |
| 2 | sll + beq (volta 1×) | PC 64–68 aparece 2× |
| 3 | sllv + bne (volta 1×) | PC 88–92 aparece 2× |
| 4 | sra + slt + beq (volta 2×) | PC 108–116 aparece 3× |
| 5 | sw / lw | 30, 70, 100; memória em 12, 16, 48, 52 |
| 6 | j | PCs 200–212 **não** executam |
| 7 | jal / jr | PC do `jal` = 224; `$ra` = 228 aparece na ULA em `add $8,$0,$ra` |

Depois do `jr $ra` o programa executa `addi $8,$0,-1 … -4` (previstos no .asm) e `j exit` leva o PC a 256 (fim do programa); por isso `$t0` termina em −4.
