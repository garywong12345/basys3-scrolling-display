`timescale 1ns / 1ps
module window (
    input  logic        tick,
    input  logic        clk,
    input  logic        rst,
    input  logic        run,
    input  logic [4:0]  next_ch,
    output logic [19:0] window // four 5-bit codes; [19:15] is leftmost
);
    import chars::*;

    always_ff @(posedge clk)
        if (rst)
            window <= {4{C_BLANK}};
        else if (tick && run)
            window <= {window[19:0], next_ch}; // discard leftmost, insert at right
        // Otherwise retain all four stored codes.
endmodule
