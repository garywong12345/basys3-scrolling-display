`timescale 1ns / 1ps
module tick_gen_tb;

    localparam int W = 4;
    localparam time CLK_PERIOD = 10ns;
    localparam int TEST_PERIOD = 4;
    localparam time EXPECTED_INTERVAL = time'(TEST_PERIOD + 1) * CLK_PERIOD;

    logic clk = 0;
    logic rst;
    logic [W-1:0] period;
    logic tick;

    int errors = 0;

    time tick_start;
    time tick_end;
    time prev_tick;
    time curr_tick;

    tick_gen #(.W(W)) dut (
        .clk    (clk),
        .rst    (rst),
        .period (period),
        .tick   (tick)
    );

    // 100 MHz clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        period = TEST_PERIOD;
        rst = 1;

        // Hold reset for two clock cycles.
        repeat (2) @(posedge clk);
        @(negedge clk); rst = 0; // Release reset away from the active edge.

        // Wait for the first tick.
        @(posedge tick);
        prev_tick = $time;

        // Check that tick stays high for exactly one clock cycle.
        tick_start = $time;
        @(negedge tick);
        tick_end = $time;

        assert (tick_end - tick_start == CLK_PERIOD)
            else begin
                $error("tick width = %0t, expected %0t",
                       tick_end - tick_start, CLK_PERIOD);
                errors++;
            end

        // Check the spacing between several consecutive ticks.
        repeat (3) begin
            @(posedge tick);
            curr_tick = $time;

            assert (curr_tick - prev_tick ==
                    EXPECTED_INTERVAL)
                else begin
                    $error("tick spacing = %0t, expected %0t",
                           curr_tick - prev_tick,
                           EXPECTED_INTERVAL);
                    errors++;
                end

            prev_tick = curr_tick;
        end

        if (errors == 0)
            $display("PASS: tick is one cycle wide and spacing is %0d cycles.",
                     TEST_PERIOD + 1);
        else
            $fatal(1, "FAIL: %0d tick-generator error(s).", errors);

        $finish;
    end

    // A stalled tick generator must fail instead of waiting forever.
    initial begin
        #10us;
        $fatal(1, "FAIL: tick-generator test exceeded its time limit.");
    end

endmodule
