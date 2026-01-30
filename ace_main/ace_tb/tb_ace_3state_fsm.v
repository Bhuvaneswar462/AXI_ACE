`timescale 1ns/1ps

module tb_ace_3state_fsm_fixed;

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

    // Clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("ace_fsm_fixed.vcd");
        $dumpvars(0, tb_ace_3state_fsm_fixed);

        // Init
        clk = 0;
        rst_n = 0;
        acvalid = 0;
        awvalid = 0;
        arvalid = 0;
        crready = 0;
        acsnoop = 0;

        // -------------------------
        // RESET → INVALID
        // -------------------------
        #20 rst_n = 1;
        #20;

        // =========================
        // INVALID operations
        // =========================
        arvalid = 1;
        #10;
        arvalid = 0;
        awvalid = 1;
        #10;
        awvalid = 0;
        #20;
    

        // =========================
        // INVALID → UNIQUE_DIRTY
        // =========================
        acvalid = 1;
        #10;
        awvalid = 1;
        #10;
        acvalid = 0;
        awvalid = 0;
        arvalid = 1;
        crready = 1;
        #10;

        acsnoop = 1;

        #20;

        acsnoop = 0;
        acvalid = 1;
        awvalid = 1;
        arvalid = 0;
        crready = 0;
        
        #20;



        $finish;
    end

    initial begin
        $monitor(
            "T=%0t | INV=%b UD=%b UC=%b | Wm=%b Wc=%b Rm=%b Rc=%b",
            $time,
            invalid,
            unique_dirty,
            unique_clean,
            write_main_mem,
            write_cache,
            read_main_mem,
            read_cache
        );
    end

endmodule
