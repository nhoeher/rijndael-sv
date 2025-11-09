`timescale 1ns / 1ps

module rijndael_keyschedulestep #(
    parameter int NK = 4,
    localparam int KEYSIZE = 32 * NK
) (
    input  logic [KEYSIZE-1:0] keystate,
    input  logic [7:0]         rc,
    output logic [KEYSIZE-1:0] next_keystate
);

    // ------------------------------------------------------------
    // Parts that do not depend on the value of NK
    // ------------------------------------------------------------

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

    // Compute the first 4 output words (same for all values of NK)
    assign next_keystate[31: 0]  = keystate[31: 0] ^ out_addrcon;

    generate
        for (genvar i = 1; i < NK; i++) begin : gen_next_keystate
            // If NK == 8, the fifth word of the new key state is computed differently (2nd subword)
            if (NK != 8 || i != 4) begin : gen_next_keystate_inner
                localparam int HI = 32 * (i + 1) - 1;
                assign next_keystate[HI -: 32]  = keystate[HI -: 32] ^ next_keystate[HI-32 -: 32];
            end
        end
    endgenerate

    // ------------------------------------------------------------
    // Parts that do depend on NK
    // ------------------------------------------------------------

    /**
     * If NK=8, we also need to apply subword to the 4th word of the next state
     * before XORing the result onto the 5th word of the current state.
     */
    generate
        if (NK == 8) begin : gen_nk8
            logic [31:0] in_subword2, out_subword2;

            assign in_subword2 = next_keystate[127:96];

            rijndael_sbox s4 (
                .in_byte  ( in_subword2[31:24]),
                .out_byte (out_subword2[31:24])
            );

            rijndael_sbox s5 (
                .in_byte  ( in_subword2[23:16]),
                .out_byte (out_subword2[23:16])
            );

            rijndael_sbox s6 (
                .in_byte  ( in_subword2[15:8]),
                .out_byte (out_subword2[15:8])
            );

            rijndael_sbox s7 (
                .in_byte  ( in_subword2[7:0]),
                .out_byte (out_subword2[7:0])
            );

            assign next_keystate[159:128] = keystate[159:128] ^ out_subword2;
        end
    endgenerate

endmodule
