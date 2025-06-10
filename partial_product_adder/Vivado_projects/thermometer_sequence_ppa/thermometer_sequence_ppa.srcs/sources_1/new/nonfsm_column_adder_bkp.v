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
	output wire column_sum_ready
);

    // Internal parameter for output width
    // localparam OUTPUT_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;  // e.g., 6+1+8 = 15
    localparam EXT_IN_WIDTH = INPUT_WIDTH + 1;  // 7 bits

	//internal registers
	reg [$clog2(NUM_SEQ_INPUTS+1)-1:0] iteration_count;
	reg last_input_processed;
	// reg signed [SUM_WIDTH] temp_sum;
	
    //Combinational signals
    wire signed [EXT_IN_WIDTH-1:0] extended_input;
	assign extended_input = {in[INPUT_WIDTH-1], in};  // sign-extend 6 bit input to 7 bits for addition 

	wire signed [EXT_IN_WIDTH-1:0] sum_higher_bits;  //7bits
	wire signed [SUM_WIDTH-EXT_IN_WIDTH-1:0] sum_lower_bits;  //8bits
	
	assign sum_higher_bits = column_sum[SUM_WIDTH-1 -: EXT_IN_WIDTH];  //column_sum[14:7]
	assign sum_lower_bits = column_sum[SUM_WIDTH-EXT_IN_WIDTH-1:0];	   //column_sum[7:0]
	
	//add extended_input to MSBs of column_sum reg
	wire signed [EXT_IN_WIDTH-1:0] updated_sum_higher_bits;  //7bits
	assign updated_sum_higher_bits = sum_higher_bits + extended_input;  //sliced addition //synthesize 2 input 7 bit comb adder
	
	//update column sum 
	wire signed [SUM_WIDTH-1:0] updated_sum;
	assign updated_sum = {updated_sum_higher_bits, sum_lower_bits};
	
	wire signed [SUM_WIDTH-1:0] shifted_updated_sum;
	assign shifted_updated_sum = updated_sum >>> 1; //arithmetic shift right by 1, preserve msb sign bit
	
	//input processing condition
	wire processing_flag;
	assign processing_flag = (input_valid && !last_input_processed && (iteration_count > 0));
	
    //Combinational logic for ready signal
    assign column_sum_ready = last_input_processed;

	
    always @(posedge clk or posedge clear) begin
        if (clear) begin
			// temp_sum <=0;
            column_sum <=0;
			iteration_count <= NUM_SEQ_INPUTS;  //down counter 7 to 0
			last_input_processed <= 0;
        end else begin 
			if (processing_flag == 1) begin
				iteration_count <= iteration_count - 1;
				// column_sum <= updated_sum >>> 1; //arithmetic shift right by 1, preserve msb sign bit
				column_sum <= shifted_updated_sum;
				
				if (iteration_count == 1) begin  //last iteration
					last_input_processed <= 1;
				end else 
					last_input_processed <= 0;
				end 
			else begin 
				column_sum <= column_sum;  //hold value until external clear input applied
			end
		end
    end

endmodule
