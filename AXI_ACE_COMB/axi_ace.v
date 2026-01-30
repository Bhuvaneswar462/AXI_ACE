module axi_ace_single_mem_top (
    input         clk,
    input         rst_n,

    // -------- AXI READ --------
    input         arvalid,
    output        arready,
    input  [5:0]  araddr,     // address index
    input         rready,
    output        rvalid,
    output [31:0] rdata,

    // -------- AXI WRITE --------
    input         awvalid,
    output        awready,
    input  [5:0]  awaddr,     // address index
    input         wvalid,
    output        wready,
    input  [31:0] wdata,
    input         bready,
    output        bvalid,

    // -------- ACE SNOOP --------
    input         acvalid,
    input  [5:0]  acaddr,
    input         crready,
    output        acready,
    output        crvalid
);

    //-----------------------------
    // Single shared memory
    //-----------------------------
    reg [31:0] mem [0:63];

    //-----------------------------
    // Instantiate your FSMs
    //-----------------------------
    wire write_main_mem;
    wire read_main_mem;

    ace_3state_fsm ace_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .acvalid(acvalid),
        .awvalid(awvalid),
        .arvalid(arvalid),
        .crready(crready),
        .acsnoop(1'b0),   // adapt as needed
        .invalid(),
        .unique_clean(),
        .unique_dirty(),
        .write_main_mem(write_main_mem),
        .write_cache(),      // unused in single memory
        .read_main_mem(read_main_mem),
        .read_cache()        // unused in single memory
    );

    axi4_write_fsm write_fsm (
        .ACLK(clk),
        .ARESETn(rst_n),
        .AWADDR({awaddr,2'b00}),
        .AWLEN(8'd0),
        .AWVALID(awvalid),
        .AWREADY(awready),
        .WDATA(wdata),
        .WVALID(wvalid),
        .WLAST(1'b1),
        .WREADY(wready),
        .BVALID(bvalid),
        .BREADY(bready),
        .BRESP()
    );

    axi4_read_fsm read_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .arvalid(arvalid),
        .arready(arready),
        .arid(awaddr[3:0]), // only for its FSM flow
        .rvalid(rvalid),
        .rready(rready),
        .rdata()            // we drive rdata from shared mem below
    );

    //-----------------------------
    // ACE snoop handshake outputs
    //-----------------------------
    assign acready = acvalid;   // simple accept
    assign crvalid = acvalid & crready;

    //-----------------------------
    // WRITE path to single memory
    //-----------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            // optional reset init
        end
        else if (wvalid && wready && write_main_mem) begin
            mem[awaddr] <= wdata;
        end
    end

    //-----------------------------
    // READ path from single memory
    //-----------------------------
    reg [31:0] rdata_reg;

    always @(posedge clk) begin
        if (read_main_mem)
            rdata_reg <= mem[araddr];
    end

    assign rdata = rdata_reg;

endmodule
