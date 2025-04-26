`timescale 1ns/1ps

module uart_transmitter_tb();
    // Testbench parameters
    localparam CLOCK_FREQ = 50_000_000;	
    localparam CLK_PERIOD = 20;  // 50 MHz clock (1/50M = 20ns)
    localparam BAUD_RATE = 115200;
    //localparam BAUD_RATE = 921600;
    parameter DATA_BITS = 8;	

    // Testbench signals
    reg         clk;
    reg         rst;
    reg [7:0]   tx_data;  //PISO
    reg         tx_valid;
    wire        tx_ready;
    wire        tx_pin;
    wire        tx_baud_tick;  
    wire        rx_baud_tick;  // Not used by Tx but required by the baud generator

    // Instantiate Baud Rate Generator (moved from transmitter to testbench)
    baud_rate_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .rst(rst),
        .tx_baud_tick(tx_baud_tick),
        .rx_baud_tick(rx_baud_tick)
    );

    uart_transmitter #(
        .DATA_BITS(DATA_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_baud_tick(tx_baud_tick),  // Connect baud tick signal
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_pin(tx_pin)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        tx_data = 8'h00;
        tx_valid = 0;

        // Reset sequence
        #(CLK_PERIOD * 2);
        rst = 0;

        wait(tx_ready);  //wait for tx ready 
        #10;
        
        // Test Case 1:
        tx_data = 8'h55;
        tx_valid = 1;
        wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        // Wait for frame transmission
        wait(tx_ready);  //wait for tx ready 

        // Test Case 2: 
        tx_data = 8'hB4;
        tx_valid = 1;
        wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        // Wait for frame transmission
        wait(tx_ready);  //wait for tx ready 

        // Test Case 3: Multiple back-to-back transmissions
        tx_data = 8'hAA;
        tx_valid = 1;
        wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        #(CLK_PERIOD * 5);  //incomplete wait to cause error

        tx_data = 8'hA2;
        tx_valid = 1;
        wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        wait(tx_ready);  //wait for tx ready 
        
        // Finish simulation
        #(CLK_PERIOD * 10);
        $display("UART Transmitter Testbench Complete");
        
        #10; 
        $finish;
    end

    initial begin
        $dumpfile("uart_transmitter_tb.vcd");
        $dumpvars(0, uart_transmitter_tb);
    end
endmodule
