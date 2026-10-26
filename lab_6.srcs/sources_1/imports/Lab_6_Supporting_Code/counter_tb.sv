`timescale 1ns / 1ps
module counter_tb;

    localparam int W = 4;
    localparam time CLK_PERIOD = 10ns;
    localparam logic [W-1:0] LOAD_VAL = W'(2);

    // Which part of the test is running. Shown by name in the waveform.
    typedef enum {PH_RESET, PH_LOAD, PH_COUNT_UP, PH_COUNT_DOWN, PH_HOLD} phase_t;

    logic clk = 0;
    logic rst;
    logic en;
    logic up;
    logic load;
    logic [W-1:0] d;
    logic [W-1:0] q;

    logic [W-1:0] expected;
    int errors = 0;
    phase_t phase = PH_RESET;

    // Recording signals, written only by the monitor blocks below.
    logic [W-1:0] prev_q;
    phase_t prev_phase;
    logic saw_wrap_up   = 0;       // high for one cycle after each 1111 -> 0000
    logic saw_wrap_down = 0;       // high for one cycle after each 0000 -> 1111

    counter #(.W(W)) dut (
        .clk  (clk),
        .rst  (rst),
        .en   (en),
        .up   (up),
        .load (load),
        .d    (d),
        .q    (q)
    );

    // 100 MHz clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ----------------------------------------------------------------
    // Monitor: remember q and the test phase from the previous cycle.
    // Nonblocking assignment, so both are taken from just before the edge.
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        prev_q     <= q;
        prev_phase <= phase;
    end

    // ----------------------------------------------------------------
    // Monitor: flag each wrap for one cycle, for viewing in the waveform.
    // Checked on the falling edge, when q and prev_q are both stable.
    // Only counting phases are considered, so a load from 0000 to 1111
    // is not mistaken for a wrap.
    // ----------------------------------------------------------------
    always @(negedge clk) begin
        if (prev_phase == PH_COUNT_UP && prev_q == '1 && q == '0)
            saw_wrap_up = 1;      // 1111 -> 0000
        else
            saw_wrap_up = 0;

        if (prev_phase == PH_COUNT_DOWN && prev_q == '0 && q == '1)
            saw_wrap_down = 1;    // 0000 -> 1111
        else
            saw_wrap_down = 0;
    end

    // ----------------------------------------------------------------
    // Stimulus and value checks.
    // Inputs are changed on the falling edge so they are stable when the
    // counter samples them on the rising edge. q is checked on the falling
    // edge, half a cycle after it has updated.
    // ----------------------------------------------------------------
    initial begin
        rst  = 1;
        en   = 0;
        up   = 1;
        load = 0;
        d    = '0;

        // ------------------------------------------------------------
        // 1. Reset: hold reset for two clock cycles, q must be 0.
        // ------------------------------------------------------------
        phase = PH_RESET;
        repeat (2) @(negedge clk);

        assert (q == '0)
            else begin
                $error("after reset q = %b, expected 0", q);
                errors++;
            end

        // rst, load and en are all high, and d = 1111.
        // (See the lab question: which value does q take, and why?)
        load = 1;
        d    = '1;
        en   = 1;
        @(negedge clk);

        assert (q == '0)
            else begin
                $error("rst with load/en high: q = %b, expected 0", q);
                errors++;
            end

        // Release reset but keep load high: now d is really loaded.
        phase = PH_LOAD;
        rst   = 0;
        @(negedge clk);

        assert (q == '1)
            else begin
                $error("load after reset: q = %b, expected %b", q, '1);
                errors++;
            end

        load = 0;

        // ------------------------------------------------------------
        // 2. Count up from 1111. The first step wraps to 0000, and the
        //    count goes all the way round once more.
        // ------------------------------------------------------------
        phase    = PH_COUNT_UP;
        en       = 1;
        up       = 1;
        expected = '1;

        repeat (2**W + 1) begin
            @(negedge clk);
            expected = expected + 1'b1;

            assert (q == expected)
                else begin
                    $error("count up: q = %b, expected %b", q, expected);
                    errors++;
                end
        end

        // ------------------------------------------------------------
        // 3. Load a value. en stays high, so load must override en.
        // ------------------------------------------------------------
        phase = PH_LOAD;
        load  = 1;
        d     = LOAD_VAL;
        @(negedge clk);

        assert (q == LOAD_VAL)
            else begin
                $error("load: q = %b, expected %b (load must override en)",
                       q, LOAD_VAL);
                errors++;
            end

        load     = 0;
        expected = LOAD_VAL;

        // ------------------------------------------------------------
        // 4. Count down through 0000 to 1111.
        // ------------------------------------------------------------
        phase = PH_COUNT_DOWN;
        up    = 0;

        repeat (LOAD_VAL + 2) begin
            @(negedge clk);
            expected = expected - 1'b1;

            assert (q == expected)
                else begin
                    $error("count down: q = %b, expected %b", q, expected);
                    errors++;
                end
        end

        // ------------------------------------------------------------
        // 5. en low freezes the count, whatever up is set to.
        // ------------------------------------------------------------
        phase    = PH_HOLD;
        en       = 0;
        up       = 1;
        expected = q;

        repeat (5) begin
            @(negedge clk);

            assert (q == expected)
                else begin
                    $error("en low: q = %b, expected %b (count should hold)",
                           q, expected);
                    errors++;
                end
        end

        if (errors == 0)
            $display("PASS: reset, load, wrap up, wrap down and hold all correct.");
        else
            $display("FAIL: %0d error(s) found.", errors);

        $finish;
    end

endmodule
