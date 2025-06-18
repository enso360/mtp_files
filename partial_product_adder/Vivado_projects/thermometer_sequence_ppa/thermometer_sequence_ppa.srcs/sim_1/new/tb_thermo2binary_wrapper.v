`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: tb_thermo2binary_wrapper
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

module tb_thermo2binary_wrapper();
    parameter SERIAL_INPUT_LENGTH = 33;  // 32 bits + 1 sign bit
    parameter T2B_OUT_WIDTH = 6;         // 1-bit sign + 5-bit magnitude
    parameter CLK_PERIOD = 20;           // Clock period in ns
    
    reg clk;
    reg reset;
    
    reg thermo_start;
    reg thermo_serial_in;
    wire thermo_valid_out;
    wire signed [T2B_OUT_WIDTH-1:0] signed_result_out;

	reg TB_DONE = 0;
	
    // Instantiate the updated wrapper module
    thermo2binary_wrapper #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH),
        .T2B_OUT_WIDTH(T2B_OUT_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(thermo_start),
        .serial_in(thermo_serial_in),
        .valid_out(thermo_valid_out),
        .signed_result_out(signed_result_out)
    );

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task to send a 33-bit thermometer code with sign bit as LSB (inverted)
    task send_pattern;
        input [32:0] pattern;
        input [64:0] pattern_name;
        integer i;
        begin
            @(posedge clk);
            $display("Sending pattern %s: %b", pattern_name, pattern);
            // Send the start signal and first bit (sign)
            thermo_start <= 1;  //Non-blocking update inside a task after clk edge
			
            @(posedge clk);
			thermo_serial_in <= pattern[0]; // inverted sign	//Non-blocking update inside a task after clk edge			
			thermo_start <= 0;
				
            // Send remaining bits
            for (i = 1; i < SERIAL_INPUT_LENGTH; i = i + 1) begin
                @(posedge clk);				
                thermo_serial_in <= pattern[i];	//Non-blocking update inside a task after clk edge			
            end

            // Idle input
            @(posedge clk);
            thermo_serial_in <= 0;

            wait(thermo_valid_out);

            $display("Pattern %s complete: result=%0d", 
                     pattern_name, $signed(signed_result_out));

            #50;
        end
    endtask

    // Main test sequence
    initial begin
        clk = 0;
        reset = 1;
        thermo_start = 0;
        thermo_serial_in = 0;

        #40;
        reset = 0;
        #40;

        send_pattern(33'b00000000000000000000000000001111_1, "Positive 4");
        send_pattern(33'b00000000000000000000000000000111_1, "Positive 3");
        send_pattern(33'b00000000000000000000000000000011_1, "Positive 2");
        send_pattern(33'b01111111111111111111111111111111_0, "Negative 1");

        #200;
		
		TB_DONE = 1; 
		#50;
		
        $display("Testbench completed");
        $finish;
    end

endmodule

