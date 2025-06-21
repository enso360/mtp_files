`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: column_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: FSM control logic moved to column_adder_array wrapper
// 
//////////////////////////////////////////////////////////////////////////////////

module column_adder #(
    parameter INPUT_WIDTH = 6,
    parameter NUM_SEQ_INPUTS = 8
)(
    input clk,
    input clear,
    input signed [INPUT_WIDTH-1:0] sequential_sum_in,    // input port
	input load_input,
    input enable_accumulation,
    output reg signed [(INPUT_WIDTH + 1 + NUM_SEQ_INPUTS) - 1:0] column_sum   //signed 7b addition + 8 bit ASR >>>
);

	
    // Internal parameter for output width
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;  // e.g., 6+1+8 = 15
    localparam EXT_IN_WIDTH = INPUT_WIDTH + 1;  //sign extended input of 7 bits

	/** Combinational logic for Sequential Sliced Addition  **/ 
	// Emulates left shifting of next partial product by right shifting the accumulator instead
	reg signed [INPUT_WIDTH-1:0] input_reg;  //to store new inputs 		
    wire signed [EXT_IN_WIDTH-1:0] extended_input;

	wire signed [EXT_IN_WIDTH-1:0] sum_higher_bits;  //7bits
	wire signed [SUM_WIDTH-EXT_IN_WIDTH-1:0] sum_lower_bits;  //8bits
	
	wire signed [EXT_IN_WIDTH-1:0] updated_sum_higher_bits;  //7bits
	wire signed [SUM_WIDTH-1:0] updated_sum;  //15bits pre shifted column sum
	wire signed [SUM_WIDTH-1:0] shifted_sum;  //15btis right shifted column sum 
	
	assign extended_input = {input_reg[INPUT_WIDTH-1], input_reg};  	// sign-extend 6 bit input to 7 bits for addition 	
	assign sum_higher_bits = column_sum[SUM_WIDTH-1 -: EXT_IN_WIDTH];  //column_sum[14:7]
	assign sum_lower_bits = column_sum[SUM_WIDTH-EXT_IN_WIDTH-1:0];	   //column_sum[7:0]
	
	//add extended_input to MSBs of column_sum reg  
	//sliced addition //synthesize 2 input 7 bit comb adder
	assign updated_sum_higher_bits = sum_higher_bits + extended_input;
	// //Continuous assignment with ternary
	// assign updated_sum_higher_bits = enable_addition ? (sum_higher_bits + extended_input) : sum_higher_bits;
	
	assign updated_sum = {updated_sum_higher_bits, sum_lower_bits}; 	//update pre shifted column sum	
	//shifted_sum contains the pre-computed additon value
	assign shifted_sum = updated_sum >>> 1; 							//arithmetic shift right by 1, preserve msb sign bit
 

	//Sequential accumulation 
	always @(posedge clk) begin
		if (clear) begin //synchronous clear 
			input_reg <= 0;
			column_sum <= 0;			
		end 
		else begin 
			//external FSM will ensure mutually exclusive conditions 
			if (load_input) begin 
				input_reg <= sequential_sum_in;
			end 
			
			if (enable_accumulation) begin 
				column_sum <= shifted_sum;  //update accumulator with pre-computed additon value
			end 
		end 		
	end 
endmodule 
