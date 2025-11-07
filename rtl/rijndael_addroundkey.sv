`timescale 1ns / 1ps

module rijndael_addroundkey #(
    parameter int NB = 4,
    localparam int STATESIZE = 32 * NB
) (
    input  logic [STATESIZE-1:0] in_state,
    input  logic [STATESIZE-1:0] roundkey,
    output logic [STATESIZE-1:0] out_state
);

    assign out_state = in_state ^ roundkey;
endmodule
