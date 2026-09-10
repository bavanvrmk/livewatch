`timescale 1ns / 1ps

// Top-level module showing integration of Watchpoint IP on a shared bus
module multicore_soc #(
    parameter WATCH_ADDR = 32'h0000_1000,
    parameter CLKS_PER_BIT = 87
)(
    input wire clk,
    input wire rst_n,
    output wire uart_tx
);

    // Simulated shared memory bus
    wire [31:0] bus_addr;
    wire [31:0] bus_wdata;
    wire bus_we;
    wire [3:0]  bus_core_id;

    // Watchpoint IP Instantiation
    wire [71:0] event_data;
    wire event_valid;
    wire event_ready;

    watchpoint #(
        .WATCH_ADDR(WATCH_ADDR),
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .CORE_ID_WIDTH(4),
        .TS_WIDTH(32)
    ) watchpoint_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_we(bus_we),
        .bus_core_id(bus_core_id),
        .event_data(event_data),
        .event_valid(event_valid),
        .event_ready(event_ready)
    );

    // UART Serializer for Watchpoint events
    event_serializer #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) serializer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .event_data(event_data),
        .event_valid(event_valid),
        .event_ready(event_ready),
        .uart_tx(uart_tx)
    );

    // ---- MOCK CORES FOR DEMONSTRATION ----
    // In a real system, these would be PicoRV32 cores connected to an arbiter.
    
    reg [31:0] core0_addr, core1_addr;
    reg [31:0] core0_wdata, core1_wdata;
    reg core0_we, core1_we;
    
    reg [7:0] counter0, counter1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter0 <= 0;
            counter1 <= 0;
            core0_we <= 0;
            core1_we <= 0;
        end else begin
            counter0 <= counter0 + 1;
            counter1 <= counter1 + 1;
            
            // Core 0 writes every 256 cycles
            if (counter0 == 8'hFF) begin
                core0_addr <= WATCH_ADDR;
                core0_wdata <= 32'hAAAA_0000 + counter1; // some data
                core0_we <= 1;
            end else begin
                core0_we <= 0;
            end
            
            // Core 1 writes with a slight offset
            if (counter1 == 8'h80) begin
                core1_addr <= WATCH_ADDR;
                core1_wdata <= 32'hBBBB_0000 + counter0;
                core1_we <= 1;
            end else begin
                core1_we <= 0;
            end
        end
    end

    // Simple Bus Arbiter Mock
    assign bus_addr = core0_we ? core0_addr : (core1_we ? core1_addr : 32'h0);
    assign bus_wdata = core0_we ? core0_wdata : (core1_we ? core1_wdata : 32'h0);
    assign bus_we = core0_we | core1_we;
    assign bus_core_id = core0_we ? 4'd0 : (core1_we ? 4'd1 : 4'd0);

endmodule
