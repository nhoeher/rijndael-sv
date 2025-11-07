`timescale 1ns / 1ps

module rijndael_subbytes #(
    parameter int NB = 4,
    localparam int STATESIZE = 32 * NB
) (
        input  logic [STATESIZE-1:0] in_state,
        output logic [STATESIZE-1:0] out_state
    );

    localparam int NUMBYTES = 8 * NB;

    genvar i;
    generate
        for (i = 0; i < NUMBYTES; i++) begin : gen_sbox
            rijndael_sbox sbox (
                .in_byte(in_state[i+7:i]),
                .out_byte(out_state[i+7:i])
            );
        end
    endgenerate
endmodule
