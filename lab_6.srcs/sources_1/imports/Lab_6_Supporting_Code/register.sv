`timescale 1ns / 1ps
module register #(
    parameter int W = 8
) (
    input  logic         clk,
    input  logic         rst,       // synchronous, active high
    input  logic         en,        // load enable
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);

    always_ff @(posedge clk)
        if (rst)        q <= '0;
        else if (en)    q <= d;
        // No assignment when en is low: q retains its stored value.

endmodule
