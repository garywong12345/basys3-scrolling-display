`timescale 1ns / 1ps
module register_tb;

    parameter int W = 8;
    logic rst, en;
    logic [W-1:0] d;
    logic [W-1:0] q;
    logic clk = 1'b0;
    always #5 clk = ~clk;                  // 100 MHz: period 10 ns
    int errors = 0;
    register #(.W(W)) dut (.clk(clk), .rst(rst), .en(en), .d(d), .q(q));

    // Example to adapt: add explicit reset and load checks, an error
    // count, and PASS output only when every required check succeeds.
initial begin
        // 1. Test Synchronous Reset
        rst = 1'b1;  en = 1'b1;  d = 8'hFF; 
        repeat (2) @(posedge clk);          
        #1;                                 
        if (q !== 8'h00) begin
            errors++;
        end

        // Release reset with en low (should hold 00 even if d is non-zero)
        @(negedge clk);
        rst = 1'b0;  en = 1'b0;  d = 8'hFF;
        @(posedge clk);
        #1;
        if (q !== 8'h00) begin
            errors++;
        end

        // 2. Test Load (First value: 8'hA5)
        @(negedge clk);
        d = 8'hA5;  en = 1'b1;
        @(posedge clk);
        #1;
        if (q !== 8'hA5) begin
            errors++;
        end

        // 3. Test Load (Second value: 8'h5A)
        @(negedge clk);
        d = 8'h5A;  en = 1'b1;
        @(posedge clk);
        #1;
        if (q !== 8'h5A) begin
            errors++;
        end

        // 4. Test Hold (Change d while en is 0; q must stay 8'h5A)
        @(negedge clk);
        d = 8'hA5;  en = 1'b0;
        repeat (2) @(posedge clk);
        #1;
        if (q !== 8'h5A) begin
            errors++;
        end

        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s) detected.", errors);

        $finish;
    end

endmodule
