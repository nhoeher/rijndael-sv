`timescale 1ns / 1ps

module rijndael_encrypt #(
    parameter int NB = 4,
    parameter int NK = 4,
    localparam int STATESIZE = 32 * NB,
    localparam int KEYSIZE = 32 * NK
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 enable,
    input  logic [STATESIZE-1:0] plaintext,
    input  logic [KEYSIZE-1:0]   key,
    output logic [STATESIZE-1:0] ciphertext,
    output logic                 ready,
    output logic                 valid
);

    // ------------------------------------------------------------
    // Parameter / type definitions
    // ------------------------------------------------------------

    // Compute the required number of rounds
    localparam logic [31:0] NR = (NK > NB) ? NK + 6 : NB + 6;
    // Compute the bitwidth needed for the round counter
    localparam int ROUNDCOUNTERWIDTH = $clog2(NR);
    // Determine the last value of the round counter for comparison later on
    localparam logic[ROUNDCOUNTERWIDTH-1:0] LASTCOUNTERVALUE = NR[ROUNDCOUNTERWIDTH-1:0];

    // FSM states
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_ENCRYPT
    } state_e;

    // ------------------------------------------------------------
    // Encryption logic
    // ------------------------------------------------------------

    // FSM state, round counter, and signal indicating if we are in the last round
    state_e fsm_state, fsm_next_state;
    logic [ROUNDCOUNTERWIDTH-1:0] round_counter;
    logic is_last_round;

    // Internal Rijndael state
    logic [STATESIZE-1:0] rijndael_state, rijndael_next_state;

    // Key schedule IO
    logic keyschedule_enable;
    logic [STATESIZE-1:0] roundkey;

    // Instantiate key schedule
    rijndael_keyschedule #(.NB (NB), .NK (NK)) keyschedule (
        .clk (clk),
        .rst (rst),
        .enable (keyschedule_enable),
        .key (key),
        .roundkey (roundkey)
    );

    // Instantiate AES round
    rijndael_round #(.NB (NB)) round (
        .is_last(is_last_round),
        .in_state (rijndael_state),
        .roundkey (roundkey),
        .out_state (rijndael_next_state)
    );

    assign is_last_round = round_counter == LASTCOUNTERVALUE;
    assign ciphertext = rijndael_state;

    // ------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------

    // Next state logic
    always_comb begin
        case (fsm_state)
            STATE_IDLE : fsm_next_state = (enable) ? STATE_ENCRYPT : STATE_IDLE;
            STATE_ENCRYPT : fsm_next_state = (is_last_round) ? STATE_IDLE : STATE_ENCRYPT;
            default : fsm_next_state = fsm_state;
        endcase
    end

    // Output logic
    always_comb begin
        case (fsm_state)
            STATE_IDLE : begin
                ready = 1'h1;
                valid = 1'h1;
            end

            default : begin
                ready = 1'h0;
                valid = 1'h0;
            end
        endcase
    end

    // Update internal FSM + Rijndael state
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_state <= STATE_IDLE;
            rijndael_state <= '0;
            round_counter <= '0;
        end else begin
            fsm_state <= fsm_next_state;
            if (fsm_state == STATE_ENCRYPT) begin
                rijndael_state <= rijndael_next_state;
                round_counter <= round_counter + 1;
            end
        end
    end

endmodule
