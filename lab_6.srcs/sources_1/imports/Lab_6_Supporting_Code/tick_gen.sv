`timescale 1ns / 1ps
module tick_gen #(
    parameter int W = 27                     // 2**27 > 100,000,000: enough for a 1 Hz tick
) (
    input  logic         clk,
    input  logic         rst,
    input  logic [W-1:0] period,             // ticks every (period + 1) cycles
    output logic         tick                // one-cycle pulse
);

    logic [W-1:0] count;

    always_ff @(posedge clk)
        if (rst || tick)  count <= '0;
        else              count <= count + 1'b1;

    // Tick when the counter reaches the selected terminal count.
    assign tick = (count == period);

endmodule
