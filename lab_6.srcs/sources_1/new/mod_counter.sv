`timescale 1ns / 1ps

module mod_counter #(
    parameter int W          = 5,
    parameter int PHRASE_LEN = 19
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         en,
    input  logic         up,
    input  logic         load,
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);

    logic at_max;
    logic load_internal;
    logic [W-1:0] d_internal;

    // Detect when counter reaches the final message address (PHRASE_LEN - 1)
    assign at_max = (q == W'(PHRASE_LEN - 1));

    assign load_internal = load || (en && at_max);
    assign d_internal    = load ? d : '0;

    counter #(
        .W(W)
    ) u_counter (
        .clk  (clk),
        .rst  (rst),
        .en   (en),
        .up   (up),
        .load (load_internal),
        .d    (d_internal),
        .q    (q)
    );

endmodule
