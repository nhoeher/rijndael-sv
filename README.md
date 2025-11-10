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
- Instantiate the `rijndael_encrypt` module within your design hierarchy.
- Key and block size can be configured via the corresponding module parameters `NB` and `NK`.
- The module uses an active-low synchronous reset (port `rst_ni`).
- The `ready_o` port is used to signal that the Rijndael instance is ready to receive data.
  Set the `plaintext_i` and `key_i` ports to the intended value and start execution by pulsing
  `enable_i` to 1 for one clock cycle. Afterward, wait for `valid_o` to become 1, which indicates
  that the computation is over and the `ciphertext_o` output has the correct value.

- **NOTE:** Plaintext and key are copied into the internal state once the enable signal is received.
  The input values of the module do not need to be constant for the entire execution.

Currently, decryption is **not** supported since it was not needed for my use case. If you do need it,
feel free to reach out and I might extend this project accordingly.

## Architecture
Since area usage was a secondary concern, the design uses a simple LUT-based Sbox implementation and operates 
using a full-state data path to compute one Rijndael round in each clock cycle. The entire encryption
thus requires `NR + 1` cycles, where `NR` refers to the number of rounds and depends on the chosen
parameters. It holds that `NR = max(NB, NK) + 6`.

The key schedule is executed in parallel to the encryption operation itself and only the current internal key
state is stored.

## Synthesis Results (FPGA + ASIC)
See the tables below for an overview of resource utilization and maximum clock frequency.
FPGA implementation results for a Xilinx Artix-7 (*XC7A100T*) were generated using the included
Vivado synthesis script (see `syn/` directory). For ASIC synthesis, I used Synopsys Design Compiler, version S-2021.06-SP4, with the NanGate45 cell library.

**TODO:** Add results

## Executing Tests
We include both a set of minimal SystemVerilog testbenches for two relevant configurations (see `sim/sv`)
and a [cocotb](https://github.com/cocotb/cocotb) testbench that is able to test all implemented configurations with
randomly generated test vectors and compare the results against an included Python reference implementation (see `sim/cocotb`).

We rely on [Icarus Verilog](https://github.com/steveicarus/iverilog) for simulation of RTL designs.
To generate waveforms, make sure that you have Icarus installed and on your path. To run the cocotb
testbenches, you also need to install the Python requirements from `requirements.txt`.
Afterward, the included test suite can be executed using:

```bash
make sim        # Runs both SystemVerilog and cocotb testbenches
make sim_sv     # Runs only SystemVerilog testbenches
make sim_cocotb # Runs only cocotb testbenches
```