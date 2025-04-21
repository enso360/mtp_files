
module thermometer_code_generator #(
    parameter N = 4  // Default to 4-bit binary input
)(
    input wire clk,
    input wire reset,      // Active high reset
    input wire start,      // Active high start signal
    input wire [N-1:0] binary_in,  // N-bit binary input
    output reg serial_out, // Serial output bit
    output reg done        // Active high done signal
);

    // Calculate the total number of output bits (2^N - 1)
    localparam TOTAL_BITS = (2**N) - 1;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam RUNNING = 2'b01;
    localparam FINISHED = 2'b10;
    
    // Registers
    reg [1:0] state, next_state;
    reg [N-1:0] binary_counter;  // Counter for binary value (counts up)
    reg [N-1:0] bit_counter;     // Counter to track number of bits sent
    
    // State register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            binary_counter <= 0;
            bit_counter <= 0;
            serial_out <= 0;
            done <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        binary_counter <= 0;          // Initialize binary counter to 0 (counting up)
                        bit_counter <= 0;             // Initialize bit counter
                        serial_out <= 0;              // Clear serial_out
                        done <= 0;                    // Clear done signal
                    end
                end
                
                RUNNING: begin
                    if (bit_counter < TOTAL_BITS) begin
                        bit_counter <= bit_counter + 1;
                        
                        // Determine serial output using ternary operator
                        serial_out <= (binary_counter < binary_in) ? 1'b1 : 1'b0;
                        
                        // Only increment binary counter if it hasn't reached binary_in yet
                        if (binary_counter < binary_in) begin
                            binary_counter <= binary_counter + 1;
                        end
                    end
                end
                
                FINISHED: begin
                    done <= 1;  // Assert done signal
                end
                
                default: begin
                    // Default case to handle unexpected states
                    binary_counter <= 0;
                    bit_counter <= 0;
                    serial_out <= 0;
                    done <= 0;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = RUNNING;
                else
                    next_state = IDLE;
            end
            
            RUNNING: begin
                if (bit_counter >= TOTAL_BITS - 1)
                    next_state = FINISHED;
                else
                    next_state = RUNNING;
            end
            
            FINISHED: begin
                // Automatically return to IDLE after completion
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule

