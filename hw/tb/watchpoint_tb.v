`timescale 1ns / 1ps

module watchpoint_tb;

    reg clk;
    reg rst_n;
    wire uart_tx;
    
    // Instantiate the SoC
    multicore_soc #(
        .WATCH_ADDR(32'h0000_1000),
        .CLKS_PER_BIT(4) // Fast simulation
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_tx(uart_tx)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        $dumpfile("watchpoint_tb.vcd");
        $dumpvars(0, watchpoint_tb);
        
        rst_n = 0;
        #20 rst_n = 1;
        
        // Wait long enough to see some UART traffic
        #10000;
        
        $finish;
    end

endmodule
