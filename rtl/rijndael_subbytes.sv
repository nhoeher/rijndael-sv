`timescale 1ns / 1ps

module rijndael_subbytes #(
    parameter int NB = 4,
    localparam int STATESIZE = 32 * NB
) (
        input  logic [STATESIZE-1:0] state_i,
        output logic [STATESIZE-1:0] state_o
    );

    localparam int NUMBYTES = 8 * NB;

    generate
        for (genvar i = 0; i < NUMBYTES; i++) begin : gen_sbox
            rijndael_sbox sbox (
                .x_i(state_i[i+7:i]),
                .y_o(state_o[i+7:i])
            );
        end
    endgenerate
endmodule
