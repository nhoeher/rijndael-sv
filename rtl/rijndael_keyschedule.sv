`timescale 1ns / 1ps

module rijndael_keyschedule #(
    parameter int NK = 4,
    parameter int NB = 4,
    localparam int STATESIZE = 32 * NB,
    localparam int KEYSIZE = 32 * NK
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 enable,
    input  logic [KEYSIZE-1:0]   key,
    output logic [STATESIZE-1:0] roundkey
);

    /**
     * Compute the size of the internal key state as well as the size of the
     * chunk of the previous key state that still needs to be retained since
     * it is needed for the following round key.
     */
    localparam int KEYSTATESIZE = (STATESIZE > KEYSIZE) ? STATESIZE : KEYSIZE;
    localparam int PREVKEYSTATESIZE =
        ((NB != NK) && (NB != 2 * NK) && (NK != 2 * NB)) ? 2 : 0;

    /**
     * Compute the minimum and maximum number of key schedule steps that might
     * be required in a single key schedule update iteration. If NK is a multiple
     * of NB, both of these are going to be the same and PREVKEYSTATESIZE will be 0.
     * Otherwise, there will be some iterations where we can return 2 round keys
     * (constructed from the previous key state chunk and the current key state)
     * without updating the internal state inbetween.
     */
    localparam int MAXSTEPS = (NB + NK - 1) / NK;
    localparam int MINSTEPS = (PREVKEYSTATESIZE != 0) ? 0 : MAXSTEPS;

    // Signals for storing the current and next internal keystate
    logic [KEYSIZE-1:0] keystate, next_keystate;

    // Signals for storing current and next round constant
    logic [7:0] rc, next_rc;

    // Logic to compute the next round constant
    function static [7:0] mul2(input logic [7:0] x);
        return {x[6:0], 1'b0} ^ (x[7] * 8'h1b);
    endfunction

    assign next_rc = mul2(rc);

    // Logic to compute the next internal state

    // TODO: Implement


    // Update the internal state
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rc <= 8'h1;
            keystate <= key;
        end else if (enable) begin
            rc <= next_rc;
            keystate <= next_keystate;
        end
    end

endmodule
