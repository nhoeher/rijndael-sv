`timescale 1ns / 1ps

module tb_rijndael_encrypt_128_128;

    logic clk, rst;
    logic enable, ready, valid;
    logic [127:0] plaintext, key, ciphertext, expected;

    // Clock setup
    initial clk = 0;
    always #5 clk = ~clk;

    `ifdef VCD
        initial begin
            $display("VCD: Writing waveform to tb_rijndael_encrypt_128_128.vcd");
            $dumpfile("tb_rijndael_encrypt_128_128.vcd");
            $dumpvars(0, tb_rijndael_encrypt_128_128);
        end
    `endif

    // Instantiate DUT
    rijndael_encrypt #(.NB (4), .NK (4)) dut (
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
        #30;
        rst = 1;
        #20;

        // Set test vector inputs and pulse enable
        plaintext = 128'h3243f6a8885a308d313198a2e0370734;
        key       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        expected  = 128'h3925841d02dc09fbdc118597196a0b32;
        enable = 1;
        @(posedge clk);
        enable = 0;

        // Wait for execution to finish and check result
        while (!valid || !ready) #10;
        if (ciphertext !== expected) begin
            $display("Test failed!");
            $finish;
        end

        $display("All tests succeeded!");
        $finish;
    end

endmodule
