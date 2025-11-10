// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Niklas Höher

`timescale 1ns / 1ps

module tb_rijndael_encrypt_256_256;

    logic clk, rst;
    logic enable, ready, valid;
    logic [255:0] plaintext, key, ciphertext, expected;

    // Clock setup
    initial clk = 0;
    always #5 clk = ~clk;

    `ifdef WAVES
        initial begin
            $dumpfile("sim.fst");
            $dumpvars(0, tb_rijndael_encrypt_256_256);
        end
    `endif

    // Instantiate DUT
    rijndael_encrypt #(.NB (8), .NK (8)) dut (
        .clk_i       (clk),
        .rst_ni      (rst),
        .enable_i    (enable),
        .ready_o     (ready),
        .valid_o     (valid),
        .plaintext_i (plaintext),
        .key_i       (key),
        .ciphertext_o (ciphertext)
    );

    // Execute test vector
    initial begin
        // Set initial values for DUT IO
        enable = 0;
        plaintext = 0;
        key = 0;

        // Initial reset
        rst = 0;
        repeat(3) @(posedge clk);
        rst = 1;
        repeat(2) @(posedge clk);

        // Set test vector inputs and pulse enable
        plaintext = 256'h3243f6a8885a308d313198a2e03707343243f6a8885a308d313198a2e0370734;
        key       = 256'h2b7e151628aed2a6abf7158809cf4f3c2b7e151628aed2a6abf7158809cf4f3c;
        expected  = 256'h512b41370932f9be41a6fa2332ac4f63f016c06f0a3d5352ae3b7ede4acc343d;
        enable = 1;
        @(posedge clk);
        enable = 0;
        @(posedge clk);

        // Wait for execution to finish and check result
        while (!valid || !ready) @(posedge clk);
        if (ciphertext !== expected) begin
            $display("Test failed!");
            $finish;
        end

        $display("All tests succeeded!");
        $finish;
    end

endmodule
