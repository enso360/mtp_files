
module thermometer_to_binary_2scomplement #(
    parameter SERIAL_INPUT_LENGTH = 33  //32 + 1  //length of serial input thermometer sequence with sign bit as MSB
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

    // Internal registers
    reg [1:0] state, next_state;
    // Size sum_magnitude register to match thermometer_sum_out
    reg [$clog2(SERIAL_INPUT_LENGTH - 1) - 1:0] sum_magnitude; //2s complement magnitude of 5 bits binary sum_magnitude for 32 levels
    reg [$clog2(SERIAL_INPUT_LENGTH):0] bit_counter;  // Counter for tracking processed bits
    //reg serial_in_reg;  // 1-bit register to store the serial_in input bit
	reg sign_bit_reg;

    // State and data registers logic
    always @(posedge clk or posedge rst) begin
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
					//save incoming MSB in sign bit reg
					sign_bit_reg <= serial_in;								
					valid_out <= 0;  //processing has started
					bit_counter <= bit_counter + 1;
				end 
				
                ADDING: begin
                    // Store the serial_in bit in the serial_in_reg register
                    //serial_in_reg <= serial_in;
                    
                    // If serial_in is 1, increment sum_magnitude by 1
                    if (serial_in) begin
                        sum_magnitude <= sum_magnitude + 1;
                    end else begin 
						//sum_magnitude <= sum_magnitude;
					end
                    bit_counter <= bit_counter + 1;
                end
				
                DONE: begin
                    valid_out <= 1;
                    thermometer_sum_out <= sum_magnitude;
					thermometer_result_2scomp_out <= {sign_bit_reg, sum_magnitude}; //concatenate sign bit to sum_magnitude magnitude
                end
				
                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = START;
                end else begin 
					next_state = IDLE; //to prevent implicit latch
				end 
            end
			
			START: begin 
				next_state = ADDING;
			end 
			
            ADDING: begin
			//The transition to DONE should happen after the last bit has been processed, 
			//and not one clock cycle earlier.
			
                if (bit_counter == SERIAL_INPUT_LENGTH - 1) begin			
                //if (bit_counter == SERIAL_INPUT_LENGTH) begin
                    next_state = DONE;
                end else begin 
					next_state = ADDING; //to prevent implicit latch 
				end 
            end
			
            DONE: begin
                next_state = IDLE;
            end
			
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
