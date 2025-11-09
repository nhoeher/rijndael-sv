`timescale 1ns / 1ps

module rijndael_shiftrows #(
    parameter int NB = 4,
    localparam int STATESIZE = 32 * NB
) (
    input  logic [STATESIZE-1:0] in_state,
    output logic [STATESIZE-1:0] out_state
);

    // Internal 2D byte matrices
    logic [7:0] istate_matrix [4][NB];
    logic [7:0] ostate_matrix [4][NB];

    // Flattened state <-> State matrix mapping
    generate
        for (genvar i = 0; i < NB; i++) begin : gen_cols
            for (genvar j = 0; j < 4; j++) begin : gen_rows
                localparam int HI = (STATESIZE-1) - (i*32 + j*8);
                assign istate_matrix[j][i] = in_state[HI -: 8];
                assign out_state[HI -: 8]  = ostate_matrix[j][i];
            end
        end
    endgenerate

    // Determine row-shift pattern
    // NB = 4 or 6  -> shifts = {0,1,2,3}
    // NB = 8       -> shifts = {0,1,3,4}
    localparam int SHIFT [4] = (NB == 8) ? '{0,1,3,4} : '{0,1,2,3};

    // Perform shift rows operation itself
    generate
        for (genvar j = 0; j < 4; j++) begin : gen_shift_rows
            for (genvar i = 0; i < NB; i++) begin : gen_shift_cols
                assign ostate_matrix[j][i] = istate_matrix[j][(i + SHIFT[j]) % NB];
            end
        end
    endgenerate

endmodule