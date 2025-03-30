`timescale 1ns/1ps

module uart_receiver_tb();
    // Parameters
    parameter CLK_PERIOD = 20;  // 50 MHz clock (20ns)
    parameter BAUD_RATE = 115200;
    parameter DATA_BITS = 8;
    
    // Testbench signals
    reg clk;
    reg rst;
    reg rx_in;
    wire rx_baud_tick;
    wire tx_baud_tick;  // Not used in this test
    wire rx_ready;
    wire [DATA_BITS-1:0] rx_data;
    wire rx_error;
    
    // Instantiate the baud rate generator
    baud_rate_generator #(
        .CLOCK_FREQ(50_000_000),
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
    
    // Task to send a byte with a framing error (missing stop bit)
    task send_uart_byte_frame_error;
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
            
            // Error: Stop bit is low instead of high
            rx_in = 1'b0;
            #(BIT_PERIOD);
            
            // Return to idle state
            rx_in = 1'b1;
            #(BIT_PERIOD);
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize signals
        rx_in = 1'b1;  // Idle state is high
        rst = 1'b1;
        
        // Apply reset
        #(CLK_PERIOD * 10);
        rst = 1'b0;
        #(CLK_PERIOD * 10);
        
        // Test scenario 1: Send a single byte
        $display("Test 1: Sending byte 0x55 (alternating 0 and 1)");
        send_uart_byte(8'h55);
        
        // Wait for reception to complete and check result
        @(posedge rx_ready);
        if (rx_data === 8'h55 && rx_error === 1'b0)
            $display("Test 1 PASSED: Received 0x%h, error = %b", rx_data, rx_error);
        else
            $display("Test 1 FAILED: Received 0x%h, error = %b", rx_data, rx_error);
        
        #(BIT_PERIOD * 2);
        
        // Test scenario 2: Send 0xFF
        $display("Test 2: Sending byte 0xFF (all ones)");
        send_uart_byte(8'hFF);
        
        // Wait for reception to complete and check result
        @(posedge rx_ready);
        if (rx_data === 8'hFF && rx_error === 1'b0)
            $display("Test 2 PASSED: Received 0x%h, error = %b", rx_data, rx_error);
        else
            $display("Test 2 FAILED: Received 0x%h, error = %b", rx_data, rx_error);
        
        #(BIT_PERIOD * 2);
        
        // Test scenario 3: Send 0x00
        $display("Test 3: Sending byte 0x00 (all zeros)");
        send_uart_byte(8'h00);
        
        // Wait for reception to complete and check result
        @(posedge rx_ready);
        if (rx_data === 8'h00 && rx_error === 1'b0)
            $display("Test 3 PASSED: Received 0x%h, error = %b", rx_data, rx_error);
        else
            $display("Test 3 FAILED: Received 0x%h, error = %b", rx_data, rx_error);
        
        #(BIT_PERIOD * 2);
        
        // Test scenario 4: Test framing error
        $display("Test 4: Testing framing error detection");
        send_uart_byte_frame_error(8'hA5);
        
        // Wait for reception to complete and check result
        @(posedge rx_ready);
        if (rx_error === 1'b1)
            $display("Test 4 PASSED: Framing error detected, data = 0x%h", rx_data);
        else
            $display("Test 4 FAILED: Framing error not detected, data = 0x%h, error = %b", rx_data, rx_error);
        
        #(BIT_PERIOD * 2);
        
        // Test scenario 5: Back-to-back data transmission
        $display("Test 5: Testing back-to-back transmission");
        send_uart_byte(8'h33);
        
        // Send the next byte immediately after the stop bit
        @(posedge rx_ready);
        send_uart_byte(8'hCC);
        
        // Wait for reception to complete and check result
        @(posedge rx_ready);
        if (rx_data === 8'hCC && rx_error === 1'b0)
            $display("Test 5 PASSED: Back-to-back received 0x%h, error = %b", rx_data, rx_error);
        else
            $display("Test 5 FAILED: Back-to-back received 0x%h, error = %b", rx_data, rx_error);
        
        #(BIT_PERIOD * 10);
        
        // End simulation
        $display("All tests completed");
        $finish;
    end
    
    // Optional: Monitor the UART receiver outputs
    initial begin
        $monitor("Time: %t, rx_ready: %b, rx_data: 0x%h, rx_error: %b", 
                 $time, rx_ready, rx_data, rx_error);
    end
endmodule
