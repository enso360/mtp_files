`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
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
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module column_adder #(
    parameter INPUT_WIDTH = 6,
    parameter NUM_SEQ_INPUTS = 8
)(
    input clk,
    input clear,
    input signed [INPUT_WIDTH-1:0] in,    // signed input
    input input_valid,
    output reg signed [(INPUT_WIDTH + 1 + NUM_SEQ_INPUTS) - 1:0] column_sum,   //signed 7b addition + 8 bit ASR >>>
	output reg column_sum_ready   //changed from output wire to output reg
);

	//state definition 
	localparam IDLE  		= 2'b00,
			   PROCESSING   = 2'b01,
			   DONE 		= 2'b10;
    reg [1:0] state, next_state;
	
    // Internal parameter for output width
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;  // e.g., 6+1+8 = 15
    localparam EXT_IN_WIDTH = INPUT_WIDTH + 1;  //sign extended input of 7 bits

	localparam COUNTER_WIDTH = $clog2(NUM_SEQ_INPUTS+1);
	reg [COUNTER_WIDTH-1:0] iteration_count;
	
	// reg last_input_processed;
	// reg signed [SUM_WIDTH] temp_sum;
	
    //Combinational signals
    wire signed [EXT_IN_WIDTH-1:0] extended_input;
	assign extended_input = {in[INPUT_WIDTH-1], in};  // sign-extend 6 bit input to 7 bits for addition 

	wire signed [EXT_IN_WIDTH-1:0] sum_higher_bits;  //7bits
	wire signed [SUM_WIDTH-EXT_IN_WIDTH-1:0] sum_lower_bits;  //8bits
	
	assign sum_higher_bits = column_sum[SUM_WIDTH-1 -: EXT_IN_WIDTH];  //column_sum[14:7]
	assign sum_lower_bits = column_sum[SUM_WIDTH-EXT_IN_WIDTH-1:0];	   //column_sum[7:0]
	
	//add extended_input to MSBs of column_sum reg  //sliced adder 
	wire signed [EXT_IN_WIDTH-1:0] updated_sum_higher_bits;  //7bits
	assign updated_sum_higher_bits = sum_higher_bits + extended_input;  //sliced addition //synthesize 2 input 7 bit comb adder
	
	//update column sum 
	wire signed [SUM_WIDTH-1:0] updated_sum;
	assign updated_sum = {updated_sum_higher_bits, sum_lower_bits};
	
	wire signed [SUM_WIDTH-1:0] shifted_sum;
	assign shifted_sum = updated_sum >>> 1; //arithmetic shift right by 1, preserve msb sign bit
	
	//last input condition
	wire last_input_flag;
	assign last_input_flag = (iteration_count == 0);  
	
	// //input processing condition
	// wire processing_flag;
	// assign processing_flag = (!last_valid_input_flag && input_valid && (iteration_count > 0));
	
    // //Combinational logic for ready signal
    // // assign column_sum_ready = last_input_processed;
	// assign column_sum_ready = (state == DONE);


	// FSM Process 1: State and data registers (sequential logic)
	always @(posedge clk) begin 
		if (clear) begin //synchronous clear 
			state <= IDLE; 
			column_sum <= 0;
			column_sum_ready <= 0;
			iteration_count <= NUM_SEQ_INPUTS - 1; //down counter 7 to 0
		end else begin 
			state <= next_state; //default state assignment 
			
			// Data path updates based on current state
			case (state) 
				IDLE: begin 
					column_sum <= 0; 
					column_sum_ready <= 0;
					iteration_count <= NUM_SEQ_INPUTS - 1; 
				end
				
				PROCESSING: begin 
					//update sum if input valid 
					if (input_valid) begin 
						//arithmetic shift right by 1, preserve msb sign bit
						// column_sum <= updated_sum >>> 1; 
						column_sum <= shifted_sum;					
						iteration_count <= iteration_count - 1;
					end else begin 
						// Hold current value
						column_sum <= column_sum;
					end 
					
					column_sum_ready <= 0;
				end 
				
				DONE: begin 
					// Hold current value in DONE state 
					column_sum <= column_sum;
					column_sum_ready <= 1;
				end 

				default: begin 
					column_sum <= 0; 
					column_sum_ready <= 0;
					iteration_count <= NUM_SEQ_INPUTS - 1;
				end 
			endcase 
		end 
	end 

	// FSM Process 2: Next state and output logic (combinational logic)
	always @(*) begin 
		//default assignment
		next_state = state; 
		
		case (state) 
			IDLE: begin 
					next_state = (input_valid) ? PROCESSING : IDLE;
				end 
				
			PROCESSING: begin 
				if (last_input_flag) begin 
					next_state = DONE;
				end else begin 
					// Stay in processing state
					next_state = PROCESSING;
				end 
			end 
			
			DONE: begin 
				// Stay in done state until external clear applied 
				next_state = DONE;
			end 
			
			default: begin 
				next_state = IDLE;
			end 
		endcase 
	end 
	
endmodule 
