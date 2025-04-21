
module bit_serial_adder #(
    parameter SERIAL_INPUT_LENGTH = 32  // length of input bit sequence of thermometer code
)(
    input wire clk,           
    input wire rst,           // Active high reset
    input wire start,         
    input wire serial_in,     
    output reg valid,         
    output reg [$clog2(SERIAL_INPUT_LENGTH):0] parallel_sum_out  // Parallel output result
);

    // State definition
    localparam IDLE = 2'b00;
    localparam ADDING = 2'b01;
    localparam DONE = 2'b10;

    // Internal registers
    reg [1:0] state, next_state;
    // Size sum register to match parallel_sum_out
    reg [$clog2(SERIAL_INPUT_LENGTH):0] sum; //1 additional bit for overflow if any
    reg [$clog2(SERIAL_INPUT_LENGTH):0] bit_counter;  // Counter for tracking processed bits
    reg serial_in_reg;  // 1-bit register to store the serial_in input bit

    // State and data registers logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            sum <= 0;
            bit_counter <= 0;
            valid <= 0;
            parallel_sum_out <= 0;
            serial_in_reg <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        sum <= 0;
                        bit_counter <= 0;
                        valid <= 0;
                        serial_in_reg <= 0;
                    end
                end
                ADDING: begin
                    // Store the serial_in bit in the serial_in_reg register
                    serial_in_reg <= serial_in;
                    
                    // If serial_in_reg is 1, increment sum by 1
                    if (serial_in_reg) begin
                        sum <= sum + 1;
                    end else begin 
						//
					end
                    bit_counter <= bit_counter + 1;
                end
                DONE: begin
                    valid <= 1;
                    parallel_sum_out <= sum;
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
                    next_state = ADDING;
                end
            end
            ADDING: begin
			//The last input bit is stored in the serial_in_reg register, 
			//and the sum register is updated based on this value in the same clock cycle. 
			//Therefore, the transition to DONE should happen after the last bit has been processed, 
			//and not one clock cycle earlier.
			
                //if (bit_counter == SERIAL_INPUT_LENGTH - 1) begin			
                if (bit_counter == SERIAL_INPUT_LENGTH) begin
                    next_state = DONE;
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
