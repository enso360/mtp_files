`timescale 1ns/1ps

module uart_loopback_tb();
    // Testbench parameters
    localparam CLOCK_FREQ = 50_000_000;
    localparam CLK_PERIOD = 20;  // 50 MHz clock (1/50M = 20ns)
    localparam BAUD_RATE = 115200;
    parameter DATA_BITS = 8;

    // Testbench signals
    reg         clk;
    reg         rst;
    reg [7:0]   tx_data;
    reg         tx_valid;
    wire        tx_ready;
    wire        tx_pin;       // TX output, connects to RX input
    wire        tx_baud_tick;
    wire        rx_baud_tick;
    wire        rx_ready;
    wire [7:0]  rx_data;
    wire        rx_error;

    // Instantiate Baud Rate Generator
    baud_rate_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .rst(rst),
        .tx_baud_tick(tx_baud_tick),
        .rx_baud_tick(rx_baud_tick)
    );

    // Instantiate UART Transmitter
    uart_transmitter #(
        .DATA_BITS(DATA_BITS)
    ) uart_tx (
        .clk(clk),
        .rst(rst),
        .tx_baud_tick(tx_baud_tick),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_pin(tx_pin)
    );

    // Instantiate UART Receiver - connect TX pin to RX input
    uart_receiver #(
        .DATA_BITS(DATA_BITS)
    ) uart_rx (
        .clk(clk),
        .rst(rst),
        .rx_baud_tick(rx_baud_tick),
        .rx_in(tx_pin),        // Connect to TX output
        .rx_ready(rx_ready),
        .rx_data(rx_data),
        .rx_error(rx_error)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Monitor for received data
    always @(posedge clk) begin
        if (rx_ready)
            $display("Time: %t, Received data: 0x%h", $time, rx_data);
    end

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        tx_data = 8'h00;
        tx_valid = 0;

        // Reset sequence
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 10);

        // Test Case 1: Send 0x55
        $display("Test Case 1: Sending 0x55");
        tx_data = 8'h55;
        tx_valid = 1;
        wait(tx_ready == 0);  // Wait until transmitter accepts data
        tx_valid = 0;
        
        // Wait for reception
        wait(rx_ready);
        #(CLK_PERIOD * 5);
        
        if (rx_data === 8'h55)
            $display("PASS: Received correct data 0x%h", rx_data);
        else
            $display("FAIL: Expected 0x55, Received 0x%h", rx_data);

        // Wait for transmitter to be ready again
        wait(tx_ready);
        #(CLK_PERIOD * 20);

        // Test Case 2: Send 0xA3
        $display("Test Case 2: Sending 0xA3");
        tx_data = 8'hA3;
        tx_valid = 1;
        wait(tx_ready == 0);
        tx_valid = 0;
        
        // Wait for reception
        wait(rx_ready);
        #(CLK_PERIOD * 5);
        
        if (rx_data === 8'hA3)
            $display("PASS: Received correct data 0x%h", rx_data);
        else
            $display("FAIL: Expected 0xA3, Received 0x%h", rx_data);

        // Wait for transmitter to be ready again
        wait(tx_ready);
        #(CLK_PERIOD * 20);

        // Test Case 3: Send 0xFF
        $display("Test Case 3: Sending 0xFF");
        tx_data = 8'hFF;
        tx_valid = 1;
        wait(tx_ready == 0);
        tx_valid = 0;
        
        // Wait for reception
        wait(rx_ready);
        #(CLK_PERIOD * 5);
        
        if (rx_data === 8'hFF)
            $display("PASS: Received correct data 0x%h", rx_data);
        else
            $display("FAIL: Expected 0xFF, Received 0x%h", rx_data);

        // Test Case 4: Send back-to-back data (0x12, 0x34)
        wait(tx_ready);
        #(CLK_PERIOD * 20);
        
        $display("Test Case 4: Sending back-to-back data 0x12, 0x34");
        
        // Send first byte
        tx_data = 8'h12;
        tx_valid = 1;
        wait(tx_ready == 0);
        tx_valid = 0;
        
        // Wait for reception of first byte
        wait(rx_ready);
        #(CLK_PERIOD * 5);
        
        if (rx_data === 8'h12)
            $display("PASS: First byte - Received correct data 0x%h", rx_data);
        else
            $display("FAIL: First byte - Expected 0x12, Received 0x%h", rx_data);
        
        // Send second byte immediately when tx_ready
        wait(tx_ready);
        tx_data = 8'h34;
        tx_valid = 1;
        wait(tx_ready == 0);
        tx_valid = 0;
        
        // Wait for reception of second byte
        wait(rx_ready);
        #(CLK_PERIOD * 5);
        
        if (rx_data === 8'h34)
            $display("PASS: Second byte - Received correct data 0x%h", rx_data);
        else
            $display("FAIL: Second byte - Expected 0x34, Received 0x%h", rx_data);

        // Finish simulation
        #(CLK_PERIOD * 100);
        $display("UART Loopback Testbench Complete");
        $finish;
    end

    // Monitor key signals
    initial begin
        $monitor("Time: %t, TX: %b, TX Ready: %b, RX Ready: %b, RX Data: 0x%h, RX Error: %b",
                 $time, tx_pin, tx_ready, rx_ready, rx_data, rx_error);
    end

    // Dump waveforms
    initial begin
        $dumpfile("uart_loopback_tb.vcd");
        $dumpvars(0, uart_loopback_tb);
    end
endmodule
