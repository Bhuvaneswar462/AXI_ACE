`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 14:07:24
// Design Name: 
// Module Name: allwritefsm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi4_write_fsm (
    input wire ACLK,
    input wire ARESETn,
    input wire [31:0] AWADDR,
    input wire [7:0]  AWLEN,
    input wire        AWVALID,
    output reg        AWREADY,
    input wire [31:0] WDATA,
    input wire        WVALID,
    input wire        WLAST,
    output reg        WREADY,
    output reg        BVALID,
    input wire        BREADY,
    output reg [1:0]  BRESP
);

    parameter IDLE = 4'd0, W_S1 = 4'd1, W_S2 = 4'd2, W_S3 = 4'd3, 
              W_S4 = 4'd4, W_S5 = 4'd5, W_S6 = 4'd6, W_S7 = 4'd7, W_S8 = 4'd8;

    reg [3:0] state;
    reg [31:0] mem [0:63];
    reg [5:0] write_ptr;

    // FSM State Transitions
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= IDLE;
            AWREADY <= 1'b0; WREADY <= 1'b0; BVALID <= 1'b0; BRESP <= 2'b00;
        end else begin
            case (state)
                IDLE: begin
                    AWREADY <= 1'b1; WREADY <= 1'b1;
                    if (AWVALID && WVALID) state <= W_S5;
                    else if (AWVALID)      state <= W_S1;
                    else if (WVALID)       state <= W_S3;
                end
                W_S1: begin AWREADY <= 1'b0; WREADY <= 1'b1; if (WVALID) state <= W_S2; end
                W_S2: state <= W_S6;
                W_S3: begin WREADY <= 1'b0; AWREADY <= 1'b1; if (AWVALID) state <= W_S4; end
                W_S4: state <= W_S6;
                W_S5: state <= W_S6;
                W_S6: begin 
                    WREADY <= 1'b1;
                    if (WVALID && WREADY && WLAST) state <= W_S7;
                end
                W_S7: begin BVALID <= 1'b1; if (BREADY) state <= W_S8; end
                W_S8: begin BVALID <= 1'b0; state <= IDLE; end
                default: state <= IDLE;
            endcase
        end
    end

    // ... (Keep your port declarations and FSM state transitions the same)

    // IMPROVED Memory and Pointer Logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_ptr <= 6'b0;
        end else begin
            // 1. Capture the start address immediately on AW handshake
            if (AWVALID && AWREADY) begin
                write_ptr <= AWADDR[7:2]; 
            end 
            
            // 2. Write Data on EVERY W-handshake
            // We use (WVALID && WREADY) as the only condition for writing.
            // This ensures beats aren't lost while the FSM is switching states.
            if (WVALID && WREADY) begin
                mem[write_ptr] <= WDATA;
                write_ptr <= write_ptr + 1; // Increment for the NEXT beat
            end
        end
    end
endmodule
