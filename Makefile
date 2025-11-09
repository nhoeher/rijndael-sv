# ============================================================
# Makefile for SystemVerilog and cocotb testbenches
# ============================================================

# Icarus Verilog tools
IVERILOG = iverilog
VVP      = vvp

# Compiler flags for Icarus
IVERILOG_FLAGS = -g2012 -Wall -Irtl -D VCD

# Base build directory
BUILD_DIR = build

# Automatically extract all source files from the rtl directory
SRC := $(shell find rtl -name "*.sv" -o -name "*.svh" -o -name "*.v")

# ============================================================
# SystemVerilog Testbenches
# ============================================================

# --- Rijndael 128-128 ---
sim_sv_rijndael_128_128: $(SRC) sim/sv/tb_rijndael_encrypt_128_128.sv
	@mkdir -p $(BUILD_DIR)/$@
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(BUILD_DIR)/$@/sim.vvp $(SRC) sim/sv/tb_rijndael_encrypt_128_128.sv
	cd $(BUILD_DIR)/$@ && $(VVP) sim.vvp

# --- Rijndael 256-256 ---
sim_sv_rijndael_256_256: $(SRC) sim/sv/tb_rijndael_encrypt_256_256.sv
	@mkdir -p $(BUILD_DIR)/$@
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(BUILD_DIR)/$@/sim.vvp $(SRC) sim/sv/tb_rijndael_encrypt_256_256.sv
	cd $(BUILD_DIR)/$@ && $(VVP) sim.vvp

# Run all SystemVerilog testbenches
sim_sv: sim_sv_rijndael_128_128 sim_sv_rijndael_256_256

# ============================================================
# cocotb Testbenches
# ============================================================

# TODO: Add cocotb targets here
sim_python:

# ============================================================
# Utilities
# ============================================================

.PHONY: all clean sim_sv sim_python
.DEFAULT_GOAL := all

all: sim_sv sim_python

# Clean everything
clean:
	rm -rf $(BUILD_DIR)