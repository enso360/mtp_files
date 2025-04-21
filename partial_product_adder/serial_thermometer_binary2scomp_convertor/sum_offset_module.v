
module sum_offset_module #(
    parameter SERIAL_INPUT_LENGTH = 64  // Updated to 64
)(
    input wire [$clog2(SERIAL_INPUT_LENGTH):0] sum_in,  // Sum input from bit_serial_adder
    output wire [$clog2(SERIAL_INPUT_LENGTH)+1:0] offset_sum_out  // Output with offset applied (+1 bit for sign)
);
    // Calculate the bit width for the offset
    localparam OFFSET_WIDTH = $clog2(SERIAL_INPUT_LENGTH);
    
    // Calculate the most negative value possible with OFFSET_WIDTH bits (in 2's complement)
    localparam NEGATIVE_OFFSET = -(2**(OFFSET_WIDTH-1));  // -32 for SERIAL_INPUT_LENGTH=64
    
    // Combinational logic to add the offset
    // Sign extend sum_in and add the offset
    assign offset_sum_out = $signed({1'b0, sum_in}) + $signed(NEGATIVE_OFFSET);
    
endmodule
