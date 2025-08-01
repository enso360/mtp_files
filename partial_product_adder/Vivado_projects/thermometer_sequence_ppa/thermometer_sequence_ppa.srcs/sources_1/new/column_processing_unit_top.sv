`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: Column Processing Unit Top 
// Module Name: column_processing_unit_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top-level module that instantiates N units of column_processing_unit sub-module 
// 				which in turn instantiate thermo2binary and column adder array sub-modules 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: The column_processing_unit module converts serial thermometer codes to binary, 
// 						and accumulates the results
// 
//////////////////////////////////////////////////////////////////////////////////

//top level module 
module column_processing_unit_top #(
	parameter NUM_UNITS = 32,
    parameter SERIAL_INPUT_LENGTH = 33,
    parameter T2B_OUT_WIDTH = 6,
    parameter NUM_COLUMNS = 8,
    parameter NUM_SEQ_INPUTS = 8,
	parameter COLUMN_SUM_WIDTH = 15,  //15
    parameter FINAL_VECTOR_SUM_WIDTH = 24
)(
    input wire clk,
    input wire reset,
    input wire clear,
	input wire global_accumulation_enable,  //master enable 
	input wire start_conversion, // Thermometer to binary conversion control  // Same for all units
    // Serial thermometer code inputs (one bit per column per clock cycle)
    input wire [NUM_UNITS-1: 0][NUM_COLUMNS-1:0] serial_thermo_in,
	// Final outputs
    output wire signed [NUM_UNITS-1: 0][NUM_COLUMNS-1:0][COLUMN_SUM_WIDTH - 1:0] column_sum,
    output wire signed [NUM_UNITS-1: 0][FINAL_VECTOR_SUM_WIDTH - 1:0] final_vector_sum,
	
    // Status outputs
    output wire [NUM_UNITS-1: 0] conversion_valid,  //t2b valid out
    output wire [NUM_UNITS-1: 0] column_sum_ready,
    output wire [NUM_UNITS-1: 0] processing_complete
); 

	wire w_start_conversion_top; // Same for all units
	
	// Enable start_conversion only when global accumulation is active
	assign w_start_conversion_top = global_accumulation_enable && start_conversion;  // Same for all units


	//generate for loop for instantiating NUM_UNITS times column processing units 
	genvar i; 
	generate 
		for (i = 0; i < NUM_UNITS; i = i + 1) begin: gen_col_proc_units 
			column_processing_unit #(
				.SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH),
				.T2B_OUT_WIDTH(T2B_OUT_WIDTH),
				.NUM_COLUMNS(NUM_COLUMNS),
				.NUM_SEQ_INPUTS(NUM_SEQ_INPUTS),
				.COLUMN_SUM_WIDTH(COLUMN_SUM_WIDTH),
				.FINAL_VECTOR_SUM_WIDTH(FINAL_VECTOR_SUM_WIDTH)
			) column_processing_unit_inst (
				.clk(clk),
				.reset(reset),
				.clear(clear),
				.start_conversion(w_start_conversion_top),  // Same for all units
				.serial_thermo_in(serial_thermo_in[i]),
				.column_sum(column_sum[i]),
				.final_vector_sum(final_vector_sum[i]),
				.conversion_valid(conversion_valid[i]),
				.column_sum_ready(column_sum_ready[i]),
				.processing_complete(processing_complete[i])
			);
		end 
	endgenerate 

endmodule


//////////////////////////////////////////////////////////////////////////////////
//sub-module 
module column_processing_unit #(
    parameter SERIAL_INPUT_LENGTH = 33,
    parameter T2B_OUT_WIDTH = 6,
    parameter NUM_COLUMNS = 8,
    parameter NUM_SEQ_INPUTS = 8,
	parameter COLUMN_SUM_WIDTH = 15,
    parameter FINAL_VECTOR_SUM_WIDTH = 24
)(
    input wire clk,
    input wire reset,
    input wire clear,
	input wire start_conversion, // Thermometer to binary conversion control
    // Serial thermometer code inputs (one bit per column per clock cycle)
    input wire [NUM_COLUMNS-1:0] serial_thermo_in,
	// Final outputs
    output wire signed [NUM_COLUMNS-1:0][COLUMN_SUM_WIDTH - 1:0] column_sum,
    output wire signed [FINAL_VECTOR_SUM_WIDTH - 1:0] final_vector_sum,
	
    // Status outputs
    output wire conversion_valid,  //t2b valid out
    output wire column_sum_ready,
    output wire processing_complete
); 

    // Internal signals connecting the two array wrapper sub-modules
    wire signed [NUM_COLUMNS-1:0][T2B_OUT_WIDTH - 1:0] t2b_results;
    wire t2b_valid;

    // Output assignments
    assign conversion_valid = t2b_valid;

    // Instantiate thermometer to binary converter array wrapper
    thermo2binary_array_wrapper #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH),
        .T2B_OUT_WIDTH(T2B_OUT_WIDTH),
        .NUM_COLUMNS(NUM_COLUMNS)
    ) thermo2binary_wrapper_inst (
        .clk(clk),
        .reset(reset),
        .start(start_conversion),
        .serial_in_array(serial_thermo_in),
        .signed_result_out_array(t2b_results),
        .valid_out(t2b_valid)
    );

	// (* use_dsp = "no", use_carry_chain = "no" *)
	// (* keep = "true", dont_touch = "true" *)    
    // Instantiate column adder array
    column_adder_array #(
        .INPUT_WIDTH(T2B_OUT_WIDTH),
        .NUM_SEQ_INPUTS(NUM_SEQ_INPUTS),
        .NUM_COLUMNS(NUM_COLUMNS),
		.COLUMN_SUM_WIDTH(COLUMN_SUM_WIDTH),
        .FINAL_VECTOR_SUM_WIDTH(FINAL_VECTOR_SUM_WIDTH)
    ) column_adder_array_inst (
        .clk(clk),
        .clear(clear),
        .input_valid(t2b_valid),
        .data_in(t2b_results),
        .column_sum(column_sum),
        .out_column_sum_ready(column_sum_ready),
        .Final_Vector_Sum(final_vector_sum),
        .array_processing_complete(processing_complete)
    );

endmodule
