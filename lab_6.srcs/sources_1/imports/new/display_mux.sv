`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 11:58:37 AM
// Design Name: 
// Module Name: display_mux
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module display_mux #(
parameter int DWELL = 17 // passed through to the refresh counter
) (
input logic clk, // 100 MHz board oscillator
input logic [19:0] value, // MODIFIED
output logic [6:0] seg,
output logic [3:0] an
);
logic [1:0] sel;
logic [4:0] digit;
refresh_counter #(.DWELL(DWELL)) u_ref (.clk(clk), .sel(sel)); // scaffolding
// 4-to-1 multiplexer: which nibble is on the shared segment bus right now
always_comb begin
case (sel)
2'd0: digit = value[4:0]; // rightmost digit
2'd1: digit = value[9:5];
2'd2: digit = value[14:10];
2'd3: digit = value[19:15]; // leftmost digit
endcase
end
// 2-to-4 decoder, active low: enable exactly one anode
always_comb begin
case (sel)
            2'd0: an = 4'b1110;  // Enable rightmost digit
            2'd1: an = 4'b1101;  // Enable middle-right digit
            2'd2: an = 4'b1011;  // Enable middle-left digit
            2'd3: an = 4'b0111;  // Enable leftmost digit
        endcase
end
char7seg u_char (.code(digit), .seg(seg));

endmodule
