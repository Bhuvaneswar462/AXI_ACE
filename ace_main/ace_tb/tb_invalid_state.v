`timescale 1ns/1ps

module tb_invalid_state;

    // Clock and reset
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

    // -------------------------
    // DUT instantiation
    // -------------------------
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

    // -------------------------
    // Clock generation
    // -------------------------
    always #5 clk = ~clk;

    // -------------------------
    // Test stimulus
    // -------------------------
    initial begin
        // Dump for GTKWave
        $dumpfile("invalid_state.vcd");
        $dumpvars(0, tb_invalid_state);

        // Init
        clk      = 0;
        rst_n    = 0;
        acvalid  = 0;
        awvalid  = 0;
        arvalid  = 0;
        crready  = 0;
        acsnoop  = 0;

        // Apply reset
        #20;
        rst_n = 1;

        // ---------------------------
        // 1. Stay in INVALID (idle)
        // ---------------------------
        #20;

        // ---------------------------
        // 2. Write in INVALID
        // ---------------------------
        awvalid = 1;
        #10;
        awvalid = 0;

        // ---------------------------
        // 3. Read in INVALID
        // ---------------------------
        arvalid = 1;
        #10;
        arvalid = 0;

        // ---------------------------
        // 4. Ensure no transition
        // ---------------------------
        #10;

        acvalid = 1;

        #10;

        acvalid = 0;
        awvalid = 0;
        arvalid = 0;

        #20;

        

        // End simulation
        $finish;
    end

    // -------------------------
    // Monitor
    // -------------------------
    initial begin
        $monitor(
            "T=%0t | INVALID=%b UC=%b UD=%b | Wm=%b Rm=%b",
            $time,
            invalid,
            unique_clean,
            unique_dirty,
            write_main_mem,
            read_main_mem
        );
    end

endmodule

