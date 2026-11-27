#!/usr/bin/env python3
"""
Modelo de referencia (golden model) do MIPS monociclo do Projeto 02.
Grupo: Guilherme Augusto | AOC - UFRPE 2026.2 | Prof. Vitor A. Coutinho

Executa o arquivo instructions.list usando a MESMA tabela de controle e a MESMA
codificacao de ULA do Verilog (ctrl.v / ula_ctrl.v / ula.v / mips_top.v) e:
  1) confere os resultados anotados no .asm de teste (35, 5, 40, 4, 31, 27, -32, ...);
  2) gera tb/expected_trace.vh, usado pelo testbench para auto-verificar o hardware.
Uso: python3 sim/golden_model.py
"""
import sys, os
M = 0xFFFFFFFF
def s32(x): x &= M; return x - (1 << 32) if x & 0x80000000 else x
def sext16(x): return x - 0x10000 if x & 0x8000 else x

# ---- Tabela da unidade de controle (espelha ctrl.v) ---------------------------------
# opcode: (RegWrite, RegDst, ALUSrc, ZeroExt, MemtoReg, MemRead, MemWrite, Branch, BranchNE, Jump, ALUOp)
ALUOP = dict(ADD=0, SUB=1, FUNCT=2, AND=3, OR=4, XOR=5, SLT=6, SLTU=7, LUI=8)
CTRL = {
 0x00: (1,1,0,0,0,0,0,0,0,0,ALUOP['FUNCT']),
 0x08: (1,0,1,0,0,0,0,0,0,0,ALUOP['ADD']),  0x0A: (1,0,1,0,0,0,0,0,0,0,ALUOP['SLT']),
 0x0B: (1,0,1,0,0,0,0,0,0,0,ALUOP['SLTU']), 0x0C: (1,0,1,1,0,0,0,0,0,0,ALUOP['AND']),
 0x0D: (1,0,1,1,0,0,0,0,0,0,ALUOP['OR']),   0x0E: (1,0,1,1,0,0,0,0,0,0,ALUOP['XOR']),
 0x0F: (1,0,1,0,0,0,0,0,0,0,ALUOP['LUI']),
 0x23: (1,0,1,0,1,1,0,0,0,0,ALUOP['ADD']),  0x2B: (0,0,1,0,0,0,1,0,0,0,ALUOP['ADD']),
 0x04: (0,0,0,0,0,0,0,1,0,0,ALUOP['SUB']),  0x05: (0,0,0,0,0,0,0,0,1,0,ALUOP['SUB']),
 0x02: (0,0,0,0,0,0,0,0,0,1,ALUOP['ADD']),  0x03: (1,2,0,0,2,0,0,0,0,1,ALUOP['ADD']),
}
# ---- ula_ctrl.v: funct -> (OP da ULA, shamt_sel) -----------------------------------
OP = dict(AND=0, OR=1, ADD=2, XOR=3, NOR=4, SLL=5, SUB=6, SLT=7, SLTU=8, SRL=9, SRA=10, LUI=11)
FUNCT = {0x20:('ADD',0),0x22:('SUB',0),0x24:('AND',0),0x25:('OR',0),0x26:('XOR',0),0x27:('NOR',0),
         0x2A:('SLT',0),0x2B:('SLTU',0),0x00:('SLL',1),0x02:('SRL',1),0x03:('SRA',1),
         0x04:('SLL',0),0x06:('SRL',0),0x07:('SRA',0),0x08:('ADD',0)}
ALUOP2OP = {0:'ADD',1:'SUB',3:'AND',4:'OR',5:'XOR',6:'SLT',7:'SLTU',8:'LUI'}

def ula(op, a, b):
    a &= M; b &= M
    r = {'AND':a&b,'OR':a|b,'ADD':a+b,'XOR':a^b,'NOR':~(a|b),'SLL':b<<(a&31),'SUB':a-b,
         'SLT':int(s32(a)<s32(b)),'SLTU':int(a<b),'SRL':b>>(a&31),'SRA':s32(b)>>(a&31),
         'LUI':(b&0xFFFF)<<16}[op]
    return r & M

def run(prog, max_cycles=1000, imem_words=256):
    R=[0]*32; D={}; pc=0; trace=[]
    for n in range(max_cycles):
        idx=(pc>>2)%imem_words
        ins=prog[idx] if idx<len(prog) else 0
        opc=ins>>26; rs=(ins>>21)&31; rt=(ins>>16)&31; rd=(ins>>11)&31
        sh=(ins>>6)&31; fn=ins&63; imm=ins&0xFFFF; ja=ins&0x3FFFFFF
        (RW,RD,AS,ZE,M2R,MR,MW,BR,BN,JP,AO)=CTRL.get(opc,(0,0,0,0,0,0,0,0,0,0,0))
        shsel=0
        if AO==ALUOP['FUNCT']: op,shsel=FUNCT.get(fn,('ADD',0))
        else: op=ALUOP2OP.get(AO,'ADD')
        isjr = (opc==0 and fn==8)
        imm_s=sext16(imm)&M; imm_e=imm if ZE else imm_s
        a = sh if shsel else R[rs]
        b = imm_e if AS else R[rt]
        res=ula(op,a,b); zero=int(res==0)
        wr = rt if RD==0 else (rd if RD==1 else 31)
        mem_val = D.get(res&~3 & 0x3FF, 0)     # d_mem: indice = Address[9:2] (256 palavras)
        wb = res if M2R==0 else (mem_val if M2R==1 else (pc+4)&M)
        pc4=(pc+4)&M
        taken=(BR and zero) or (BN and not zero)
        btarget=(pc4+((imm_s<<2)&M))&M
        jtarget=(pc4&0xF0000000)|(ja<<2)
        npc = R[rs] if isjr else (jtarget if JP else (btarget if taken else pc4))
        trace.append(dict(n=n,pc=pc,ins=ins,alu=res,op=op,opc=opc,isjr=isjr,jp=JP,
                          regs=list(R), rt=rt, rd=rd))
        # --- fim do ciclo (borda de subida): escritas
        if MW: D[res&0x3FF&~3]=R[rt]
        if RW and not isjr and wr!=0: R[wr]=wb
        pc=npc
        if pc>=len(prog)*4 + 8: break       # passou do fim do programa (cai nos NOPs da ROM)
    return trace,R,D

def main():
    root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    prog=[int(l,2) for l in open(os.path.join(root,'instructions.list')).read().split()]
    trace,R,D=run(prog)
    ok=True
    def chk(name,got,exp):
        nonlocal ok
        good=(got&M)==(exp&M); ok&=good
        print(f"  [{'OK ' if good else 'ERRO'}] {name}: obtido {s32(got)} / esperado {s32(exp)}")
    print("Conferencia com os comentarios do .asm de teste:")
    first={}                      # resultado da ULA da 1a execucao de cada PC
    for t in trace: first.setdefault(t['pc'],t['alu'])
    chk("add $t0,$s0,$s1 (PC=24)",first[24],35); chk("sub $t1 (PC=28)",first[28],5)
    chk("addi $t2,$s0,20 (PC=32)",first[32],40); chk("and (PC=36)",first[36],4)
    chk("or  (PC=40)",first[40],31); chk("xor (PC=44)",first[44],27); chk("nor (PC=48)",first[48],-32)
    chk("magic + teste 1 (PC=12)",first[12],1024001); chk("magic + teste 2 (PC=52)",first[52],1024002)
    chk("$t3 = 30 (PC=172)",first[172],30); chk("$t4 = 70 (PC=184)",first[184],70); chk("$t0 = 100 (PC=188)",first[188],100)
    jal=[t for t in trace if t['pc']==224][0]
    nxt=[t for t in trace if t['pc']==248][0]
    chk("ULA em jump_link (add $8,$0,$ra) = PC(jal)+4 = 228",nxt['alu'],228)
    # contador de teste 1..7: valor de $t9 ($25) ao final
    chk("$t9 final = magic + 7",R[25],1024007)
    chk("$t3 final",R[11],30); chk("$t4 final",R[12],70); chk("$t0 final (-4: addi $8,$0,-4 apos o retorno do jal)",R[8],-4)
    chk("$ra final",R[31],228); chk("mem[12]",D[12],10); chk("mem[16]",D[16],20)
    chk("mem[48]",D[48],30); chk("mem[52]",D[52],40)
    pcs=[t['pc'] for t in trace]
    print(f"\nCiclos ate sair do programa: {len(trace)}")
    print("Teste 2 (loop beq): PCs 64,68 repetem ->",pcs.count(64),"vezes (esperado 2)")
    print("Teste 3 (loop bne): PC 88 ->",pcs.count(88),"vezes (esperado 2)")
    print("Teste 4 (loop sra/slt): PC 108 ->",pcs.count(108),"vezes (esperado 3)")
    print("Salto j: PCs 200..212 nao executados ->", not any(p in pcs for p in (200,204,208,212)))
    # --- gera o arquivo de expected para o testbench
    out=os.path.join(root,'tb','expected_trace.vh')
    with open(out,'w') as f:
        f.write("// Gerado por sim/golden_model.py - NAO EDITAR A MAO\n")
        f.write(f"// Trace esperado: PC e resultado da ULA em cada ciclo (antes da borda de subida)\n")
        for t in trace:
            check_alu = 0 if (t['opc'] in (2,3) or t['isjr']) else 1   # j/jal/jr: ULA nao e relevante
            f.write(f"exp_pc[{t['n']}]=32'd{t['pc']}; exp_alu[{t['n']}]=32'h{t['alu']:08x}; exp_chk[{t['n']}]=1'b{check_alu};\n")
    print("Arquivo gerado:",os.path.relpath(out,root))
    return 0 if ok else 1, len(trace), R
if __name__=="__main__":
    rc,n,_=main(); sys.exit(rc)
