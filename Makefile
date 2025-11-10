# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Niklas Höher

# ============================================================
# Makefile for SystemVerilog and cocotb testbenches
# ============================================================

# Icarus Verilog tools
IVERILOG = iverilog
VVP      = vvp

# Compiler flags for Icarus
IVERILOG_FLAGS = -g2012 -Wall -Irtl -D WAVES

# Base build directory
BUILD_DIR = build

# Automatically extract all source files from the rtl directory
SRC := $(shell find rtl -name "*.sv" -o -name "*.svh" -o -name "*.v")

# ============================================================
# SystemVerilog Testbenches
# ============================================================

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

# ============================================================
# cocotb Testbenches
# ============================================================

# Run all cocotb testbenches
sim_cocotb:
	@SIM=icarus WAVES=1 python3 sim/cocotb/test_rijndael.py

# ============================================================
# Utilities
# ============================================================

.PHONY: all clean sim_sv sim_cocotb
.DEFAULT_GOAL := all

all: sim_sv sim_cocotb

# Clean everything
clean:
	rm -r $(BUILD_DIR)/*