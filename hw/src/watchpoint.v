`timescale 1ns / 1ps

module watchpoint #(
    parameter WATCH_ADDR = 32'h0000_1000,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter CORE_ID_WIDTH = 4,
    parameter TS_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    
    // Snooped Bus interface
    input wire [ADDR_WIDTH-1:0] bus_addr,
    input wire [DATA_WIDTH-1:0] bus_wdata,
    input wire bus_we,
    input wire [CORE_ID_WIDTH-1:0] bus_core_id,
    
    // Output FIFO interface
    output wire [71:0] event_data, // {timestamp (32), core_id (8), data (32)}
    output wire event_valid,
    input  wire event_ready
);

    reg [TS_WIDTH-1:0] timestamp;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp <= 0;
        end else begin
            timestamp <= timestamp + 1;
        end
    end

    // Match logic
    wire addr_match = (bus_addr == WATCH_ADDR);
    wire capture_event = bus_we & addr_match;

    // FIFO instantiation (simple synchronous FIFO)
    wire fifo_full;
    wire fifo_empty;
    
    assign event_valid = !fifo_empty;
    
    // A simple 16-entry FIFO
    reg [71:0] fifo_mem [0:15];
    reg [3:0] rd_ptr;
    reg [3:0] wr_ptr;
    reg [4:0] count;
    
    assign fifo_empty = (count == 0);
    assign fifo_full  = (count == 16);
    
    assign event_data = fifo_mem[rd_ptr];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            count <= 0;
        end else begin
            if (capture_event && !fifo_full && event_ready && !fifo_empty) begin
                // Read and write simultaneously
                fifo_mem[wr_ptr] <= {timestamp, {8-CORE_ID_WIDTH{1'b0}}, bus_core_id, bus_wdata};
                wr_ptr <= wr_ptr + 1;
                rd_ptr <= rd_ptr + 1;
            end else if (capture_event && !fifo_full) begin
                // Write only
                fifo_mem[wr_ptr] <= {timestamp, {8-CORE_ID_WIDTH{1'b0}}, bus_core_id, bus_wdata};
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end else if (event_ready && !fifo_empty) begin
                // Read only
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

endmodule
