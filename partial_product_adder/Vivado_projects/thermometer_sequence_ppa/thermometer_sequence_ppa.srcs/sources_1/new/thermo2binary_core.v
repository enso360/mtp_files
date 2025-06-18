`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: thermo2binary_core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Core thermo2binary conversion module without FSM
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: FSM logic moved to wrapper
// 
//////////////////////////////////////////////////////////////////////////////////

module thermo2binary_core #(
    parameter SERIAL_INPUT_LENGTH = 33,  //32 + 1  //length of serial input thermometer sequence with inverted sign bit as MSB
	parameter T2B_OUT_WIDTH = 6			//1 bit sign + 5 bit magnitude
)(
    input wire clk,           
    input wire rst,           // Active high reset
	
	input wire reset_data,    // Reset data signal from wrapper
	input wire capture_sign,  // Capture sign bit signal from wrapper
    input wire enable,    	  // Enable signal from wrapper 
	input wire latch_data,    // Latch data signal from wrapper
	
    input wire serial_in,             
	output reg signed [T2B_OUT_WIDTH - 1:0] signed_result_out // for final result including sign bit  //6bits
);


	localparam SUM_WIDTH = T2B_OUT_WIDTH - 1;  //5 bits 
		
    // Internal registers
    reg [SUM_WIDTH-1:0] sum_magnitude; // for sum magnitude without sign bit, magnitude of 5 bits binary for 32 levels
	// reg [SUM_WIDTH-1:0] sum_magnitude_next;  //to hold updated sum 

	reg sign_bit_reg;
	// reg sign_bit_reg_next;

    // Datapath registers logic // SystemVerilog approach - clear intent
	// More predictable flip-flop inference with always_ff
	// synchronous reset preferred for ASIC
    // always_ff @(posedge clk) begin
	// Use this for Vivado compatibility
	always @(posedge clk) begin
        if (rst) begin
            sum_magnitude <= 0;
			sign_bit_reg <= 0;
			signed_result_out <= 0;		
            //serial_in_reg <= 0;
        end else begin
            // Reset data when commanded by wrapper
            if (reset_data) begin
				sum_magnitude <= 0;
				sign_bit_reg <= 0;
				// signed_result_out <= 0;
            end            
            // Capture sign bit when commanded by wrapper
            else if (capture_sign) begin
				//invert and save incoming bit in sign bit reg			
                sign_bit_reg <= !serial_in; // Sign bit is received inverted
            end
            // add data bits when adder enabled
            else if (enable) begin
                sum_magnitude <= sum_magnitude + serial_in;  //todo* : zero extend to 5 bits 
            end		
			// Latch data when commanded by wrapper
            else if (latch_data) begin
                signed_result_out <= {sign_bit_reg, sum_magnitude}; //concatenate sign bit to sum_magnitude
            end	
			else begin 
				//sum_magnitude <= 0;
			end 
        end
    end

endmodule
