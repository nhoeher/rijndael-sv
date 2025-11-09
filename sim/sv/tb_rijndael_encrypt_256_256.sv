`timescale 1ns / 1ps

module tb_rijndael_encrypt_256_256;

    logic clk, rst;
    logic enable, ready, valid;
    logic [255:0] plaintext, key, ciphertext, expected;

    // Clock setup
    initial clk = 0;
    always #5 clk = ~clk;

    `ifdef VCD
        initial begin
            $display("VCD: Writing waveform to tb_rijndael_encrypt_256_256.vcd");
            $dumpfile("tb_rijndael_encrypt_256_256.vcd");
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
        #30;
        rst = 1;
        #20;

        // Set test vector inputs and pulse enable
        // TODO: Replace with proper test vectors
        plaintext = 256'h0000000000000000000000000000000000000000000000000000000000000000;
        key       = 256'h0000000000000000000000000000000000000000000000000000000000000000;
        expected  = 256'h0000000000000000000000000000000000000000000000000000000000000000;
        enable = 1;
        #10;
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
