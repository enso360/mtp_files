`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: column_adder_array
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
    parameter NUM_COLUMNS = 8
)(
    input wire clk,
    input wire clear,
    input wire input_valid,
    
    // A 2D packed array for input data - NUM_COLUMNS x  INPUT_WIDTH - easier to connect and parameterize
    input wire signed [NUM_COLUMNS-1:0][INPUT_WIDTH-1:0] data_in,
    
    // Packed arrays for outputs - NUM_COLUMNS x Sum Width 
    output wire signed [NUM_COLUMNS-1:0][(INPUT_WIDTH + 1 + NUM_SEQ_INPUTS) - 1:0] column_sum,
    output wire [NUM_COLUMNS-1:0] column_sum_ready
);

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
                .in(data_in[i]),
                .input_valid(input_valid),
                .column_sum(column_sum[i]),
                .column_sum_ready(column_sum_ready[i])
            );
        end
    endgenerate


    // Internal parameter for output width
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;	
	localparam SIGN_EXT_SHIFTED_SUM_WIDTH = SUM_WIDTH + 1 + NUM_COLUMNS;

	// New output declaration
	wire signed [NUM_COLUMNS-1:0][(INPUT_WIDTH + 1 + NUM_SEQ_INPUTS + 1 + NUM_COLUMNS) - 1:0] Sign_Ext_and_Shifted_Col_Sum;

	// Generate block for sign extension and shifting
	genvar j;
	generate
		for (j = 0; j < NUM_COLUMNS; j = j + 1) begin : gen_sign_ext_shift
			assign Sign_Ext_and_Shifted_Col_Sum[j] = {
				{(NUM_COLUMNS + 1 - j){column_sum[j][SUM_WIDTH-1]}},  // Sign extension
				column_sum[j],                                         // Original value
				{j{1'b0}}                                             // Zero padding (LSB)
			};
		end
	endgenerate

	//Final Vector Merge addition 
	// Declare Final_Vector_Sum with localparam
	localparam FINAL_SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS + 1 + NUM_COLUMNS;
	wire signed [FINAL_SUM_WIDTH - 1:0] Final_Vector_Sum;

	// Generate block for adding all Sign_Ext_and_Shifted_Col_Sum values
	genvar k;
	generate
		// Create intermediate sum wires for the adder tree
		wire signed [FINAL_SUM_WIDTH - 1:0] partial_sum [NUM_COLUMNS:0];
		
		// Initialize the first partial sum to zero
		assign partial_sum[0] = {FINAL_SUM_WIDTH{1'b0}};
		
		// Add each Sign_Ext_and_Shifted_Col_Sum to the running sum
		for (k = 0; k < NUM_COLUMNS; k = k + 1) begin : gen_accumulate
			assign partial_sum[k+1] = partial_sum[k] + Sign_Ext_and_Shifted_Col_Sum[k];
		end
		
		// Final result
		assign Final_Vector_Sum = partial_sum[NUM_COLUMNS];
	endgenerate

endmodule
