# Makefile for Live Watch Hardware Simulation

IVERILOG = iverilog
VVP = vvp

SRC_DIR = src
TB_DIR = tb

# All Verilog source files
SRCS = $(wildcard $(SRC_DIR)/*.v)
TBS = $(wildcard $(TB_DIR)/*.v)

# Output executable for Icarus Verilog
OUT = watchpoint_sim.vvp

.PHONY: all test clean

all: $(OUT)

$(OUT): $(SRCS) $(TBS)
	$(IVERILOG) -o $(OUT) -I $(SRC_DIR) $(SRCS) $(TBS)

test: $(OUT)
	$(VVP) $(OUT)

clean:
	rm -f $(OUT) *.vcd
