`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: Column Processing Unit
// Module Name: column_processing_unit_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top-level module connecting thermo2binary and column adder arrays
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: This module processes thermometer codes sequentially,
//                     converts them to binary, and accumulates the results
// 
//////////////////////////////////////////////////////////////////////////////////


module column_processing_unit_top #(
    parameter SERIAL_INPUT_LENGTH = 33,
    parameter T2B_OUT_WIDTH = 6,
    parameter NUM_COLUMNS = 8,
    parameter NUM_SEQ_INPUTS = 8,
    parameter FINAL_VECTOR_SUM_WIDTH = 24
)(
    input wire clk,
    input wire reset,
    input wire clear,
	input wire global_accumulation_enable,  //master enable 
	input wire start_conversion, // Thermometer to binary conversion control
    // Serial thermometer code inputs (one bit per column per clock cycle)
    input wire [NUM_COLUMNS-1:0] serial_thermo_in,
	// Final outputs
    output wire signed [NUM_COLUMNS-1:0][(T2B_OUT_WIDTH + 1 + NUM_SEQ_INPUTS) - 1:0] column_sum,
    output wire signed [FINAL_VECTOR_SUM_WIDTH - 1:0] final_vector_sum,
	
    // Status outputs
    output wire conversion_valid,  //t2b valid out
    output wire column_sum_ready,
    output wire processing_complete
); 

	wire w_start_conversion_top; 
	
	
    // Internal signals connecting the two wrapper modules
    wire signed [NUM_COLUMNS-1:0][T2B_OUT_WIDTH - 1:0] t2b_results;
    wire t2b_valid;

    // Instantiate thermometer to binary converter array wrapper
    thermo2binary_array_wrapper #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH),
        .T2B_OUT_WIDTH(T2B_OUT_WIDTH),
        .NUM_COLUMNS(NUM_COLUMNS)
    ) thermo2binary_wrapper_inst (
        .clk(clk),
        .reset(reset),
        .start(w_start_conversion_top),
        .serial_in_array(serial_thermo_in),
        .signed_result_out_array(t2b_results),
        .valid_out(t2b_valid)
    );

	(* use_dsp = "no", use_carry_chain = "no" *)
	(* keep = "true", dont_touch = "true" *)    
    // Instantiate column adder array
    column_adder_array #(
        .INPUT_WIDTH(T2B_OUT_WIDTH),
        .NUM_SEQ_INPUTS(NUM_SEQ_INPUTS),
        .NUM_COLUMNS(NUM_COLUMNS),
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



    // Output assignments
    assign conversion_valid = t2b_valid;
	// Enable start_conversion only when global accumulation is active
	assign w_start_conversion_top = global_accumulation_enable && start_conversion;

endmodule


