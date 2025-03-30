module uart_receiver #(
    parameter DATA_BITS = 8    // Number of data bits
)(
    input  wire        clk,           // System clock
    input  wire        rst,           // Reset signal
    input  wire        rx_baud_tick,  // 16x baud rate tick from baud generator
    input  wire        rx_in,         // Serial input line
    output reg         rx_ready,      // Data valid indicator
    output reg [DATA_BITS-1:0] rx_data,  // Received data //SIPO
    output reg         rx_error       // Frame error indicator
);

    // State definitions
    localparam IDLE        = 3'b000;
    localparam START_BIT   = 3'b001;
    localparam DATA_BITS_S = 3'b010;
    localparam STOP_BIT    = 3'b011;
    localparam CLEANUP     = 3'b100;

    // Internal registers
    reg [2:0]  state;
    reg [3:0]  sample_counter;    // Counts rx_baud_ticks (0-15)
    reg [3:0]  bit_counter;       // Counts received bits
    reg [7:0]  rx_shift_reg;      // Shift register for received bits
    
    // Synchronize rx_in with two flip-flops to avoid metastability
    reg rx_sync1, rx_sync2;
    
    always @(posedge clk) begin
        if (rst) begin
            rx_sync1 <= 1'b1;  // Default idle state is high
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx_in;
            rx_sync2 <= rx_sync1;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            sample_counter <= 0;
            bit_counter <= 0;
            rx_shift_reg <= 0;
            rx_ready <= 1'b0;
            rx_data <= 0;
            rx_error <= 1'b0;
        end else begin
            // Default - maintain current signals
            rx_ready <= 1'b0;  // Pulse rx_ready for only one clock cycle //todo
            
            case (state)
                IDLE: begin
                    // Wait for start bit (high-to-low transition)
                    if (rx_sync2 == 1'b0) begin
                        // Start bit detected, begin sampling
                        state <= START_BIT;
                        sample_counter <= 0;
                    end
                end
                
                START_BIT: begin
                    // Sample the start bit at middle point (at tick 7)
                    if (rx_baud_tick) begin
                        sample_counter <= sample_counter + 1;
                        
                        // Check middle of start bit to verify it's still low
                        if (sample_counter == 7) begin
                            // If not low, there was noise - go back to IDLE
                            if (rx_sync2 != 1'b0) begin
                                state <= IDLE;
                            end
                        end
                        // End of start bit
                        else if (sample_counter == 15) begin
                            state <= DATA_BITS_S;
                            sample_counter <= 0;
                            bit_counter <= 0;
                        end
                    end
                end
                
                DATA_BITS_S: begin
                    // Sample data bits
                    if (rx_baud_tick) begin
                        sample_counter <= sample_counter + 1;
                        
                        // Sample at middle of bit (at tick 7)
                        if (sample_counter == 7) begin
                            //Right Shift in the received bit
                            rx_shift_reg <= {rx_sync2, rx_shift_reg[DATA_BITS-1:1]};
                        end
                        // End of current bit
                        else if (sample_counter == 15) begin
                            sample_counter <= 0;
                            bit_counter <= bit_counter + 1;
                            
                            // Check if all data bits have been received
                            if (bit_counter == DATA_BITS - 1) begin
                                state <= STOP_BIT;
                            end
                        end
                    end
                end
                
                STOP_BIT: begin
                    // Sample stop bit
                    if (rx_baud_tick) begin
                        sample_counter <= sample_counter + 1;
                        
                        // Sample at middle of stop bit
                        if (sample_counter == 7) begin
                            // Check for framing error (stop bit should be high)
                            rx_error <= (rx_sync2 != 1'b1);
                            
                            // Capture the data regardless of framing error
                            rx_data <= rx_shift_reg;  //SIPO
                            rx_ready <= 1'b1;  // Data is ready
                        end
                        // End of stop bit
                        else if (sample_counter == 15) begin
                            // state <= CLEANUP;  //todo
							state <= IDLE;  //todo
                            sample_counter <= 0;
                        end
                    end
                end
                
                // CLEANUP: begin
                    // // Extra state to handle any cleanup and prepare for next byte
                    // state <= IDLE;
                    // // Check for immediate start bit (back-to-back transmission)
                    // if (rx_sync2 == 1'b0) begin
                        // state <= START_BIT;
                        // sample_counter <= 0;
                    // end
                // end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
