`timescale 1ns / 1ps
// Part E - top level of the scrolling display.
// Fill in every /* TODO */. Each block below matches one row of the
// block table in the lab manual. Parameters, expressions and connections
// are student work; input synchronization and speed acceptance are supplied complete.

module top #(
    parameter int COUNTER_DATA_WIDTH = 5,            // width of the position counter
    parameter int TICK_PERIOD_WIDTH  = 27,           // width of the tick_gen period
    parameter int MESSAGE_LENGTH     = 19,           // characters in message_rom, LEN
    parameter int PERIOD_orig        = 100_000_000,  // clock cycles per tick at 1 Hz
    parameter int REFRESH_DWELL      = 18            // display refresh, passed to display_mux
) (
    input  logic       clk,              // 100 MHz oscillator (W5)
    input  logic       rst,              // btnC (U18)
    input  logic       run,              // sw[0] (V17), 1 = scroll
    input  logic [1:0] speed,            // sw[2:1] (W16, V16)
    output logic       tick_indicator,   // led[0] (U16), toggles on every tick
    output logic [3:0] an,
    output logic [6:0] seg
);

    // ----------------------------------------------------------------
    // Internal signals
    // ----------------------------------------------------------------
    logic                         tick;        // keeps pulsing while scrolling is paused
    logic [TICK_PERIOD_WIDTH-1:0] period;      // tick_gen period for the selected speed
    logic [COUNTER_DATA_WIDTH-1:0] addr;       // position in the message
    logic [4:0]                   next_ch;     // character at that position
    logic [19:0]                  window;      // four characters on the display
    logic                         load;        // one-cycle pulse after reset is released

    // ----------------------------------------------------------------
    // Reset synchronizer and load pulse (given).
    // rst_sync is the reset for every block. load goes high for one cycle
    // right after rst_sync falls.
    // ----------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) logic rst_sync1, rst_sync;
    logic rst_d;

    always_ff @(posedge clk) begin
        rst_sync1 <= rst;                     // two-flop synchronizer
        rst_sync  <= rst_sync1;
        rst_d     <= rst_sync;
    end

    assign load = rst_d && !rst_sync;         // falling-edge detector

    // ----------------------------------------------------------------
    // Switch synchronization and speed acceptance (given).
    // Use run_sync, not the raw run input, in both scroll enables.
    // Each speed bit is synchronized independently. Intermediate switch
    // settings are allowed; this is not a debouncer or an atomic bus transfer.
    // ----------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) logic run_sync1, run_sync;
    (* ASYNC_REG = "TRUE" *) logic [1:0] speed_sync1, speed_sync;
    logic [1:0] speed_prev, speed_active;

    always_ff @(posedge clk) begin
        run_sync1   <= run;
        run_sync    <= run_sync1;
        speed_sync1 <= speed;
        speed_sync  <= speed_sync1;
    end

    // Accept equal consecutive samples only when tick_gen restarts its count.
    // This keeps period fixed throughout each interval, even when switching
    // to a faster rate whose terminal count is below the current count.
    always_ff @(posedge clk) begin
        speed_prev <= speed_sync;
        if (rst_sync)
            speed_active <= speed_sync;
        else if (tick && speed_sync == speed_prev)
            speed_active <= speed_sync;
    end

    // ----------------------------------------------------------------
    // Speed select: 1, 2, 4 and 8 Hz.
    // tick_gen produces a tick every (period + 1) clock cycles.
    // PERIOD_orig is a cycle count; period is a terminal count.
    // Work out the conversion for each speed, including the off-by-one.
    // ----------------------------------------------------------------
    always_comb
        case (speed_active)
            2'b00:   period = TICK_PERIOD_WIDTH'((PERIOD_orig >> 0) - 1); // 1 Hz
            2'b01:   period = TICK_PERIOD_WIDTH'((PERIOD_orig >> 1) - 1); // 2 Hz
            2'b10:   period = TICK_PERIOD_WIDTH'((PERIOD_orig >> 2) - 1); // 4 Hz
            2'b11:   period = TICK_PERIOD_WIDTH'((PERIOD_orig >> 3) - 1); // 8 Hz
            default: period = TICK_PERIOD_WIDTH'((PERIOD_orig >> 0) - 1);
        endcase

    // ----------------------------------------------------------------
    // Scroll tick
    // ----------------------------------------------------------------
    tick_gen #(.W(TICK_PERIOD_WIDTH)) u_tick (
        .clk    (clk),
        .rst    (rst_sync),
        .period (period),
        .tick   (tick)
    );

    // ----------------------------------------------------------------
    // Tick indicator: one flip-flop that inverts on every tick (led[0]).
    // ----------------------------------------------------------------
    always_ff @(posedge clk)
        if (rst_sync)     tick_indicator <= 1'b0;
        else if (tick) tick_indicator <= ~tick_indicator ;

    // ----------------------------------------------------------------
    // Position: counts 0 ... MESSAGE_LENGTH-1 and wraps.
    // Think about: when should it count, what should it load and when.
    // Use run_sync in its enable condition.
    // Your wrapper must combine reset-release load and message wrapping,
    // and hold at the final address while paused.
    // ----------------------------------------------------------------
    mod_counter #(    // Use you own definition of mod_counter
        .W          (COUNTER_DATA_WIDTH),
        .PHRASE_LEN (MESSAGE_LENGTH)
    ) u_position (
        .clk  (clk),
        .rst  (rst_sync),
        .en   (tick && run_sync),
        .up   (1'b1),
        .load (load),
        .d    ('0),
        .q    (addr)
    );

    // ----------------------------------------------------------------
    // Message: character at the current position
    // ----------------------------------------------------------------
    message_rom u_message (
        .addr (addr),
        .ch   (next_ch)
    );

    // ----------------------------------------------------------------
    // Window: the four characters currently displayed; connect run_sync to run.
    // ----------------------------------------------------------------
    window u_window (
        .clk     (clk),
        .rst     (rst_sync),
        .tick    (tick),
        .run     (run_sync),
        .next_ch (next_ch),
        .window  (window)
    );

    // ----------------------------------------------------------------
    // Display: 4:1 mux + anode decoder + char7seg, with a refresh counter
    // ----------------------------------------------------------------
    display_mux #(.DWELL(REFRESH_DWELL)) u_display (
        .clk   (clk),
        .value (window),
        .seg   (seg),
        .an    (an)
    );

endmodule
