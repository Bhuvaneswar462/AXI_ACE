module axi4_write_fsm (
    input  wire        clk,
    input  wire        rst_n,

    // AXI write address channel
    input  wire        awvalid,
    output reg         awready,

    // AXI write data channel
    input  wire        wvalid,
    output reg         wready,

    // AXI write response channel
    output reg         bvalid,
    input  wire        bready
);

    // -------------------------------------------------
    // FSM state encoding (matches Fig-4)
    // -------------------------------------------------
    typedef enum logic [3:0] {
        IDLE = 4'd0,
        W_S1 = 4'd1,   // only addr
        W_S2 = 4'd2,   // addr then data
        W_S3 = 4'd3,   // only data
        W_S4 = 4'd4,   // data then addr
        W_S5 = 4'd5,   // addr & data together
        W_S6 = 4'd6,   // write to memory
        W_S7 = 4'd7,   // completed write
        W_S8 = 4'd8    // response
    } state_t;

    state_t state, next_state;

    // -------------------------------------------------
    // State register
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -------------------------------------------------
    // Next-state logic
    // -------------------------------------------------
    always @(*) begin
        next_state = state;

        case (state)

            IDLE: begin
                if (awvalid && wvalid)
                    next_state = W_S5;
                else if (awvalid)
                    next_state = W_S1;
                else if (wvalid)
                    next_state = W_S3;
            end

            W_S1: begin
                if (wvalid)
                    next_state = W_S2;
            end

            W_S2: begin
                next_state = W_S6;
            end

            W_S3: begin
                if (awvalid)
                    next_state = W_S4;
            end

            W_S4: begin
                next_state = W_S6;
            end

            W_S5: begin
                next_state = W_S6;
            end

            W_S6: begin
                next_state = W_S7;
            end

            W_S7: begin
                next_state = W_S8;
            end

            W_S8: begin
                if (bready)
                    next_state = IDLE;
            end

        endcase
    end

    // -------------------------------------------------
    // Output logic
    // -------------------------------------------------
    always @(*) begin
        awready = 1'b0;
        wready  = 1'b0;
        bvalid  = 1'b0;

        case (state)

            IDLE: begin
                awready = 1'b1;
                wready  = 1'b1;
            end

            W_S1: awready = 1'b1;
            W_S3: wready  = 1'b1;

            W_S2, W_S4, W_S5: begin
                awready = 1'b1;
                wready  = 1'b1;
            end

            W_S8: bvalid = 1'b1;

        endcase
    end

endmodule
