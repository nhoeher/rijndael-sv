# rijndael-sv

This repository contains a generic SystemVerilog hardware implementation of the original **Rijndael** proposal,
that is parameterizable for the number of blocks within the state (`NB = [4,6,8]`) and the number of blocks
within the key (`NK = [4,6,8]`).

Commonly used configurations include:
- `NB = 4, NK = 4`: **AES-128** (compliant with NIST specification)
- `NB = 4, NK = 6`: **AES-192** (compliant with NIST specification)
- `NB = 4, NK = 8`: **AES-256** (compliant with NIST specification)
- `NB = 8, NK = 8`: **Rijndael-256-256** (used in some post-quantum cryptography schemes)

## Usage
TODO

## Synthesis Results (FPGA + ASIC)
TODO

## Executing Tests
TODO