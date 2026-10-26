`timescale 1ns / 1ps
module counter #(
    parameter int W = 4
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         en,        // count when high
    input  logic         up,        // 1 = increment, 0 = decrement
    input  logic         load,      // load d, overrides en
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);

    always_ff @(posedge clk)
        if (rst)        q <= '0;
        else if (load)  q <= d;
        else if (en)    q <= up ? (q + 1'b1) : (q - 1'b1);

endmodule
