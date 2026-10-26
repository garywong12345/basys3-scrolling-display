`timescale 1ns / 1ps
module top_tb;

    import chars::*;

    localparam time CLK_PERIOD    = 10ns;
    // With REFRESH_DWELL = 4 each digit is lit for 16 cycles, so one full
    // turn of an takes 64 cycles. The scroll period is 4 turns, so every
    // window is shown completely before the next shift, as on the board.
    localparam int  REFRESH_DWELL = 4;
    localparam int  SCROLL_PERIOD = 256;      // clock cycles per scroll tick (speed 00)
    localparam int  MSG_LEN       = 19;
    localparam int  ADDR_W = (MSG_LEN > 1) ? $clog2(MSG_LEN) : 1;
    localparam int  N_TICKS       = MSG_LEN + 4;   // wrap once, then refill the window
    localparam int  PAUSE_AT      = 8;             // pull run low after this many ticks

    // Clock cycles from tick_indicator to the window update. 2 is enough if
    // the window shifts on the rising edge after the tick. Increase it if
    // your design has more registers between the tick and the window.
    localparam int  SETTLE = 2;

    logic clk = 0;
    logic rst;
    logic run;
    logic [1:0] speed;
    logic tick_indicator;
    logic [3:0] an;
    logic [6:0] seg;

    // The testbench reads its own copy of the ROM to know what to expect.
    // It checks stored-window/control behavior, not anode/segment wiring.
    logic [ADDR_W-1:0] ref_addr;
    logic [4:0]  ref_ch;
    logic [19:0] expected;
    time tick_start;
    time tick_end;
    int errors = 0;

    top #(
        .COUNTER_DATA_WIDTH (ADDR_W),
        .PERIOD_orig    (SCROLL_PERIOD),
        .REFRESH_DWELL  (REFRESH_DWELL),
        .MESSAGE_LENGTH (MSG_LEN)
    ) dut (
        .rst            (rst),
        .run            (run),
        .speed          (speed),
        .clk            (clk),
        .tick_indicator (tick_indicator),
        .an             (an),
        .seg            (seg)
    );

    message_rom ref_rom (
        .addr (ref_addr),
        .ch   (ref_ch)
    );

    // 100 MHz clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Inputs are changed on the falling edge so they are stable at the
    // rising edge. The window is checked on a falling edge as well.
    initial begin
        rst      = 1;
        run      = 1;
        speed    = 2'b00;
        ref_addr = '0;

        // The window is expected to reset to four blanks.
        expected = {4{C_BLANK}};

        // Hold reset for five clock cycles.
        repeat (5) @(negedge clk);
        assert (dut.window == expected)
            else begin
                $error("reset: window must contain four blanks");
                errors++;
            end
        rst = 0;

        for (int tick = 0; tick < N_TICKS; tick++) begin

            // --------------------------------------------------------
            // Pull run low for three scroll periods in the middle of
            // the message. The window must not change, and when run
            // goes high again no character may be skipped.
            // --------------------------------------------------------
            if (tick == PAUSE_AT) begin
                run = 0;
                repeat (3 * SCROLL_PERIOD) @(negedge clk);

                assert (dut.window == expected)
                    else begin
                        $error("run low: window changed to %0d %0d %0d %0d",
                               dut.window[19:15], dut.window[14:10],
                               dut.window[9:5],   dut.window[4:0]);
                        errors++;
                    end

                // run went low SETTLE cycles after a tick and stayed low
                // for whole scroll periods, so it goes high again between
                // ticks, never during one.
                run = 1;
            end

            // --------------------------------------------------------
            // One tick: the window shifts one character to the left and
            // the next ROM character enters on the right.
            // tick_indicator toggles once per tick, so waiting for any
            // change of it waits for one tick.
            // dut.window is a hierarchical reference to the window signal
            // inside top. Change it if your signal has another name.
            // --------------------------------------------------------
            @(tick_indicator);
            repeat (SETTLE) @(negedge clk);

            expected = {expected[14:0], ref_ch};

            assert (dut.window == expected)
                else begin
                    $error("tick %0d (ROM address %0d): window = %0d %0d %0d %0d, expected %0d %0d %0d %0d",
                           tick, ref_addr,
                           dut.window[19:15], dut.window[14:10],
                           dut.window[9:5],   dut.window[4:0],
                           expected[19:15],   expected[14:10],
                           expected[9:5],     expected[4:0]);
                    errors++;
                end

            // Reference indexing uses arithmetic, independent of the
            // student's hardware modulus-counter implementation.
            ref_addr = ADDR_W'((tick + 1) % MSG_LEN);
        end

        // ------------------------------------------------------------
        // Speed select: the tick interval must halve for each setting,
        // SCROLL_PERIOD, /2, /4 and /8 cycles (1, 2, 4 and 8 Hz on the
        // board). The speed is changed right after a tick, and the first
        // interval after the change is skipped, so the measurement does
        // not depend on how tick_gen reacts to a change of period.
        // ------------------------------------------------------------
        for (int s = 0; s < 4; s++) begin
            @(negedge clk);
            speed = 2'(s);

            @(tick_indicator);               // first interval after the change
            @(tick_indicator);
            tick_start = $time;
            @(tick_indicator);
            tick_end = $time;

            assert (tick_end - tick_start == time'(SCROLL_PERIOD >> s) * CLK_PERIOD)
                else begin
                    $error("speed %b: tick interval = %0t, expected %0t",
                           speed, tick_end - tick_start,
                           time'(SCROLL_PERIOD >> s) * CLK_PERIOD);
                    errors++;
                end
        end

        if (errors == 0)
            $display("PASS: the window matched the ROM for %0d ticks, run low paused it, and all four speeds are correct.",
                     N_TICKS);
        else
            $display("FAIL: %0d error(s) found.", errors);

        $finish;
    end

    // Safety stop in case tick_indicator never toggles.
    initial begin
        #1ms;
        $fatal(1, "FAIL: stopped at the time limit. Does tick_indicator toggle?");
    end

endmodule
