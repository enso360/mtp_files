`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.05.2025 22:36:18
// Design Name: 
// Module Name: thermometer_to_binary_2scomplement
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

module thermometer_to_binary_2scomplement #(
    parameter SERIAL_INPUT_LENGTH = 33  //32 + 1  //length of serial input thermometer sequence with inverted sign bit as MSB
)(
    input wire clk,           
    input wire rst,           // Active high reset
    input wire start,         
    input wire serial_in,     
    output reg valid_out,         
    output reg [$clog2(SERIAL_INPUT_LENGTH - 1) - 1:0] thermometer_sum_out,  // for sum magnitude without sign bit
	output reg [$clog2(SERIAL_INPUT_LENGTH - 1):0] thermometer_result_2scomp_out // for final result including sign bit
);

    // State definition
    localparam IDLE = 2'b00;
	localparam START = 2'b01;  //sign bit
    localparam ADDING = 2'b10;
    localparam DONE = 2'b11;

	// Better for ASIC - avoid subtraction in comparison
	localparam LAST_BIT_COUNT = SERIAL_INPUT_LENGTH - 1;

	localparam SUM_WIDTH = $clog2(SERIAL_INPUT_LENGTH - 1);
	localparam COUNT_WIDTH = $clog2(SERIAL_INPUT_LENGTH);
	
    // Internal registers
    reg [1:0] state, next_state;
    // Size sum_magnitude register to match thermometer_sum_out
    reg [SUM_WIDTH-1:0] sum_magnitude; //2s complement magnitude of 5 bits binary sum_magnitude for 32 levels
	reg [SUM_WIDTH-1:0] sum_magnitude_next;  //to hold updated sum 
	
    reg [COUNT_WIDTH:0] bit_counter;  // Counter for tracking processed bits
	reg [COUNT_WIDTH:0] bit_counter_next;

    //reg serial_in_reg;  // 1-bit register to store the serial_in input bit
	reg sign_bit_reg;
	reg sign_bit_reg_next;

    // State and data registers logic // SystemVerilog approach - clear intent
	// More predictable flip-flop inference with always_ff
	//synchronous reset preferred for ASIC
    // always_ff @(posedge clk) begin
	// Use this for Vivado compatibility
	always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sum_magnitude <= 0;
            bit_counter <= 0;
            valid_out <= 0;
            thermometer_sum_out <= 0;
			sign_bit_reg <= 0;
			thermometer_result_2scomp_out <= 0;
            //serial_in_reg <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
					//reset sign bit, sum_magnitude, bit_counter
					sign_bit_reg <= 0;
					sum_magnitude <= 0;
                    bit_counter <= 0;					
                end
				
				START: begin 					
					//invert and save incoming MSB in sign bit reg
					//sign bit is received inverted 
					// sign_bit_reg <= !serial_in;
					sign_bit_reg <= sign_bit_reg_next;
													
					valid_out <= 0;  //processing has started
					
					//// Avoid unnecessary clearing during processing
					// sign_bit_reg <= 0;
					// thermometer_sum_out <= 0;
					// thermometer_result_2scomp_out <= 0; 
					//count 1 is for sign bit 
					bit_counter <= bit_counter_next;
				end 
				
                ADDING: begin
                    // Store the serial_in bit in the serial_in_reg register
                    //serial_in_reg <= serial_in;
                                        
                    sum_magnitude <= sum_magnitude_next;
                    bit_counter <= bit_counter_next;
					valid_out <= 0;
                end
				
                DONE: begin
                    valid_out <= 1;
                    thermometer_sum_out <= sum_magnitude;
					thermometer_result_2scomp_out <= {sign_bit_reg, sum_magnitude}; //concatenate sign bit to sum_magnitude magnitude
                end
				
                default: begin
                    // Do nothing or same as IDLE 
					sign_bit_reg <= 0;
					sum_magnitude <= 0;
                    bit_counter <= 0;					
                end
            endcase
        end
    end

    // Next state logic // SystemVerilog approach - clear intent
	// always_comb automatically includes ALL inputs
	//Prevents accidental latch creation in always_comb blocks
    // always_comb begin
	always @(*) begin
        next_state = state;
		
		case (state)
			IDLE	:	next_state = start ? START : IDLE;
			START	:	next_state = ADDING;
			//The transition to DONE should happen after the last bit has been processed, 
			//and not one clock cycle earlier.
			//ADDING	:	next_state = (bit_counter == SERIAL_INPUT_LENGTH) ? DONE : ADDING;
			ADDING	:	next_state = (bit_counter == LAST_BIT_COUNT) ? DONE : ADDING;
			DONE	:   next_state = IDLE;
			default : 	next_state = IDLE; //to prevent implicit latch
		endcase		
    end

	//output comb logic 
	always @(*) begin
		//default assignment //covers IDLE and default state output 
		bit_counter_next = bit_counter;
		sum_magnitude_next = sum_magnitude;
		sign_bit_reg_next = sign_bit_reg;
		
		case (state)
			START: begin
				sign_bit_reg_next = !serial_in;	
				bit_counter_next = bit_counter + 1;
			end
			
			ADDING: begin
				bit_counter_next = bit_counter + 1;
				
				//if serial_in = 1, add 1 or else add 0
				sum_magnitude_next = sum_magnitude + serial_in;					
			end

		endcase
	end


endmodule


//TODO: handle and alert invalid thermometer code 