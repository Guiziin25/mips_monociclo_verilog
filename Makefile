# Projeto 02 - MIPS monociclo em Verilog (Icarus Verilog)
# Uso: make        -> compila e simula (precisa de iverilog/vvp)
#      make model  -> roda o modelo de referencia em Python e regenera tb/expected_trace.vh
all: sim/mips.vvp
	vvp sim/mips.vvp

sim/mips.vvp: src/*.v tb/mips_tb.v tb/expected_trace.vh instructions.list
	iverilog -g2005 -I tb -o sim/mips.vvp src/*.v tb/mips_tb.v

model:
	python3 sim/golden_model.py

clean:
	rm -f sim/mips.vvp mips_tb.vcd
