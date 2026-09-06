`timescale 1ns / 1ps

// Simple UART Transmitter
module uart_tx_byte #(
    parameter CLKS_PER_BIT = 87 // e.g., 10MHz clk, 115200 baud -> ~87
)(
    input wire clk,
    input wire rst_n,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx,
    output reg tx_done,
    output wire tx_active
);

    parameter IDLE = 3'b000;
    parameter TX_START_BIT = 3'b001;
    parameter TX_DATA_BITS = 3'b010;
    parameter TX_STOP_BIT = 3'b011;
    parameter CLEANUP = 3'b100;

    reg [2:0] state;
    reg [7:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] tx_data_reg;

    assign tx_active = (state != IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx <= 1'b1;
            tx_done <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
            tx_data_reg <= 0;
        end else begin
            tx_done <= 1'b0;
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        state <= TX_START_BIT;
                    end
                end
                TX_START_BIT: begin
                    tx <= 1'b0;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= TX_DATA_BITS;
                    end
                end
                TX_DATA_BITS: begin
                    tx <= tx_data_reg[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= TX_STOP_BIT;
                        end
                    end
                end
                TX_STOP_BIT: begin
                    tx <= 1'b1;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        tx_done <= 1'b1;
                        state <= CLEANUP;
                    end
                end
                CLEANUP: begin
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// Serializes a 72-bit event into 9 UART bytes
// Format (Big Endian): {Timestamp[31:0] (4B), CoreID[7:0] (1B), Data[31:0] (4B)}
module event_serializer #(
    parameter CLKS_PER_BIT = 87
)(
    input wire clk,
    input wire rst_n,
    
    // Interface to Watchpoint FIFO
    input wire [71:0] event_data,
    input wire event_valid,
    output reg event_ready,
    
    // External UART TX pin
    output wire uart_tx
);

    wire tx_done;
    wire tx_active;
    reg tx_start;
    reg [7:0] tx_byte;
    
    uart_tx_byte #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_byte),
        .tx(uart_tx),
        .tx_done(tx_done),
        .tx_active(tx_active)
    );
    
    reg [3:0] byte_idx;
    reg [71:0] current_event;
    
    parameter IDLE = 0, SEND = 1, WAIT_DONE = 2;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            event_ready <= 0;
            tx_start <= 0;
            byte_idx <= 0;
        end else begin
            tx_start <= 0;
            event_ready <= 0;
            
            case (state)
                IDLE: begin
                    if (event_valid) begin
                        current_event <= event_data;
                        event_ready <= 1; // Pop from FIFO
                        byte_idx <= 0;
                        state <= SEND;
                    end
                end
                SEND: begin
                    if (!tx_active && !tx_start) begin
                        // Select byte to send (Big Endian)
                        case (byte_idx)
                            0: tx_byte <= current_event[71:64];
                            1: tx_byte <= current_event[63:56];
                            2: tx_byte <= current_event[55:48];
                            3: tx_byte <= current_event[47:40];
                            4: tx_byte <= current_event[39:32]; // Core ID
                            5: tx_byte <= current_event[31:24];
                            6: tx_byte <= current_event[23:16];
                            7: tx_byte <= current_event[15:8];
                            8: tx_byte <= current_event[7:0];
                            default: tx_byte <= 8'h00;
                        endcase
                        tx_start <= 1;
                        state <= WAIT_DONE;
                    end
                end
                WAIT_DONE: begin
                    if (tx_done) begin
                        if (byte_idx == 8) begin
                            state <= IDLE; // Done with all 9 bytes
                        end else begin
                            byte_idx <= byte_idx + 1;
                            state <= SEND; // Next byte
                        end
                    end
                end
            endcase
        end
    end

endmodule
