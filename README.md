# rijndael-sv

This repository contains a generic SystemVerilog hardware implementation of the original **Rijndael** proposal,
that is parameterizable for the number of blocks within the state (`NB = [4,6,8]`) and the number of blocks
within the key (`NK = [4,6,8]`).

Commonly used configurations include:
- `NB = 4, NK = 4`: **AES-128**
- `NB = 4, NK = 6`: **AES-192**
- `NB = 4, NK = 8`: **AES-256**
- `NB = 8, NK = 8`: **Rijndael-256-256** (used in some post-quantum cryptography schemes)

Currently, decryption is **not** supported since it was not needed for the intended use case. If you do need it, open an issue and I might extend this project accordingly.

## Usage
- Instantiate the `rijndael_encrypt` module within your design hierarchy.
- Configure the key and block size via the module parameters `NB` and `NK`.
- **NOTE:** Plaintext and key are copied into the internal state once the enable signal is received.
  The input values of the module do not need to be constant for the entire execution.

### Example Instantiation
```systemverilog
rijndael_encrypt #(.NB(4), .NK(4)) aes128 (
    .clk_i        (clk),
    .rst_ni       (rst),
    .enable_i     (aes_enable),
    .ready_o      (aes_ready),
    .valid_o      (aes_valid),
    .plaintext_i  (aes_plaintext),
    .key_i        (aes_key),
    .ciphertext_o (aes_ciphertext)
);
```

### Port Description
| Port | Direction | Description |
| -- | -- | -- |
| clk_i | in | Clock input |
| rst_ni | in | Active-low synchronous reset |
| enable_i | in | Pulse high for one cycle to start encryption |
| ready_o | out | High once the core is ready for input |
| valid_o | out | High once the ciphertext output is valid |
| plaintext_i | in | AES plaintext |
| key_i | in | AES key |
| ciphertext_o | out | AES ciphertext |


## Architecture
Since area usage was a secondary concern, the design uses a simple LUT-based Sbox implementation and operates 
using a full-state data path to compute one Rijndael round in each clock cycle. The entire encryption
thus requires `NR + 1` cycles, where `NR` refers to the number of rounds and depends on the chosen
parameters. It holds that `NR = max(NB, NK) + 6`.

The key schedule is executed in parallel to the encryption operation itself and only the current internal key
state is stored.

## Synthesis Results
See the tables below for an overview of resource utilization and maximum clock frequency.
Implementation results for a Xilinx Artix-7 FPGA (*XC7A100T*) were generated using the included
Vivado synthesis script (see `syn/` directory). For ASIC synthesis, Synopsys Design Compiler, version S-2021.06-SP4, was used with the NanGate45 cell library.

### FPGA (XC7A100T)
| NB | NK | SLICES | LUT | DSP | FF | BRAM | f_max (MHz) |
| -- | -- | -- | -- | -- | -- | -- | -- |
| 4 | 4 | 158 | 545 | 0 | 271 | 5 | 130.87 |
| 4 | 6 | 389 | 1307 | 0 | 340 | 1.5 | 142.03 |
| 4 | 8 | 369 | 1332 | 0 | 400 | 1.5 | 119.96 |
| 6 | 4 | 676 | 2385 | 0 | 478 | 0 | 125.63 |
| 6 | 6 | 405 | 1463 | 0 | 399 | 1.5 | 128.24 |
| 6 | 8 | 686 | 2483 | 0 | 471 | 0 | 114.76 |
| 8 | 4 | 628 | 2186 | 0 | 535 | 1.5 | 109.97 |
| 8 | 6 | 681 | 2446 | 0 | 670 | 1.5 | 110.80 |
| 8 | 8 | 577 | 2097 | 0 | 527 | 1.5 | 111.83 |

### ASIC (NanGate45)
| NB | NK | TOTAL AREA (GE) | COMB AREA (GE) | NON-COMB AREA (GE) | f_max (MHz) |
| -- | -- | --------------- | -------------- | ------------- | ----------- |
| 4 | 4 | 18677.72 | 17456.78 | 1220.94 | 689.66 |
| 4 | 6 | 19910.90 | 18391.51 | 1519.39 | 649.35 |
| 4 | 8 | 23233.50 | 21429.23 | 1804.28 | 374.53 |
| 6 | 4 | 31351.56 | 29217.17 | 2134.38 | 369.00 |
| 6 | 6 | 26530.57 | 24730.82 | 1799.76 | 636.94 |
| 6 | 8 | 31212.17 | 29113.97 | 2098.21 | 374.53 |
| 8 | 4 | 37394.28 | 34979.53 | 2414.75 | 364.96 |
| 8 | 6 | 39877.92 | 36875.31 | 3002.61 | 337.84 |
| 8 | 8 | 37219.52 | 34840.95 | 2378.57 | 373.13 |

## Executing Tests
We include both a set of minimal SystemVerilog testbenches for two relevant configurations (see `sim/sv`)
and a [cocotb](https://github.com/cocotb/cocotb) testbench that is able to test all implemented configurations with
randomly generated test vectors and compare the results against an included Python reference implementation (see `sim/cocotb`).

We rely on [Icarus Verilog](https://github.com/steveicarus/iverilog) for simulation of RTL designs.
To generate waveforms, make sure that you have Icarus installed and in your system path. To run the cocotb
testbenches, you also need to install the Python requirements from `requirements.txt`.
Afterward, the included test suite can be executed using:

```bash
make sim        # Runs both SystemVerilog and cocotb testbenches
make sim_sv     # Runs only SystemVerilog testbenches
make sim_cocotb # Runs only cocotb testbenches
```

## Contributing
If you notice any issues or require additional features, please open an
issue or submit a pull request.