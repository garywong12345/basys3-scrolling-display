`timescale 1ns / 1ps
module message_rom (
    input  logic [4:0] addr,
    output logic [4:0] ch
);
    import chars::*;

    always_comb
        case (addr)
// Phrase: "HELLO-ECSE-2610" (15 characters: indices 0..14)
            5'd0:    ch = C_H;
            5'd1:    ch = 5'hE;      // 'E'
            5'd2:    ch = C_L;
            5'd3:    ch = C_L;
            5'd4:    ch = C_O;
            5'd5:    ch = C_DASH;
            5'd6:    ch = 5'hE;      // 'E'
            5'd7:    ch = 5'hC;      // 'C'
            5'd8:    ch = C_S;
            5'd9:    ch = 5'hE;      // 'E'
            5'd10:   ch = C_DASH;
            5'd11:   ch = 5'd2;      // '2'
            5'd12:   ch = 5'd6;      // '6'
            5'd13:   ch = 5'd1;      // '1'
            5'd14:   ch = 5'd0;      // '0'

            5'd15:   ch = C_BLANK;
            5'd16:   ch = C_BLANK;
            5'd17:   ch = C_BLANK;
            5'd18:   ch = C_BLANK;
            default: ch = C_BLANK;
        endcase
endmodule
