`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: column_adder_array_wrapper
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

module column_adder_array #(
    parameter INPUT_WIDTH = 6,
    parameter NUM_SEQ_INPUTS = 8,
    parameter NUM_COLUMNS = 8,
	FINAL_VECTOR_SUM_WIDTH = 24
)(
    input wire clk,
    input wire clear,
    input wire input_valid,
    
    // A 2D packed array for input data - NUM_COLUMNS x  INPUT_WIDTH - easier to connect and parameterize
    input wire signed [NUM_COLUMNS-1:0][INPUT_WIDTH-1:0] data_in,
    
    // Packed arrays for outputs - NUM_COLUMNS x Sum Width 
    output wire signed [NUM_COLUMNS-1:0][(INPUT_WIDTH + 1 + NUM_SEQ_INPUTS) - 1:0] column_sum,
    output wire out_column_sum_ready,  //common signal column_sum_ready for all 8 adders 
	
	// (* use_dsp = "no", use_carry_chain = "no" *)
	output wire signed [FINAL_VECTOR_SUM_WIDTH - 1:0] Final_Vector_Sum,
    // Overall array ready signal
    output reg array_processing_complete	
);
	
	//state definition 
	localparam IDLE  		= 2'b00,
			   ADD   		= 2'b01,
			   DONE 		= 2'b10,
			   HOLD 		= 2'b11;
    reg [1:0] state, next_state;

	localparam COUNTER_WIDTH = $clog2(NUM_SEQ_INPUTS+1);
	reg [COUNTER_WIDTH-1:0] iteration_count;  //seq input cycle counter

	
	//internal registers 
	reg column_sum_ready;
	assign out_column_sum_ready = column_sum_ready;

	reg load_input;
	reg enable_accumulation; 
	reg first_accumulation; 
	
	wire w_load_input;
	//load new input into register when input valid in IDLE and ADD states 
	assign w_load_input = ((state == IDLE || state == ADD)  && input_valid);	
	
	//last input condition
	wire w_last_iteration;
	assign w_last_iteration = (state == ADD && (iteration_count == NUM_SEQ_INPUTS)); 

	
    // Generate block for creating column adders
    genvar i;
    generate
        for (i = 0; i < NUM_COLUMNS; i = i + 1) begin : gen_column_adders
            column_adder #(
                .INPUT_WIDTH(INPUT_WIDTH),
                .NUM_SEQ_INPUTS(NUM_SEQ_INPUTS)
            ) column_adder_inst (
                .clk(clk),
                .clear(clear),
                .sequential_sum_in(data_in[i]),
				.load_input(load_input),
                .enable_accumulation(enable_accumulation),
                .column_sum(column_sum[i])
            );
        end
    endgenerate


	
	// FSM Process 1: Wrapper State and data registers (sequential logic)
	always @(posedge clk) begin 
		if (clear) begin //synchronous clear 
			state <= IDLE; 
			iteration_count <= 0;
			column_sum_ready <= 0;	
			array_processing_complete <= 0;
			enable_accumulation <= 0;
			first_accumulation <= 0;
		end else begin 
			state <= next_state; //default state assignment 
		
			// Data path updates based on current state
			case (state) 
				IDLE: begin 
					column_sum_ready <= 0;
					iteration_count <= 0;
					enable_accumulation <= 0;
					first_accumulation <= 0;
				end
				
				ADD: begin 
					if (load_input) begin //only increment counter during input valid clk cycles 
						iteration_count <= iteration_count + 1;
						enable_accumulation <= 1;
					end else begin 
						enable_accumulation <= 0;
					end 
					
					//special case to handle first accumulation 
					if (!first_accumulation && (iteration_count == 0)) begin 
						enable_accumulation <= 1;
						first_accumulation <= 1;
						iteration_count <= iteration_count + 1;
					end else begin 
						first_accumulation <= 0;
					end 
					
					column_sum_ready <= 0;
				end 
				
				DONE: begin
					if (!column_sum_ready) begin 					
						// iteration_count <= iteration_count + 1;
						column_sum_ready <= 1;	
						array_processing_complete <= 1;
					end
				end 
				
				HOLD: begin 
					column_sum_ready <= 1;
					array_processing_complete <= 1;
				end 

				default: begin 
					column_sum_ready <= 0;
					iteration_count <= 0;
					array_processing_complete <= 0;
					enable_accumulation <= 0;
				end 
			endcase 
		end 
	end 

	// FSM Process 2: Wrapper Next state logic and Control signal generation (combinational logic)
	always @(*) begin 
		//default assignment
		next_state = state; 
		// load_input = 0;
		// enable_accumulation = 0; 
		// delayed_enable_accumulation = 0;
		
		case (state) 
			IDLE: begin 
				// delayed_enable_accumulation = 0;
				//next state logic 
				next_state = (input_valid) ? ADD : IDLE;
				//control signal 
				if (input_valid) begin
					load_input = 1;
					// enable_accumulation = 1;
				end else begin 
					load_input = 0;
					// enable_accumulation = 0;
				end 
			end 
				
			ADD: begin 
				//if last iteration move to DONE state 
				next_state = (w_last_iteration) ? DONE : ADD;
				//control signal 
				if (input_valid) begin
					load_input = 1;
					// enable_accumulation = 1;
				end else begin 
					load_input = 0;
					// enable_accumulation = 0;
				end 
				
				// //delay add by 1 cycle 
				// if (enable_accumulation) begin 
					// delayed_enable_accumulation = 1;
				// end else begin 
					// delayed_enable_accumulation = 0;
				// end 
			end 
			
			DONE: begin 
				next_state = (column_sum_ready)? HOLD : DONE;  
				
				load_input = 0;
				// enable_accumulation = 0;
				// //add for one last time 
				// if (!column_sum_ready) begin 
					// enable_accumulation = 1;
				// end else begin 
					// enable_accumulation = 0;
				// end 
			end 
			
			HOLD: begin 
				// Stay in hold state until external clear applied 			
				next_state = HOLD;  //HOLD to IDLE transition when clear = 1
				load_input = 0;
				// enable_accumulation = 0;				
			end 
			
			default: begin 
				next_state = IDLE;
				load_input = 0;
				// enable_accumulation = 0;				
			end 
		endcase 
	end 
	

	/** Final Vector Merge Addition of all column sums **/

    // Internal parameter for output width
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;	
	localparam SIGN_EXT_SHIFTED_SUM_WIDTH = SUM_WIDTH + 1 + NUM_COLUMNS;  //24 bits 

	// New output declaration
	wire signed [NUM_COLUMNS-1:0][SIGN_EXT_SHIFTED_SUM_WIDTH - 1:0] Sign_Ext_and_Shifted_Col_Sum;  //24 bits 

	// Generate block for sign extension and shifting
	genvar j;
	generate
		for (j = 0; j < NUM_COLUMNS; j = j + 1) begin : gen_sign_ext_shift
			if (j == 0) begin
				//handle the special case of 0th column to avoid zero replication warning 
				//since it doesn't need zero padding for shifting 
				assign Sign_Ext_and_Shifted_Col_Sum[0] = {
					{(NUM_COLUMNS + 1){column_sum[0][SUM_WIDTH-1]}},  // Sign extension
					column_sum[0]                                     // Original value
				};
			end else begin 
				assign Sign_Ext_and_Shifted_Col_Sum[j] = {
					{(NUM_COLUMNS + 1 - j){column_sum[j][SUM_WIDTH-1]}},  // Sign extension
					column_sum[j],                                         // Original value
					{j{1'b0}}                                             // Zero padding (LSB)
				};
			end 
		end
	endgenerate

	// (* use_dsp = "no", use_carry_chain = "no" *)
	// (* keep = "true", dont_touch = "true" *)

	// // Carry Chain Adder logic 
	// // Create intermediate sum wires for the partial sum Po to P7 of adder stage 
	// wire signed [FINAL_VECTOR_SUM_WIDTH - 1:0] w_partial_sum [NUM_COLUMNS-1:0];
	
	// // Generate block for adding all Sign_Ext_and_Shifted_Col_Sum values
	// genvar k;
	// generate
		// for (k = 0; k < NUM_COLUMNS; k = k + 1) begin : gen_accumulate
			// if (k == 0) begin 
				// // Initialize the first partial sum with the first column value
				// assign w_partial_sum[0] = Sign_Ext_and_Shifted_Col_Sum[0]; //Po = Co 
			// end else begin 
			// // when k > 0, Accumulate: P[k] = C[k] + P[k-1]
				// assign w_partial_sum[k] = Sign_Ext_and_Shifted_Col_Sum[k] + w_partial_sum[k-1];
			// end	
		// end 

		// // Final result from last adder stage Final sum = P7 = P(NUM_COLUMNS-1) 
		// assign Final_Vector_Sum = w_partial_sum[NUM_COLUMNS - 1];		
	// endgenerate


	// (* use_dsp = "no", use_carry_chain = "no" *)
	// (* keep = "true", dont_touch = "true" *)
	
	//Balanced Tree Adder logic 
	// Create intermediate sum wires for the partial sum Po to P7 of adder stage 
	wire signed [FINAL_VECTOR_SUM_WIDTH - 1:0] w_partial_sum [NUM_COLUMNS-1:0];
	
	// Generate block for adding all Sign_Ext_and_Shifted_Col_Sum values
	genvar k, l, m;
	generate

		// Stage 1: Add adjacent column pairs
		for (k = 0; k < NUM_COLUMNS/2; k = k + 1) begin : gen_accumulate_stage1
			//Add all shifted column sums 0 to 7 in 1st tree adder stage : k < 4, k = 0, 1, 2, 3 
			// (* use_dsp = "no", use_carry_chain = "no" *)
			// (* keep = "true", dont_touch = "true" *)
			assign w_partial_sum[k] = Sign_Ext_and_Shifted_Col_Sum[2*k] + Sign_Ext_and_Shifted_Col_Sum[2*k + 1];
		end 

		// Stage 2: Add partial sums recursively
		//continue L from where K ended, basically k, l = 4, 5, 6 
		for (l = NUM_COLUMNS/2; l < NUM_COLUMNS - 1; l = l + 1) begin : gen_accumulate_stage2 

			// // use another local index m = (l - NUM_COLUMNS/2),  m = 0, 1, 2 
			// localparam int m = l - (NUM_COLUMNS/2); 
			// // P(l) = P(2m) + P(2m + 1) 
			// assign w_partial_sum[l] = w_partial_sum[2*m] + w_partial_sum[2*m + 1];	
			
			// k > 4, k = 4, 5, 6 
			// (* use_dsp = "no", use_carry_chain = "no" *)
			// (* keep = "true", dont_touch = "true" *)
			assign w_partial_sum[l] = w_partial_sum[2*(l - NUM_COLUMNS/2)] + w_partial_sum[2*(l - NUM_COLUMNS/2) + 1];
		end 

		// Final result from last adder stage Final sum = P6 = P(NUM_COLUMNS-2) 
		assign Final_Vector_Sum = w_partial_sum[NUM_COLUMNS - 2];  //works and checked upto N = 32 
	endgenerate

	// Ensure the NUM_COLUMNS is a power of 2 and positive 
	// powers of 2 have only one bit set
    // compile-time parameter validations
    generate
        if ((NUM_COLUMNS <= 0) || ((NUM_COLUMNS & (NUM_COLUMNS - 1)) != 0)) begin : gen_invalid_columns
			// Synthesis tools will throw an error during elaboration here
			initial begin
                $fatal(1, "NUM_COLUMNS = %0d must be a positive power of 2. Valid values: 1, 2, 4, 8, 16, 32, ...", NUM_COLUMNS);
				$finish;
			end 
		end else begin : gen_valid_columns
			// Valid NUM_COLUMNS — normal hardware generation continues
		end
	endgenerate
	
endmodule

