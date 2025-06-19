`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: tb_thermo2binary_array_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_thermo2binary_array_wrapper();
    parameter SERIAL_INPUT_LENGTH = 33;  // 32 bits + 1 sign bit
    parameter T2B_OUT_WIDTH = 6;         // 1-bit sign + 5-bit magnitude
	parameter NUM_COLUMNS = 8;
	
    parameter CLK_PERIOD = 20;           // Clock period in ns
    
    reg clk;	//common 
    reg reset;	//common
    reg thermo_start;  //common 
	// A packed array for input data
    reg [NUM_COLUMNS-1:0] thermo_serial_in_array;  //serial_in bits 
	// 2D Packed array for output
    wire signed [NUM_COLUMNS-1:0][T2B_OUT_WIDTH-1:0] signed_result_out_array;	
    wire thermo_valid_out;  //common

	reg TB_DONE = 0;
	
    // Instantiate the thermo2binary_array_wrapper module
    thermo2binary_array_wrapper #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH),
        .T2B_OUT_WIDTH(T2B_OUT_WIDTH),
		.NUM_COLUMNS(NUM_COLUMNS)
    ) dut_thermo2binary_array_wrapper (
        .clk(clk),
        .reset(reset),
        .start(thermo_start),
        .serial_in_array(thermo_serial_in_array),
        .signed_result_out_array(signed_result_out_array),
        .valid_out(thermo_valid_out)		
    );

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task to send a 33-bit thermometer code with sign bit as 1st bit  (inverted)
	// pass the same serial bits to all 8 parallel t2b core modules for simple testing
    task send_pattern;
        input [32:0] pattern;
        input [64:0] pattern_name;
        integer i, j;
        begin
            @(posedge clk);
            $display("Sending pattern %s: %b", pattern_name, pattern);
            // Send the start signal and first bit (inverted sign bit)
            thermo_start <= 1;  //Non-blocking update inside a task after clk edge
			
            @(posedge clk);
			for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
				thermo_serial_in_array[j] <= pattern[0]; /// Inverted Sign bit at position 0	//Non-blocking update inside a task after clk edge			
			end 
			thermo_start <= 0;
				
            // Send remaining bits
            for (i = 1; i < SERIAL_INPUT_LENGTH; i = i + 1) begin
                @(posedge clk);				
                for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
					thermo_serial_in_array[j] <= pattern[i];	//Non-blocking update inside a task after clk edge			
				end 
			end

            // Idle input
            @(posedge clk);
				for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
					thermo_serial_in_array[j] <= 0;
				end 

            wait(thermo_valid_out);
            // #50;
        end
    endtask

	
	integer j;
		
    // Main test sequence
    initial begin
		// Initialize signals
        clk = 0;
        reset = 1;
        thermo_start = 0;
		//initialize all serial input bits to 0
		// thermo_serial_in_array = 0;	
		for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
			thermo_serial_in_array[j] = 0;
		end 
		
		// Reset sequence
		reset = 1;
		repeat (2) @(posedge clk);
		reset = 0;
		repeat (2) @(posedge clk);

        $display("Starting testbench");
        $display("SERIAL_INPUT_LENGTH = %0d, T2B_OUT_WIDTH = %0d, NUM_COLUMNS = %0d", 
         SERIAL_INPUT_LENGTH, T2B_OUT_WIDTH, NUM_COLUMNS);
		
		// Test Patterns: //pass the same serial bits to all 8 parallel t2b core modules for simple testing
        send_pattern(33'b00000000000000000000000000001111_1, "Positive 4");  //+4
		#20;
        send_pattern(33'b00000000000000000000000000000111_1, "Positive 3");  //+3
		#20;
        send_pattern(33'b00000000000000000000000000000011_1, "Positive 2");  //+2
		#20;
        send_pattern(33'b01111111111111111111111111111111_0, "Negative 1");  //-1
		#20;
        // Test maximum positive value +31
        send_pattern(33'b01111111111111111111111111111111_1, "Positive 31"); // +31
        #20;
		// Test maximum negative value -32
        send_pattern(33'b00000000000000000000000000000000_0, "Negative 32");  // -32
        #20;
		// Test 32 bits 0s, sign 1
        send_pattern(33'b00000000000000000000000000000000_1, "Test 32 bits 0s, sign 1");  //+0
        #20;
		// Test 32 bits 0s, sign 0
        send_pattern(33'b00000000000000000000000000000000_0, "Test 32 bits 0s, sign 0"); //-32
        #20;
		// Test 32 bits 1s, sign 1
        send_pattern(33'b11111111111111111111111111111111_1, "Test 32 bits 1s, sign 1"); //positive overflow +32 = +0
        #20;
		// Test 32 bits 1s, sign 0
        send_pattern(33'b11111111111111111111111111111111_0, "Test 32 bits 1s, sign 0"); //negative overflow -0 = -32 
        #20;
		
        #500;
		
		TB_DONE = 1; 
		#500;
		
        $display("Testbench completed");
        $finish;
    end

	
endmodule
