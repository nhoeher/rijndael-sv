# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Niklas Höher

# ============================================================
# Configuration
# ============================================================

# Icarus Verilog tools (only needed for simulation)
IVERILOG = iverilog
VVP      = vvp

# Vivado executable (only needed for synthesis)
VIVADO = /opt/Xilinx/Vivado/2024.2/bin/vivado


# ============================================================
# Simulation
# ============================================================

# Run all simulations
sim: sim_sv sim_cocotb

# SystemVerilog testbenches:
# ------------------------------------------------------------

# Compiler flags for Icarus
IVERILOG_FLAGS = -g2012 -Wall -Irtl -D WAVES

# Base build directory
BUILD_DIR = build

# Automatically extract all source files from the rtl directory
SRC := $(shell find rtl -name "*.sv" -o -name "*.svh" -o -name "*.v")

# --- Rijndael 128-128 ---
sim_sv_rijndael_128_128: $(SRC) sim/sv/tb_rijndael_encrypt_128_128.sv
	@mkdir -p $(BUILD_DIR)/sv_runs/rijndael_128_128
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(BUILD_DIR)/sv_runs/rijndael_128_128/sim.vvp $(SRC) sim/sv/tb_rijndael_encrypt_128_128.sv
	cd $(BUILD_DIR)/sv_runs/rijndael_128_128 && $(VVP) sim.vvp
	@echo "";

# --- Rijndael 256-256 ---
sim_sv_rijndael_256_256: $(SRC) sim/sv/tb_rijndael_encrypt_256_256.sv
	@mkdir -p $(BUILD_DIR)/sv_runs/rijndael_256_256
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(BUILD_DIR)/sv_runs/rijndael_256_256/sim.vvp $(SRC) sim/sv/tb_rijndael_encrypt_256_256.sv
	cd $(BUILD_DIR)/sv_runs/rijndael_256_256 && $(VVP) sim.vvp
	@echo "";

# Run all SystemVerilog testbenches
sim_sv: sim_sv_rijndael_128_128 sim_sv_rijndael_256_256

# cocotb testbenches:
# ------------------------------------------------------------
# Run all cocotb testbenches
sim_cocotb:
	@SIM=icarus WAVES=1 python3 sim/cocotb/test_rijndael.py

# ============================================================
# Synthesis
# ============================================================

synth_vivado:
	@VIVADO=$(VIVADO) python3 syn/syn_all.py

# ============================================================
# Utilities
# ============================================================

.PHONY: all clean sim_sv sim_cocotb sim synth_vivado
.DEFAULT_GOAL := sim

all: sim synth_vivado

# Clean everything
clean:
	rm -r $(BUILD_DIR)/*