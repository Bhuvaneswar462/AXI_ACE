module ace_3state_fsm (
    input        clk,
    input        rst_n,

    // ACE / AXI signals
    input        acvalid,
    input        awvalid,
    input        arvalid,
    input        crready,
    input        acsnoop,   // 1-bit (0 or 1)

    // State indicators
    output reg   invalid,
    output reg   unique_clean,
    output reg   unique_dirty,

    // Action signals
    output reg   write_main_mem,
    output reg   write_cache,
    output reg   read_main_mem,
    output reg   read_cache
);

    // ---------------------------
    // State encoding (Verilog)
    // ---------------------------
    localparam INVALID      = 2'd0;
    localparam UNIQUE_CLEAN = 2'd1;
    localparam UNIQUE_DIRTY = 2'd2;

    reg [1:0] state;
    reg [1:0] next_state;

    // ---------------------------
    // State register
    // ---------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= INVALID;
        else
            state <= next_state;
    end

    // ---------------------------
    // Next-state logic
    // ---------------------------
    always @(*) begin
        next_state = state;

        case (state)

            INVALID: begin
                if (acvalid)
                    next_state = UNIQUE_DIRTY;
                else
                    next_state = INVALID;
            end

            UNIQUE_DIRTY: begin
                if (acsnoop == 1'b1)
                    next_state = UNIQUE_CLEAN;
                else if (!acvalid && !awvalid && !arvalid)
                    next_state = INVALID;
                else
                    next_state = UNIQUE_DIRTY;
                end


            UNIQUE_CLEAN: begin
                if (!acvalid && !awvalid && !arvalid)
                    next_state = INVALID;
                else
                    next_state = UNIQUE_CLEAN;
            end

            default: begin
                next_state = INVALID;
            end

        endcase
    end

    // ---------------------------
    // Output logic
    // ---------------------------
    always @(*) begin
        // Default outputs
        invalid        = 1'b0;
        unique_clean   = 1'b0;
        unique_dirty   = 1'b0;

        write_main_mem = 1'b0;
        write_cache    = 1'b0;
        read_main_mem  = 1'b0;
        read_cache     = 1'b0;

        case (state)

            INVALID: begin
                invalid = 1'b1;

                if (awvalid)
                    write_main_mem = 1'b1;

                if (arvalid)
                    read_main_mem = 1'b1;
            end

            UNIQUE_DIRTY: begin
                unique_dirty = 1'b1;

                // Write to main memory and cache
                if (awvalid && acvalid) begin
                    write_main_mem = 1'b1;
                    write_cache    = 1'b1;
                end

                // Read from main memory
                if (arvalid && crready)
                    read_main_mem = 1'b1;
            end

            UNIQUE_CLEAN: begin
                unique_clean = 1'b1;

                // Write to main memory and cache
                if (awvalid && acvalid) begin
                    write_main_mem = 1'b1;
                    write_cache    = 1'b1;
                end

                // Read from cache
                if (arvalid && crready)
                    read_cache = 1'b1;
            end

            default: begin
                // Do nothing
            end

        endcase
    end

endmodule
