`timescale 1ns/1ps

module uart_receiver_simple_tb();
    // Parameters
	parameter CLOCK_FREQ = 50_000_000;
    parameter CLK_PERIOD = 20;  // 50 MHz clock (20ns)
    parameter BAUD_RATE = 115200;
    parameter DATA_BITS = 8;
    
    // Testbench signals
    reg clk;
    reg rst;
    reg rx_in;
    wire rx_baud_tick;
    wire tx_baud_tick;
    wire rx_ready;
    wire [DATA_BITS-1:0] rx_data;
    wire rx_error;
    
    // Instantiate the baud rate generator
    baud_rate_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .rst(rst),
        .tx_baud_tick(tx_baud_tick),
        .rx_baud_tick(rx_baud_tick)
    );
    
    // Instantiate the UART receiver
    uart_receiver #(
        .DATA_BITS(DATA_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx_baud_tick(rx_baud_tick),
        .rx_in(rx_in),
        .rx_ready(rx_ready),
        .rx_data(rx_data),
        .rx_error(rx_error)
    );
    
    // Generate clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Calculate bit period based on baud rate
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE;  // in ns
    
    // Task to send a byte over UART
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit (low)
            rx_in = 1'b0;
            #(BIT_PERIOD);
            
            // Data bits (LSB first)
            for (i = 0; i < DATA_BITS; i = i + 1) begin
                rx_in = data[i];
                #(BIT_PERIOD);
            end
            
            // Stop bit (high)
            rx_in = 1'b1;
            #(BIT_PERIOD);
        end
    endtask
    
    // Dump waveforms
    initial begin
        $dumpfile("uart_receiver_tb.vcd");
        $dumpvars(0, uart_receiver_simple_tb);
    end
    
    // Monitor key signals
    initial begin
        $monitor("Time: %t, State: %d, RX_in: %b, RX_ready: %b, RX_data: 0x%h",
                 $time, dut.state, rx_in, rx_ready, rx_data);
    end
    
    // Simple test sequence
    initial begin
        // Initialize signals
        rx_in = 1'b1;  // Idle state is high
        rst = 1'b1;
        
        // Apply reset
        #(CLK_PERIOD * 5);
        rst = 1'b0;
        #(CLK_PERIOD * 5);
        
        // Test case 1: Send byte 0xA5
        $display("Test 1: Sending byte 0xA5 \n");
        send_uart_byte(8'hA5);
        
        // Wait for reception
        wait(rx_ready);  //todo
        if (rx_data === 8'hA5)
            $display("Test 1 PASSED: Received 0x%h \n", rx_data);
        else
            $display("Test 1 FAILED: Received 0x%h \n", rx_data);
        
        #(BIT_PERIOD * 1);
        
        // Test case 2: Send byte 0x3C
        $display("Test 2: Sending byte 0x3C \n");
        send_uart_byte(8'h3C);
        
        // Wait for reception
        wait(rx_ready);
        if (rx_data === 8'h3C)
            $display("Test 2 PASSED: Received 0x%h \n", rx_data);
        else
            $display("Test 2 FAILED: Received 0x%h \n", rx_data);
        
        #(BIT_PERIOD * 2);
        
        // End simulation
        $display("Test completed \n");
        $finish;
    end
endmodule
