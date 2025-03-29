`timescale 1ns / 1ps

module baud_rate_generator_tb();

    parameter CLOCK_FREQ = 50_000_000; // 50 MHz clock
    // parameter BAUD_RATE = 460800;
    parameter BAUD_RATE = 115200;	

    // Derived parameter
    localparam CLOCK_PERIOD = 1000_000_000 / CLOCK_FREQ; // in ns
	// localparam CLOCK_PERIOD = 20;

    // Signals
    reg clk;
    reg rst;
    wire tx_baud_tick;	//tx
    wire rx_baud_tick;	//rx
	
    baud_rate_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
		.tx_baud_tick(tx_baud_tick),
        .rx_baud_tick(rx_baud_tick)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
		// forever #10 clk = ~clk;
    end

    // Testbench initial block
    initial begin
        // Initialize signals
        clk = 1'b0;
        rst = 1'b1;

        // Reset the BRG
        @(posedge clk);
        rst = 1'b0;

        // Monitor the rx_baud_tick signal
        $display("Time \t rx_baud_tick \t baud_tick_count");
        $monitor("%0t \t %b \t %d", $time, rx_baud_tick, baud_tick_count);
        // $monitor("%0t %d", $time, baud_tick_count);

        // Run the simulation for 1 ms
        // #(2*1000000);

        // Wait for completion
        wait(local_done);
        #10;
		
        $finish;
    end

    // Assertions: verify baud rate period and freq 
    reg [15:0] baud_tick_count;
	reg local_done;
	
    real baud_tick_freq;
	real baud_tick_period;
	
	real generated_baud_rate;

	real tick_start_time;
	real tick_end_time;
	real tick_duration_ns;

    initial begin
        baud_tick_count = 0;
		local_done = 0;
    end

    always @(posedge rx_baud_tick) begin
        baud_tick_count <= baud_tick_count + 1;
    end
	
	always @(posedge rx_baud_tick) begin
		if (baud_tick_count == 0) begin
			tick_start_time = $time;
		end
		else if (baud_tick_count == 10) begin
			tick_end_time = $time;
			tick_duration_ns = (tick_end_time - tick_start_time) * 1.0;
			baud_tick_period = tick_duration_ns / 10.0 / 1000.0; //in microseconds
			// baud_tick_freq = 10.0 / (tick_duration_ns / 1000000.0); // in kHz
			baud_tick_freq = 1.0 / (baud_tick_period / 1000000.0); // in Hz
			generated_baud_rate = baud_tick_freq/16; //in Hz
			$display("Baud tick period: %.2f uSecs", baud_tick_period);
			$display("Baud tick frequency: %.2f Hz", baud_tick_freq);
			$display("Desired Baud rate: %d Hz \n Generated Baud rate: %.2f Hz", BAUD_RATE, generated_baud_rate);
			baud_tick_count <= 0;
			// local_done <= 1
		end
		else if (baud_tick_count == 500) begin 
			local_done <= 1;
		end
	end

    // Waveform dumping
    initial begin
        $dumpfile("baud_rate_generator_waveform.vcd");
        $dumpvars(0, baud_rate_generator_tb);
    end
	
endmodule


