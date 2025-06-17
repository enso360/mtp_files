`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: tb_thermo2binary
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

module tb_thermo2binary();
    parameter SERIAL_INPUT_LENGTH = 33;  // 32 bits + 1 sign bit
    // parameter DATA_WIDTH = 6;           // Width for partial product adder
    parameter CLK_PERIOD = 20;          // Clock period in ns
    
    reg clk;
    reg rst;
    
    // Thermometer module signals
    reg thermo_start;
    reg thermo_serial_in;
    wire thermo_valid_out;
    wire [$clog2(SERIAL_INPUT_LENGTH - 1) - 1:0] sum_magnitude_out;
    wire signed [$clog2(SERIAL_INPUT_LENGTH - 1):0] signed_result_out;
    
	reg TB_DONE = 0; 
	
    // Instantiate thermo2binary module
    thermo2binary #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH)
    ) dut_t2b (
        .clk(clk),
        .rst(rst),
        .start(thermo_start),
        .serial_in(thermo_serial_in),
        .valid_out(thermo_valid_out),
        .sum_magnitude_out(sum_magnitude_out),
        .signed_result_out(signed_result_out)
    );
    
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task to send a 33-bit pattern with sign bit at LSB
    task send_pattern;
        input [32:0] pattern;
        input [64:0] pattern_name;
        integer i;
        begin
		
			@(posedge clk);
            $display("Sending pattern %s: %b", pattern_name, pattern);
            
            // Assert start and send the first bit (Inverted sign bit)
			thermo_start = 1;	
			thermo_serial_in = pattern[0];  // Inverted Sign bit at position 0				
			@(posedge clk);
			#5;
            thermo_start = 0;
			// @(posedge clk);
			// #5;
			
            // Send remaining bits one by one
            for (i = 1; i < (SERIAL_INPUT_LENGTH); i = i + 1) begin  //todo //hack
				@(posedge clk);
                thermo_serial_in = pattern[i];
            end
            
			// @(posedge clk);
			#5;
			thermo_serial_in = 0;  //diable serial input to prevent invalid computation  //todo
			
            wait(thermo_valid_out); 
            
            $display("Pattern %s complete: sum=%0d, result=%0d", 
                     pattern_name, sum_magnitude_out, $signed(signed_result_out));
            
            // Add delay between patterns
            #50;
        end
    endtask
    
    // Main test procedure
    initial begin
        
        clk = 0;
        rst = 1;
        thermo_start = 0;
        thermo_serial_in = 0;

        
        // Reset sequence
        #20;
        rst = 0;
        #20;
        
        // Test Patterns: 
        send_pattern(33'b00000000000000000000000000001111_1, "Positive 4");  //+4   			//running sum = 4
		wait(thermo_valid_out);
		// @(posedge clk);
		// pp_valid = 1;
		// @(posedge clk);
		// pp_valid = 0;
        #20;

        send_pattern(33'b00000000000000000000000000000111_1, "Positive 3");  //+3 * 2 = +6     //running sum = 10
		wait(thermo_valid_out);
		// @(posedge clk);
		// pp_valid = 1;
		// @(posedge clk);
		// pp_valid = 0;
        #20;

        send_pattern(33'b00000000000000000000000000000011_1, "Positive 2");  //+2 * 4 = +8     //running sum = 18
		wait(thermo_valid_out);
		// @(posedge clk);
		// pp_valid = 1;
		// @(posedge clk);
		// pp_valid = 0;
        #20;
		
        send_pattern(33'b01111111111111111111111111111111_0, "Negative 1");  //-1 * 8 = -8	   //running sum = 10
		wait(thermo_valid_out);
		// @(posedge clk);
		// pp_valid = 1;
		// @(posedge clk);
		// pp_valid = 0;
        #20;		
        
		#1000;
		// //apply clear on ppa
		// pp_clear = 1;
		// #20;
		// pp_clear = 0;
		// #20; 
		
		TB_DONE = 1; 
		#50;
		
        $display("Testbench completed");
        $finish;
    end
    

endmodule

