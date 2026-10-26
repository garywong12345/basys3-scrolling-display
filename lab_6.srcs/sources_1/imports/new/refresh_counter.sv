`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 11:57:12 AM
// Design Name: 
// Module Name: refresh_counter
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


// INSTRUCTOR-SUPPLIED SCAFFOLDING - do not modify; cite in your report.
// Advances sel once every 2**DWELL clock cycles. You will build this yourself in Lab 6.
module refresh_counter #(parameter int DWELL = 17) (
    input logic clk,
    output logic [1:0] sel
);
    logic [DWELL+1:0] count = '0;
    always_ff @(posedge clk) count <= count + 1'b1;
    assign sel = count[DWELL+1 : DWELL];
endmodule
