`timescale 1ns / 1ps

module rijndael_round #(
    parameter int NB = 4,
    localparam int STATESIZE = 32 * NB
) (
    input  logic                 is_last,
    input  logic [STATESIZE-1:0] in_state,
    input  logic [STATESIZE-1:0] roundkey,
    output logic [STATESIZE-1:0] out_state
);

    logic [STATESIZE-1:0] in_subbytes, out_subbytes;
    logic [STATESIZE-1:0] in_shiftrows, out_shiftrows;
    logic [STATESIZE-1:0] in_mixcolumns, out_mixcolumns;
    logic [STATESIZE-1:0] in_addroundkey, out_addroundkey;

    // Connect individual round functions
    assign in_subbytes = in_state;
    assign in_shiftrows = out_subbytes;
    assign in_mixcolumns = out_shiftrows;
    assign in_addroundkey = is_last ? out_shiftrows : out_mixcolumns;
    assign out_state = out_addroundkey;

    rijndael_subbytes #(.NB (NB)) subbytes (
        .in_state  ( in_subbytes),
        .out_state (out_subbytes)
    );

    rijndael_shiftrows #(.NB (NB)) shiftrows (
        .in_state  ( in_shiftrows),
        .out_state (out_shiftrows)
    );

    rijndael_mixcolumns #(.NB (NB)) mixcolumns (
        .in_state  ( in_mixcolumns),
        .out_state (out_mixcolumns)
    );

    rijndael_addroundkey #(.NB (NB)) addroundkey (
        .in_state  ( in_addroundkey),
        .out_state (out_addroundkey),
        .roundkey  (roundkey)
    );

endmodule
