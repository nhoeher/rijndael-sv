// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Niklas Höher

`timescale 1ns / 1ps

module rijndael_keyschedule #(
    parameter int NB = 4,
    parameter int NK = 4,
    localparam int STATESIZE = 32 * NB,
    localparam int KEYSIZE = 32 * NK
) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 enable_i,
    input  logic [KEYSIZE-1:0]   key_i,
    output logic [STATESIZE-1:0] roundkey_o
);

    // ------------------------------------------------------------
    // Parameter definitions
    // ------------------------------------------------------------

    /**
     * Compute the number of key schedule steps that need to be performed during
     * each update to ensure that enough new words are expanded so that a new
     * round key can be supplied in each iteration.
     */
    localparam int NUMSTEPS = (NB + NK - 1) / NK;

    // Compute the size of the internal key state
    localparam int KEYSTATESIZE = NUMSTEPS * KEYSIZE;

    /**
     * This parameter contains the number of different cases that must be handled
     * when extracting the round key from the current (and next) key state for
     * every different combination of NB and NK.
     */
    localparam int NUMKEYVARIATIONS =
        (NB == NK || NB == 2 * NK) ? 1 :
        (NB == 4 && NK == 6) ? 3 :
        (NB == 6 && NK == 8) ? 4 :
        (NB == 6 && NK == 4) ? 4 :
        (NB == 8 && NK == 6) ? 3 :
        (NK == 2 * NB) ? 2 : 0;

    // Bitwidth of the register used to store the current state
    localparam int FSMSTATEWIDTH = $clog2(NUMKEYVARIATIONS);

    // ------------------------------------------------------------
    // Key schedule logic
    // ------------------------------------------------------------

    // Signals for storing the current and next internal keystate
    logic [KEYSTATESIZE-1:0] keystate, next_keystate;

    // Signals for storing current and next round constants for each step instance
    logic [7:0] rc [NUMSTEPS];
    logic [7:0] next_rc [NUMSTEPS];

    // Signal that determines whether a key schedule step needs to be performed
    logic update_state;

    // Logic to compute the next round constant
    function static [7:0] mul2(input logic [7:0] x);
        return {x[6:0], 1'b0} ^ (x[7] * 8'h1b);
    endfunction

    // Instantiate step instances
    generate
        for (genvar i = 0; i < NUMSTEPS; i++) begin : gen_keyschedulestep
            assign next_rc[i] = mul2(rc[i]);

            localparam int HI = (i + 1) * KEYSIZE - 1;

            rijndael_keyschedulestep #(.NK (NK)) keyschedulestep (
                .keystate_i      (keystate[HI -: KEYSIZE]),
                .rc_i            (rc[i]),
                .next_keystate_o (next_keystate[HI -: KEYSIZE])
            );
        end
    endgenerate

    // Logic to select the next round key
    generate
        if (NUMKEYVARIATIONS > 1) begin : gen_different_key_variations
            logic [FSMSTATEWIDTH-1:0] key_variation_state;

            // Update key variation state every time a new round key is generated
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    key_variation_state <= 0;
                end else if (enable_i) begin
                    key_variation_state <= (key_variation_state == NUMKEYVARIATIONS - 1) ? '0 : (key_variation_state + 1);
                end
            end

            // Determine roundkey_o and update_state depending on the current key variation state
            if (NUMKEYVARIATIONS == 2) begin : gen_2_key_variations
                always_comb begin
                    case (key_variation_state)
                        1'b0   : roundkey_o = keystate[KEYSTATESIZE-1:STATESIZE];
                        1'b1   : roundkey_o = keystate[STATESIZE-1:0];
                        default: roundkey_o = 'h0;
                    endcase

                    update_state = (key_variation_state == 1'b1);
                end
            end else if (NUMKEYVARIATIONS == 3) begin : gen_3_key_variations
                always_comb begin
                    // TODO: These are "the wrong way around" bit-ordering wise
                    case (key_variation_state)
                        2'b00  : roundkey_o = keystate[STATESIZE-1:0];
                        2'b01  : roundkey_o = {next_keystate[2*STATESIZE-KEYSTATESIZE-1:0], keystate[KEYSTATESIZE-1:STATESIZE]};
                        2'b10  : roundkey_o = next_keystate[KEYSTATESIZE-1:2*STATESIZE-KEYSTATESIZE];
                        default: roundkey_o = 'h0;
                    endcase

                    update_state = (key_variation_state == 2'b10);
                end
            end else if (NUMKEYVARIATIONS == 4) begin : gen_4_key_variations
                always_comb begin
                    // TODO: These are "the wrong way around" bit-ordering wise
                    case (key_variation_state)
                        2'b00  : roundkey_o = keystate[STATESIZE-1:0];
                        2'b01  : roundkey_o = {next_keystate[2*STATESIZE-KEYSTATESIZE-1:0], keystate[KEYSTATESIZE-1:STATESIZE]};
                        2'b10  : roundkey_o = {next_keystate[3*STATESIZE-2*KEYSTATESIZE-1:0], keystate[KEYSTATESIZE-1:2*STATESIZE-KEYSTATESIZE]};
                        2'b11  : roundkey_o = next_keystate[KEYSTATESIZE-1:3*STATESIZE-2*KEYSTATESIZE];
                        default: roundkey_o = 'h0;
                    endcase

                    update_state = (key_variation_state[0] == 1'b1);
                end
            end
        end else begin : gen_one_key_variation
            // The round key is always the full state and we need to perform an update every time
            assign roundkey_o = keystate;
            assign update_state = 1'h1;
        end
    endgenerate

    // Update the internal state
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset round constants
            for (int i = 0; i < NUMSTEPS; i++) begin
                rc[i] <= 8'h1;
            end
            // Reset internal key state to the main Rijndael key
            keystate <= key_i;
        end else if (enable_i && update_state) begin
            // Update round constants
            for (int i = 0; i < NUMSTEPS; i++) begin
               rc[i] <= next_rc[i];
            end
            // Update internal key state
            keystate <= next_keystate;
        end
    end

endmodule
