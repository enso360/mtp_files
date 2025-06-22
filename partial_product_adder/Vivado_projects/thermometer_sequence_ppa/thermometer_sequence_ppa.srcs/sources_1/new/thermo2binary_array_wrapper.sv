`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: thermo2binary_array_wrapper 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: FSM wrapper for array of 8 parallel thermo2binary core modules
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: All cores process data synchronously using shared FSM control signals
// This ensures all 8 thermometer codes are converted simultaneously
// 
//////////////////////////////////////////////////////////////////////////////////


module thermo2binary_array_wrapper #(
    parameter SERIAL_INPUT_LENGTH = 33,
	parameter T2B_OUT_WIDTH = 6,
	parameter NUM_COLUMNS = 8
)(
    input wire clk,          //common 
    input wire reset,        //common   
    input wire start,		 //common 
	// A packed array for input data
    input wire [NUM_COLUMNS-1:0] serial_in_array, 	
	// 2D Packed array for output
    output wire signed [NUM_COLUMNS-1:0][T2B_OUT_WIDTH - 1:0] signed_result_out_array,	
	output wire valid_out  //internal to wrapper 
);

	reg valid_out_reg; //valid_out moved from core to wrapper 
	assign valid_out = valid_out_reg;   //continous assign to output port
	
    // State definition
    localparam IDLE = 2'b00;
    localparam START = 2'b01;  //Start with Sign bit processing
    localparam ADDING = 2'b10;
    localparam DONE = 2'b11;
	
	// // Better for ASIC - avoid subtraction in comparison
	localparam COUNT_WIDTH = $clog2(SERIAL_INPUT_LENGTH);	
	localparam LAST_BIT_COUNT = SERIAL_INPUT_LENGTH - 1;  //32	


    reg [1:0] state, next_state;  // FSM state registers
	
    reg [COUNT_WIDTH:0] bit_counter;  // Counter for tracking processed bits
	// reg [COUNT_WIDTH:0] bit_counter_next;

    // Control signals to core module
	reg clear_data;
	reg capture_sign;
    reg add_enable; 
    reg latch_data;
	
    wire processing_complete;
    // Processing complete when all bits are processed
    assign processing_complete = (bit_counter == LAST_BIT_COUNT);


    // Generate block for creating 8 thermo2binary core modules
	genvar i;
	generate 
		for (i = 0; i < NUM_COLUMNS; i = i + 1) begin : gen_thermo2binary_core_inst
			thermo2binary_core #(
				.SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH),
				.T2B_OUT_WIDTH(T2B_OUT_WIDTH)
			) t2b_dut (
				.clk(clk),
				.reset(reset),		
				.clear_data(clear_data),
				.capture_sign(capture_sign),
				.add_enable(add_enable),
				.latch_data(latch_data),		
				.serial_in(serial_in_array[i]),
				.signed_result_out(signed_result_out_array[i])		
			);
		end
	endgenerate
	

    // FSM block for Wrapper State registers and bit counter
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            bit_counter <= 0;
			valid_out_reg <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    bit_counter <= 0; // Reset counter when idle
					valid_out_reg <= 0;
                end
                
                START: begin
                    bit_counter <= 1; // 1st bit 
					valid_out_reg <= 0;
                end
                
                ADDING: begin
                    bit_counter <= bit_counter + 1; // Count data bits
					valid_out_reg <= 0;
                end
                
                DONE: begin
					valid_out_reg <= 1;
                end
                
                default: begin
                    bit_counter <= 0;
					valid_out_reg <= 0;
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
            IDLE    : next_state = start ? START : IDLE;
            START   : next_state = ADDING;
            ADDING  : next_state = processing_complete ? DONE : ADDING;
            DONE    : next_state = IDLE;
            default : next_state = IDLE;  //to prevent implicit latch
        endcase
    end

    // Control signal generation
    always @(*) begin
        // Default values
        clear_data = 0;
        capture_sign = 0;		
        add_enable = 0;
        latch_data = 0;
        
        case (state)
            IDLE: begin
				if (start) begin 
					clear_data = 1; // assert clear data in idle
				end 
            end
            
            START: begin
                capture_sign = 1; // Capture the sign bit
            end
            
            ADDING: begin
                add_enable = 1; // Enable processing of data bits
            end
            
            DONE: begin
                latch_data = 1; // Enable latch signal to latch result
            end
        endcase
    end

endmodule


//TODO: handle and alert invalid thermometer code 
