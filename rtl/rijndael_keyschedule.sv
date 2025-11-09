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

    // Compute the size of the internal key_i state
    localparam int KEYSTATESIZE = (STATESIZE > KEYSIZE) ? STATESIZE : KEYSIZE;

    /**
     * Compute the number of key_i schedule steps that need to be performed during
     * each update to ensure that the full internal state gets updated.
     */
    localparam int NUMSTEPS = (KEYSTATESIZE + NK - 1) / NK;

    /**
     * This parameter contains the number of different cases that must be handled
     * when extracting the round key_i from the current (and next) key_i state for
     * every different combination of NB and NK.
     */
    localparam int NUMKEYVARIATIONS =
        (NB == NK || NB == 2 * NK || NK == 2 * NB) ? 1 :
        (NB == 4 && NK == 6) ? 3 :
        (NB == 6 && NK == 8) ? 4 :
        (NB == 6 && NK == 4) ? 4 :
        (NB == 8 && NK == 6) ? 3 : 0;

    // Bitwidth of the register used to store the current state
    localparam int FSMSTATEWIDTH = $clog2(NUMKEYVARIATIONS);

    // ------------------------------------------------------------
    // key_i schedule logic
    // ------------------------------------------------------------

    // Signals for storing the current and next internal keystate
    logic [KEYSIZE-1:0] keystate, next_keystate;

    // Signals for storing current and next round constants for each step instance
    logic [7:0] rc [NUMSTEPS];
    logic [7:0] next_rc [NUMSTEPS];

    // Signal that determines whether a key_i schedule step needs to be performed
    logic update_state;

    // Logic to compute the next round constant
    function static [7:0] mul2(input logic [7:0] x);
        return {x[6:0], 1'b0} ^ (x[7] * 8'h1b);
    endfunction

    // Instantiate step instances
    generate
        for (genvar i = 0; i < NUMSTEPS; i++) begin : gen_keyschedulestep
            assign next_rc[i] = mul2(rc[i]);

            rijndael_keyschedulestep #(.NK (NK)) keyschedulestep (
                .keystate_i      (keystate),
                .rc_i            (rc[i]),
                .next_keystate_o (next_keystate)
            );
        end
    endgenerate

    // Logic to select the next round key_i
    generate
        if (NUMKEYVARIATIONS > 1) begin : gen_different_key_variations
            logic [FSMSTATEWIDTH-1:0] key_variation_state;

            // Update key_i variation state every time a new round key_i is generated
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    key_variation_state <= 0;
                end else if (enable_i) begin
                    key_variation_state <= key_variation_state + 1;
                end
            end

            // Determine roundkey_o and update_state depending on the current key_i variation state
            if (NUMKEYVARIATIONS == 3) begin : gen_3_key_variations
                always_comb begin
                    case (key_variation_state)
                        2'b00  : roundkey_o = keystate[KEYSIZE-1:0];
                        2'b01  : roundkey_o = {next_keystate[2*KEYSIZE-STATESIZE-1:0], keystate[STATESIZE-1:KEYSIZE]};
                        2'b10  : roundkey_o = next_keystate[STATESIZE-1:2*KEYSIZE-STATESIZE];
                        default: roundkey_o = 'h0;
                    endcase

                    if (key_variation_state == 2'b10) begin
                        update_state = 1'h1;
                    end
                end
            end else if (NUMKEYVARIATIONS == 4) begin : gen_4_key_variations
                always_comb begin
                    case (key_variation_state)
                        2'b00  : roundkey_o = keystate[KEYSIZE-1:0];
                        2'b01  : roundkey_o = {next_keystate[2*KEYSIZE-STATESIZE-1:0], keystate[STATESIZE-1:KEYSIZE]};
                        2'b10  : roundkey_o = {next_keystate[3*KEYSIZE-2*STATESIZE-1:0], keystate[STATESIZE-1:2*KEYSIZE-STATESIZE]};
                        2'b11  : roundkey_o = next_keystate[STATESIZE-1:3*KEYSIZE-2*STATESIZE];
                        default: roundkey_o = 'h0;
                    endcase

                    if (key_variation_state == 2'b01 || key_variation_state == 2'b11) begin
                        update_state = 1'h1;
                    end
                end
            end
        end else begin : gen_one_key_variation
            // The round key_i is always the full state and we need to perform an update every time
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
            // Reset internal key_i state to the main Rijndael key_i
            keystate <= key_i;
        end else if (enable_i && update_state) begin
            // Update round constants
            rc <= next_rc;
            // Update internal key_i state
            keystate <= next_keystate;
        end
    end

endmodule
