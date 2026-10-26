`timescale 1ns / 1ps
module char7seg (
    input  logic [4:0] code,
    output logic [6:0] seg              // active low, g f e d c b a
);
    import chars::*;

    always_comb begin
        case (code)
            5'd0:    seg = 7'b1000000;
            5'd1:    seg = 7'b1111001; // 1: b c
            5'd2:    seg = 7'b0100100; // 2: a b d e g
            5'd3:    seg = 7'b0110000; // 3: a b c d g
            5'd4:    seg = 7'b0011001; // 4: b c f g
            5'd5:    seg = 7'b0010010; // 5: a c d f g
            5'd6:    seg = 7'b0000010; // 6: a c d e f g
            5'd7:    seg = 7'b1111000; // 7: a b c
            5'd8:    seg = 7'b0000000; // 8: a b c d e f g
            5'd9:    seg = 7'b0010000; // 9: a b c d f g
            5'd10:   seg = 7'b0001000; // A: a b c e f g
            5'd11:   seg = 7'b0000011; // b: c d e f g
            5'd12:   seg = 7'b1000110; // C: a d e f
            5'd13:   seg = 7'b0100001; // d: b c d e g
            5'd14:   seg = 7'b0000110; // E: a d e f g
            5'd15:   seg = 7'b0001110; // F: a e f g
            
            C_BLANK: seg = 7'b1111111;
            C_DASH:  seg = 7'b0111111;
            C_H:     seg = 7'b0001001; // 'H': b c e f g
            C_L:     seg = 7'b1000111; // 'L': d e f
            C_P:     seg = 7'b0001100; // 'P': a b e f g
            C_U:     seg = 7'b1000001; // 'U': b c d e f
            C_I:     seg = 7'b1001111; // 'I': e f (or 7'b1111001 for b c)
            C_O:     seg = 7'b1000000; // 'O': a b c d e f
            C_S:     seg = 7'b0010010; // 'S': a c d f g
            C_R:     seg = 7'b0101111; // 'r': e g
            C_N:     seg = 7'b0101011; // 'n': c e g
            C_T:     seg = 7'b0000111; // 't': d e f g
            C_Y:     seg = 7'b0010001; // 'y': b c d f g         
               
            default: seg = 7'b1111111;
            
        endcase
    end
endmodule
