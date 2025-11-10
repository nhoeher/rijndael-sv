# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Niklas Höher

import os
import xml.etree.ElementTree as ET

# ============================================================
# Some useful helper functions for running cocotb tests
# ============================================================
def parse_cocotb_result(xml_path):
    """Parse cocotb results.xml and return ('PASS' or 'FAIL', num_failures, num_tests)"""

    if not os.path.exists(xml_path):
        return ("NO RESULTS", 0, 0)

    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()

        # Find all testcases
        testcases = root.findall(".//testcase")
        total = len(testcases)
        failures = 0

        for tc in testcases:
            if tc.find("failure") is not None:
                failures += 1

        if failures == 0:
            return ("PASS", 0, total)
        else:
            return ("FAIL", failures, total)

    except Exception as e:
        return (f"ERROR: {e}", 0, 0)