`timescale 1ns/1ps

module tb_axi4_read_fsm;

    reg         clk;
    reg         rst_n;

    reg         arvalid;
    wire        arready;
    reg  [3:0]  arid;

    wire        rvalid;
    reg         rready;
    wire [31:0] rdata;

    // DUT
    axi4_read_fsm dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .arvalid (arvalid),
        .arready (arready),
        .arid    (arid),
        .rvalid  (rvalid),
        .rready  (rready),
        .rdata   (rdata)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        // -------------------------
        // Init
        // -------------------------
        clk     = 0;
        rst_n   = 0;
        arvalid = 0;
        arid    = 0;
        rready  = 0;

        // -------------------------
        // Reset
        // -------------------------
        #20;
        rst_n = 1;

        // -------------------------
        // IDLE → r_s1 (Address handshake)
        // -------------------------
        @(posedge clk);
        arid    = 2;        // expect mem[2] = CCCC_3333
        arvalid = 1;

        // wait for proper handshake
        wait (arvalid && arready);
        @(posedge clk);
        arvalid = 0;

        $display("[%0t] Address handshake complete", $time);

        // -------------------------
        // r_s1 : Stall (NO rready)
        // -------------------------
        repeat (3) begin
            @(posedge clk);
            if (rvalid)
                $display("[%0t] rvalid=1, rready=0 → NO DATA TRANSFER (correct)", $time);
        end

        // -------------------------
        // r_s1 → r_s2 (Read handshake)
        // -------------------------
        @(posedge clk);
        rready = 1;

        // THIS is the only legal read
        wait (rvalid && rready);
        @(posedge clk);

        $display("[%0t] READ HANDSHAKE OCCURRED", $time);
        $display("[%0t] READ DATA = %h", $time, rdata);

        rready = 0;

        // -------------------------
        // r_s2 → IDLE
        // -------------------------
        repeat (2) @(posedge clk);

        if (arready)
            $display("[%0t] Returned to IDLE (FSM correct)", $time);

        #20;
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("axi4_read_fsm.vcd");
        $dumpvars(0, tb_axi4_read_fsm);
    end

endmodule
