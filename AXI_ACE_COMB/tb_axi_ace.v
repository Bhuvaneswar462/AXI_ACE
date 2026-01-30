`timescale 1ns/1ps

module tb_axi_ace_single_mem;

    reg clk;
    reg rst_n;

    // AXI read
    reg         arvalid;
    wire        arready;
    reg  [5:0]  araddr;
    reg         rready;
    wire        rvalid;
    wire [31:0] rdata;

    // AXI write
    reg         awvalid;
    wire        awready;
    reg  [5:0]  awaddr;
    reg         wvalid;
    wire        wready;
    reg  [31:0] wdata;
    reg         bready;
    wire        bvalid;

    // ACE snoop
    reg         acvalid;
    reg  [5:0]  acaddr;
    reg         crready;
    wire        acready;
    wire        crvalid;

    // DUT
    axi_ace_single_mem_top dut (
        .clk(clk),
        .rst_n(rst_n),

        .arvalid(arvalid),
        .arready(arready),
        .araddr(araddr),
        .rready(rready),
        .rvalid(rvalid),
        .rdata(rdata),

        .awvalid(awvalid),
        .awready(awready),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wready(wready),
        .wdata(wdata),
        .bready(bready),
        .bvalid(bvalid),

        .acvalid(acvalid),
        .acaddr(acaddr),
        .crready(crready),
        .acready(acready),
        .crvalid(crvalid)
    );

    // clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;

        arvalid=0; araddr=0; rready=0;
        awvalid=0; awaddr=0;
        wvalid=0;  wdata=0;
        bready=0;
        acvalid=0; acaddr=0; crready=0;

        #20 rst_n = 1;

        //------------------------------------
        // 1) WRITE address 5 = DEADBEEF
        //------------------------------------
        @(posedge clk);
        awaddr  = 6'd5;
        awvalid = 1;
        wdata   = 32'hDEADBEEF;
        wvalid  = 1;
        bready  = 1;

        wait(awready && wready);
        @(posedge clk);
        awvalid = 0;
        wvalid  = 0;

        wait(bvalid);
        @(posedge clk);
        bready = 0;

        $display("WRITE done at addr 5 = DEADBEEF");

        //------------------------------------
        // 2) READ address 5
        //------------------------------------
        @(posedge clk);
        araddr  = 6'd5;
        arvalid = 1;
        rready  = 1;

        wait(arready);
        @(posedge clk);
        arvalid = 0;

        wait(rvalid);
        @(posedge clk);

        if (rdata == 32'hDEADBEEF)
            $display("READ PASS: %h", rdata);
        else
            $display("READ FAIL: %h", rdata);

        rready = 0;

        //------------------------------------
        // 3) ACE snoop same address
        //------------------------------------
        @(posedge clk);
        acaddr  = 6'd5;
        acvalid = 1;
        crready = 1;

        wait(acready);
        @(posedge clk);
        acvalid = 0;

        wait(crvalid);
        @(posedge clk);
        crready = 0;

        $display("SNOOP done at addr 5");

        //------------------------------------
        // 4) READ again after snoop
        //------------------------------------
        @(posedge clk);
        araddr  = 6'd5;
        arvalid = 1;
        rready  = 1;

        wait(arready);
        @(posedge clk);
        arvalid = 0;

        wait(rvalid);
        @(posedge clk);

        $display("READ after snoop = %h", rdata);

        rready = 0;

        #50;
        $finish;
    end

    initial begin
        $dumpfile("axi_ace_single_mem.vcd");
        $dumpvars(0, tb_axi_ace_single_mem);
    end

endmodule
