`timescale 1ns/1ps

module uart_transmitter_tb();
    // Testbench parameters
    localparam CLK_PERIOD = 20;  // 50 MHz clock (1/50M = 20ns)
    // localparam BAUD_RATE = 115200;
    localparam BAUD_RATE = 921600;
    localparam CLOCK_FREQ = 50_000_000;

    // Testbench signals
    reg         clk;
    reg         rst;
    reg [7:0]   tx_data;  //PISO
    reg         tx_valid;
    wire        tx_ready;
    wire        tx_pin;

    // Expected bit sequence storage
    reg [9:0]   expected_frame;  // 1 start + 8 data + 1 stop
    reg [3:0]   bit_count;
    reg         frame_received;

    // Device Under Test
    uart_transmitter #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
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

/*
    // Bit capture and verification logic
    always @(posedge clk) begin
        if (tx_valid && tx_ready) begin
            // Prepare expected frame when data is sent
            expected_frame <= {1'b1, tx_data, 1'b0};  // Stop + Data + Start
            bit_count <= 4'd0;
            frame_received <= 1'b0;
        end else if (bit_count < 10) begin
            // Capture transmitted bits
            if (bit_count == 4'd0 && tx_pin == 1'b0) begin
                // Start bit detected
                bit_count <= bit_count + 1'b1;
            end else if (bit_count > 0 && bit_count < 9) begin
                // Check data bits
                if (tx_pin !== expected_frame[bit_count-1]) begin
                    $display("ERROR: Bit %d mismatch. Expected %b, Got %b", 
                             bit_count-1, expected_frame[bit_count-1], tx_pin);
                end
                bit_count <= bit_count + 1'b1;
            end else if (bit_count == 9 && tx_pin === 1'b1) begin
                // Stop bit verified
                $display("Frame transmission complete for data: %h", tx_data);
                frame_received <= 1'b1;
                bit_count <= bit_count + 1'b1;
            end
        end
    end
*/

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        tx_data = 8'h00;
        tx_valid = 0;
        bit_count = 0;
		expected_frame = 0;
        frame_received = 0;

        // Reset sequence
        #(CLK_PERIOD * 2);
        rst = 0;

		wait(tx_ready);  //wait for tx ready 
		// #(CLK_PERIOD);
		#10;
		
        // Test Case 1:
        tx_data = 8'h55;
        tx_valid = 1;
        // #(CLK_PERIOD * 2);
		wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        // Wait for frame transmission
        // wait(frame_received);
		//#(CLK_PERIOD *  CLOCK_FREQ / BAUD_RATE);  
		wait(tx_ready);  //wait for tx ready 

        // Test Case 2: 
        tx_data = 8'hB4;
        tx_valid = 1;
        // #(CLK_PERIOD*2);
		wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        // Wait for frame transmission
        // wait(frame_received);
		// #(CLK_PERIOD *  CLOCK_FREQ / BAUD_RATE);
		wait(tx_ready);  //wait for tx ready 

        // Test Case 3: Multiple back-to-back transmissions
        tx_data = 8'hAA;
        tx_valid = 1;
		wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        // wait(frame_received);
        #(CLK_PERIOD * 5);  //incomplete wait to cause error

        tx_data = 8'hA2;
        tx_valid = 1;
		wait(tx_ready==0); //assert tx_valid high until tx buffer starts trasnmitting
        tx_valid = 0;

        // wait(frame_received);
		wait(tx_ready);  //wait for tx ready 
		
        // Finish simulation
        #(CLK_PERIOD * 10);
        $display("UART Transmitter Testbench Complete");
		
		#10; 
        $finish;
    end

    //Dump waveform 
    initial begin
        $dumpfile("uart_transmitter_tb.vcd");
        $dumpvars(0, uart_transmitter_tb);
    end
endmodule
