
module thermometer_counter_wrapper #(
    parameter SERIAL_INPUT_LENGTH = 64  // Length of input bit sequence
)(
    input wire clk,
    input wire rst,           // Active high reset
    input wire start,
    input wire serial_in,     // Serial input bit
    output wire valid_out,    // Final valid output signal
    output wire [$clog2(SERIAL_INPUT_LENGTH)+1:0] final_out // Final output with offset applied
);

    // Internal signals
    wire [$clog2(SERIAL_INPUT_LENGTH):0] parallel_sum;
    wire adder_valid;

    // Instantiate the bit_serial_adder
    bit_serial_adder #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH)
    ) adder_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .serial_in(serial_in),
        .valid(adder_valid),
        .parallel_sum_out(parallel_sum)
    );

    // Instantiate the sum_offset_module
    sum_offset_module #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH)
    ) offset_inst (
        .sum_in(parallel_sum),
        .offset_sum_out(final_out)
    );
    
    // Pass through the valid signal from the adder to the output
    assign valid_out = adder_valid;

endmodule
