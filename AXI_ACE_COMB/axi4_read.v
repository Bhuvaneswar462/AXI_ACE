module axi4_read_fsm (
    input         clk,
    input         rst_n,

    // AXI Read Address Channel
    input         arvalid,
    output reg    arready,
    input  [3:0]  arid,

    // AXI Read Data Channel
    output reg        rvalid,
    input             rready,
    output reg [31:0] rdata
);

    localparam IDLE = 2'b00;
    localparam R_S1 = 2'b01;
    localparam R_S2 = 2'b10;

    reg [1:0] state, next_state;
    reg [3:0] arid_latched;

    // Memory
    reg [31:0] mem [0:3];
    initial begin
        mem[0] = 32'hAAAA_1111;
        mem[1] = 32'hBBBB_2222;
        mem[2] = 32'hCCCC_3333;
        mem[3] = 32'hDDDD_4444;
    end

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next-state logic (Fig.5 exact)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:
                if (arvalid)
                    next_state = R_S1;

            R_S1:
                if (rready)
                    next_state = R_S2;

            R_S2:
                next_state = IDLE;
        endcase
    end

    // Output + datapath (FIXED)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready       <= 0;
            rvalid        <= 0;
            rdata         <= 0;
            arid_latched  <= 0;
        end else begin
            arready <= 0;
            rvalid  <= 0;

            case (state)

                // IDLE: accept address
                IDLE: begin
                    arready <= 1'b1;
                    if (arvalid)               // ✅ FIX
                        arid_latched <= arid;  // latch ID
                end

                // r_s1: drive read data (stable)
                R_S1: begin
                    rvalid <= 1'b1;
                     if (rready)
                         rdata <= mem[arid_latched];
                end

                // r_s2: response / cleanup
                R_S2: begin
                    // no signals
                end

            endcase
        end
    end

endmodule
