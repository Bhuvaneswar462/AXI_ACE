`timescale 1ns/1ps

module tb_ace_3state_fsm_unique_clean_fix;

    reg clk;
    reg rst_n;

    reg acvalid;
    reg awvalid;
    reg arvalid;
    reg crready;
    reg acsnoop;

    wire invalid;
    wire unique_dirty;
    wire unique_clean;

    wire write_main_mem;
    wire write_cache;
    wire read_main_mem;
    wire read_cache;

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

    // Clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("unique_clean_fixed.vcd");
        $dumpvars(0, tb_ace_3state_fsm_unique_clean_fix);

        // Init
        clk = 0;
        rst_n = 0;
        acvalid = 0;
        awvalid = 0;
        arvalid = 0;
        crready = 0;
        acsnoop = 0;

        // Reset
        #20 rst_n = 1;

        // INVALID → UNIQUE_DIRTY
        #10 acvalid = 1;
        #10 acvalid = 0;

        // UNIQUE_DIRTY → UNIQUE_CLEAN
        acsnoop = 1;
        #10;

        // -------- UNIQUE_CLEAN READ --------
        arvalid = 1;
        crready = 1;
        #10;
        arvalid = 0;
        crready = 0;

        // -------- UNIQUE_CLEAN WRITE --------
        awvalid = 1;
        acvalid = 1;
        #10;
        awvalid = 0;
        acvalid = 0;

        // Exit UNIQUE_CLEAN
        #30;

        $finish;
    end

    initial begin
        $monitor(
            "T=%0t | INV=%b UD=%b UC=%b | Wm=%b Wc=%b Rc=%b",
            $time,
            invalid,
            unique_dirty,
            unique_clean,
            write_main_mem,
            write_cache,
            read_cache
        );
    end

endmodule
