import os
import glob
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_tools.runner import get_runner

from tabulate import tabulate

from model.rijndael import Rijndael
from util.cocotb_helper import parse_cocotb_result

# Pack a list of bytes into an integer (big-endian)
def bytes_to_int(b):
    return int.from_bytes(bytes(b), byteorder="big")

# Unpack integer (big-endian) into hex string of specified byte length
def int_to_hex(x, n):
    return x.to_bytes(n, byteorder="big").hex()

# Transform an array of bytes into a hex string
def bytes_to_hex(b):
    return "".join(f"{x:02x}" for x in b)

# ============================================================
# Define test cases (executed for each configuration)
# ============================================================

@cocotb.test()
async def test_rijndael_encrypt(dut):
    """cocotb test for rijndael_encrypt module. Python implementation is used as reference"""

    # Start clock
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    # Read NB and NK from DUT parameters
    NB = int(dut.NB.value)
    NK = int(dut.NK.value)
    cocotb.log.info(f"Detected DUT parameters NB={NB}, NK={NK}")

    # Instantiate reference instance
    ref = Rijndael(nb = NB, nk = NK)

    # Reset sequence
    dut.rst_ni.value = 0
    dut.enable_i.value = 0
    await Timer(100, unit="ns")
    dut.rst_ni.value = 1
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)

    # Prepare test vectors
    rnd = random.Random(0x42)
    test_vectors = []

    for _ in range(8):
        key = rnd.randbytes(4 * NK)
        pt = rnd.randbytes(4 * NB)
        test_vectors.append((key, pt))

    # Helper function to execute tests for a single test vector
    async def run_one_vector(key, pt, idx):
        # Compute expected ciphertext
        key_hex = bytes_to_hex(key)
        pt_hex = bytes_to_hex(pt)
        expected_hex = ref.encrypt_hex(key_hex, pt_hex)

        # Drive inputs
        key_int = bytes_to_int(key)
        pt_int = bytes_to_int(pt)

        dut.key_i.value = key_int
        dut.plaintext_i.value = pt_int
        await RisingEdge(dut.clk_i)

        # Pulse enable to start execution
        dut.enable_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.enable_i.value = 0
        await RisingEdge(dut.clk_i)

        # Wait until execution finishes
        timeout = 1000
        cycles = 0
        while int(dut.ready_o.value) == 0:
            await RisingEdge(dut.clk_i)
            cycles += 1
            assert cycles <= timeout, f"Timeout while waiting for ready_o (NB = {NB}, NK = {NK}, vec = {idx})"

        # Check result
        actual_int = int(dut.ciphertext_o.value)
        actual_hex = int_to_hex(actual_int, 4 * NB)

        assert expected_hex == actual_hex, f"Ciphertext mismatch (NB = {NB}, NK = {NK}, vec = {idx}): expected {expected_hex}, actual: {actual_hex}"
        cocotb.log.info(f"Pass (NB = {NB}, NK = {NK}, vec = {idx}): {actual_hex}")
            
    # Run all test vectors sequentially
    for i, (key, pt) in enumerate(test_vectors):
        await run_one_vector(key, pt, i)

    cocotb.log.info("All test vectors for NB = {NB} and NK = {NK} passed!")


# ============================================================
# Define test runner (instantiates all configurations)
# ============================================================
PROJECT_ROOT = Path(__file__).resolve().parents[2]
RTL_DIR = PROJECT_ROOT / "rtl"
PY_DIR = PROJECT_ROOT / "sim" / "python"
BUILD_DIR = PROJECT_ROOT / "build" / "cocotb_runs"

RTL_SOURCES = sorted(glob.glob(str(RTL_DIR / "*.sv")) + glob.glob(str(RTL_DIR / "*.v")) + glob.glob(str(RTL_DIR / "*.svh")))

NB_VALUES = [4, 6, 8]
NK_VALUES = [4, 6, 8]

def test_rijndael_encrypt_runner():
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    results = []

    for nb in NB_VALUES:
        for nk in NK_VALUES:

            build_dir = BUILD_DIR / f"rijndael_{nb}b_{nk}k"
            build_dir.mkdir(parents = True, exist_ok = True)

            print(f"Running cocotb tests for NB = {nb} and NK = {nk}...")

            runner.build(
                sources = RTL_SOURCES,
                hdl_toplevel = "rijndael_encrypt",
                parameters = {
                    "NB": nb,
                    "NK": nk
                },
                build_dir = build_dir,
                build_args = ["-g2012", "-Wall", "-Irtl"] if (sim == "icarus") else [],
                always = True,
                timescale = ("1ns", "1ps")
            )

            xml_path = runner.test(hdl_toplevel = "rijndael_encrypt", test_module = "test_rijndael")
            status, _, _ = parse_cocotb_result(xml_path)

            # Construct a nice status message to print at the end
            GREEN = "\033[92m"
            RED = "\033[91m"
            RESET = "\033[0m"

            if status == "PASS":
                result_str = f"{GREEN}PASS{RESET}"
            elif status == "FAIL":
                result_str = f"{RED}FAIL{RESET}"
            results.append((nb, nk, 32*nb, 32*nk, result_str))

    # Print summary
    print("\n")
    print("============================================================")
    print("                       COCOTB SUMMARY                       ")
    print("============================================================")
    print("\n")
    print(tabulate(results, headers=["NB", "NK", "Block Size", "Key Size", "Result"], tablefmt="github"))

if __name__ == "__main__":
    test_rijndael_encrypt_runner()
