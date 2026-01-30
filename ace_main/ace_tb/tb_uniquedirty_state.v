`timescale 1ns/1ps

module tb_unique_dirty_with_transitions;

    // Clock & reset
    reg clk;
    reg rst_n;

    // Inputs
    reg acvalid;
    reg awvalid;
    reg arvalid;
    reg crready;
    reg acsnoop;

    // Outputs
    wire invalid;
    wire unique_clean;
    wire unique_dirty;

    wire write_main_mem;
    wire write_cache;
    wire read_main_mem;
    wire read_cache;

    // DUT
    ace_3state_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .acvalid(acvalid),
        .awvalid(awvalid),
        .arvalid(arvalid),
        .crready(crready),
        .acsnoop(acsnoop),
        .invalid(invalid),
        .unique_clean(unique_clean),
        .unique_dirty(unique_dirty),
        .write_main_mem(write_main_mem),
        .write_cache(write_cache),
        .read_main_mem(read_main_mem),
        .read_cache(read_cache)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // GTKWave dump
        $dumpfile("unique_dirty_transitions.vcd");
        $dumpvars(0, tb_unique_dirty_with_transitions);

        // Init
        clk      = 0;
        rst_n    = 0;
        acvalid  = 0;
        awvalid  = 0;
        arvalid  = 0;
        crready  = 0;
        acsnoop  = 1'bx;   // avoid accidental transitions

        // -------------------------
        // Reset → INVALID
        // -------------------------
        #20 rst_n = 1;

        // -------------------------
        // INVALID → UNIQUE_DIRTY
        // -------------------------
        #10 acvalid = 1;
        #10 acvalid = 0;

        // -------------------------
        // Stay in UNIQUE_DIRTY
        // -------------------------
        #20;

        // -------------------------
        // Read in UNIQUE_DIRTY
        // -------------------------
        arvalid = 1;
        crready = 1;
        #10;
        arvalid = 0;
        crready = 0;

        // -------------------------
        // Write in UNIQUE_DIRTY
        // -------------------------
        awvalid = 1;
        acvalid = 1;
        #10;
        awvalid = 0;
        acvalid = 0;

        // -------------------------
        // UNIQUE_DIRTY → UNIQUE_CLEAN
        // Hold ACSNOOP = 1
        // -------------------------
        #10 acsnoop = 1'b1;
        #20;               // hold for 2 clocks

        // -------------------------
        // UNIQUE_CLEAN → INVALID
        // (no valids)
        // -------------------------
        acsnoop = 1'bx;
        #30;

        // -------------------------
        // Re-enter UNIQUE_DIRTY
        // -------------------------
        acvalid = 1;
        #10 acvalid = 0;

        // -------------------------
        // UNIQUE_DIRTY → INVALID
        // Hold ACSNOOP = 0
        // -------------------------
        #10 acsnoop = 1'b0;
        #20;

        $finish;
    end

    // Console monitor (optional)
    initial begin
        $monitor(
            "T=%0t | INV=%b UC=%b UD=%b | ACSNOOP=%b",
            $time,
            invalid,
            unique_clean,
            unique_dirty,
            acsnoop
        );
    end

endmodule
