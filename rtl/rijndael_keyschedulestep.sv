`timescale 1ns / 1ps

module rijndael_keyschedulestep #(
    parameter int NK = 4,
    localparam int KEYSIZE = 32 * NK
) (
    input  logic [KEYSIZE-1:0] keystate,
    input  logic [7:0]         rc,
    output logic [KEYSIZE-1:0] next_keystate
);

    // Intermediate signals
    logic [31:0] in_rotword, out_rotword;
    logic [31:0] in_subword, out_subword;
    logic [31:0] in_addrcon, out_addrcon;

    // Perform rotword
    assign in_rotword = keystate[KEYSIZE-1 -: 32];
    assign out_rotword = {in_rotword[23:16], in_rotword[15:8], in_rotword[7:0], in_rotword[31:24]};

    // Perform subword
    assign in_subword = out_rotword;

    rijndael_sbox s0 (
        .in_byte  ( in_subword[31:24]),
        .out_byte (out_subword[31:24])
    );

    rijndael_sbox s1 (
        .in_byte  ( in_subword[23:16]),
        .out_byte (out_subword[23:16])
    );

    rijndael_sbox s2 (
        .in_byte  ( in_subword[15:8]),
        .out_byte (out_subword[15:8])
    );

    rijndael_sbox s3 (
        .in_byte  ( in_subword[7:0]),
        .out_byte (out_subword[7:0])
    );

    // Perform addrcon
    assign out_addrcon = {in_addrcon[31:24] ^ rc, in_addrcon[23:0]};

    // Compute output
    assign next_keystate[31: 0]  = keystate[31: 0] ^ out_addrcon;

    genvar i;
    generate
        for (i = 1; i < NK; i++) begin : gen_next_keystate
            localparam int HI = 32 * (i + 1) - 1;
            assign next_keystate[HI -: 32]  = keystate[HI -: 32] ^ next_keystate[HI-32 -: 32];
        end
    endgenerate

endmodule
