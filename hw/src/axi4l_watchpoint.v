`timescale 1ns / 1ps

module axi4l_watchpoint #(
    parameter WATCH_ADDR = 32'h0000_1000,
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 32,
    parameter CLKS_PER_BIT = 87 // UART baud rate parameter
)(
    // System Signals
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    
    // UART TX Output
    output wire uart_tx,

    // AXI4-Lite Slave Interface
    
    // Write Address Channel
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    
    // Write Data Channel
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    
    // Write Response Channel
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    
    // Read Address Channel (Not really used by Watchpoint, but standard AXI4L needs it)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    
    // Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY
);

    // AXI4-Lite Write State Machine
    // We want to capture the address and data when both AWVALID and WVALID are asserted.
    // We can do this in a simplified manner by asserting ready when both are valid.
    
    wire aw_en = S_AXI_AWVALID & S_AXI_WVALID & ~S_AXI_AWREADY & ~S_AXI_WREADY;
    
    assign S_AXI_AWREADY = aw_en;
    assign S_AXI_WREADY  = aw_en;
    
    // Write Response (B Channel)
    reg axi_bvalid;
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (aw_en && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end
    
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_BRESP  = 2'b00; // OKAY
    
    // Read Channel (Tie off, watchpoint is write-only passive)
    assign S_AXI_ARREADY = 1'b1;
    assign S_AXI_RVALID = S_AXI_ARVALID;
    assign S_AXI_RDATA = 32'h0;
    assign S_AXI_RRESP = 2'b00;

    // Map AXI signals to watchpoint core bus signals
    wire [C_S_AXI_ADDR_WIDTH-1:0] bus_addr = S_AXI_AWADDR;
    wire [C_S_AXI_DATA_WIDTH-1:0] bus_wdata = S_AXI_WDATA;
    wire bus_we = aw_en;
    wire [3:0] bus_core_id = 4'd0; // AXI4-Lite does not provide a master ID

    wire [71:0] event_data;
    wire event_valid;
    wire event_ready;

    // Instantiate core IP
    watchpoint #(
        .WATCH_ADDR(WATCH_ADDR),
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .CORE_ID_WIDTH(4),
        .TS_WIDTH(32)
    ) watchpoint_core (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_we(bus_we),
        .bus_core_id(bus_core_id),
        .event_data(event_data),
        .event_valid(event_valid),
        .event_ready(event_ready)
    );

    // UART Transmitter
    event_serializer #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) serializer_inst (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .event_data(event_data),
        .event_valid(event_valid),
        .event_ready(event_ready),
        .uart_tx(uart_tx)
    );

endmodule
