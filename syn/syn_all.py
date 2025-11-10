# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Niklas Höher

import os
import subprocess
from itertools import product
from pathlib import Path

# ============================================================
# Configuration
# ============================================================
VIVADO = os.getenv("VIVADO")  # Vivado executable
NB_LIST = [4, 6, 8]
NK_LIST = [4, 6, 8]

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = PROJECT_ROOT / "rtl"
BUILD_DIR = PROJECT_ROOT / "build" / "vivado_runs"
TCL_SCRIPT = PROJECT_ROOT / "syn" / "syn_vivado.tcl"

TARGET_CLOCK_PERIOD = 10.0

# ============================================================
# Helper function to run synthesis of one design
# ============================================================
def run_synth(nb, nk):
    """Run Vivado synthesis for one configuration."""
    outdir = BUILD_DIR / f"rijndael_{nb}b_{nk}k"
    outdir.mkdir(parents=True, exist_ok=True)

    print(f"Running synthesis for NB = {nb} NK = {nk}")
    cmd = [
        VIVADO,
        "-mode", "batch",
        "-source", TCL_SCRIPT,
        "-tclargs", RTL_DIR, str(outdir), str(nb), str(nk)
    ]

    log_file = outdir / f"vivado_{nb}b_{nk}k.log"
    with open(log_file, "w") as log:
        subprocess.run(cmd, cwd=outdir, stdout=log, stderr=subprocess.STDOUT, check=False)

# ============================================================
# Main method
# ============================================================
def main():
    for nb, nk in product(NB_LIST, NK_LIST):
        run_synth(nb, nk)

    print("All configurations processed.")

if __name__ == "__main__":
    main()