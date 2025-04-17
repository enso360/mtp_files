
module priority_encoder #(
    parameter WIDTH = 64,                      // Input width 
    parameter LOG_WIDTH = $clog2(WIDTH)        // Output width (log2 of input width)
)(
    input [WIDTH-1:0] data_in,
    input clear,                               // Clear signal
    output reg [LOG_WIDTH-1:0] data_out,
    output reg [LOG_WIDTH:0] signed_out,       // Zero-padded for signed representation
    output reg [LOG_WIDTH:0] signed_thermometer_to_binary_data_out, // New output for signed addition result	
    output reg valid
);

    // 7-bit signed representation of -32 is 7'b1100000 (two's complement)
    localparam MINUS_32_7BIT_SIGNED = 7'b1100000;
	
    integer i;
    always @(*) begin
        if (clear) begin
            // When clear is active, reset outputs
            valid = 1'b0;
            data_out = {LOG_WIDTH{1'b0}};
            signed_out = {(LOG_WIDTH+1){1'b0}};
            signed_thermometer_to_binary_data_out = {(LOG_WIDTH+1){1'b0}};			
        end
        else begin
            valid = |data_in;                  // Set valid if any bit is 1
            data_out = {LOG_WIDTH{1'b0}};      // Default output is 0
            signed_out = {(LOG_WIDTH+1){1'b0}}; // Default signed output is 0
            signed_thermometer_to_binary_data_out = {(LOG_WIDTH+1){1'b0}}; // Default addition result is 0			
            
            // Priority encoding - check each bit from highest to lowest
            for (i = 0; i <= WIDTH-1; i = i + 1) begin
                if (data_in[i]) begin
                    data_out = i[LOG_WIDTH-1:0]; // Convert loop index to output size
					
                    // Zero-pad data_out by 1 bit on the left for signed representation
                    signed_out = {1'b0, i[LOG_WIDTH-1:0]};
					
                    // Add -32 to signed_out for the thermometer to binary conversion
                    // Need to ensure bit widths match for addition
                    if (LOG_WIDTH+1 >= 7) begin  //todo
                        // If our output is at least 7 bits wide, we can add the full 7-bit -32
                        //signed_thermometer_to_binary_data_out = signed_out + {{(LOG_WIDTH+1-7){MINUS_32_7BIT_SIGNED[6]}}, MINUS_32_7BIT_SIGNED};
						signed_thermometer_to_binary_data_out = signed_out + MINUS_32_7BIT_SIGNED; //todo
					end
                    else begin //todo
                        // If output is less than 7 bits, we need to truncate the -32 value
                        signed_thermometer_to_binary_data_out = signed_out + MINUS_32_7BIT_SIGNED[LOG_WIDTH:0];
                    end					
                end
            end
        end
    end
endmodule
