
`timescale 1ns / 1ps

module binary_to_thermometer_tb;

    // Parameters
    parameter INPUT_WIDTH = 3;
    localparam THERMOMETER_WIDTH = 2**INPUT_WIDTH - 1;

    // Signals
    reg [INPUT_WIDTH:0] binary_in;
    wire [THERMOMETER_WIDTH-1:0] thermometer_out;

    // Instantiate the DUT (Device Under Test)
    binary_to_thermometer #(
        .INPUT_WIDTH(INPUT_WIDTH)
    ) dut (
        .binary_in(binary_in),
        .thermometer_out(thermometer_out)
    );

    // Testbench process
    initial begin
        // Test all possible binary input values
        for (binary_in = 0; binary_in < (2**INPUT_WIDTH); binary_in = binary_in + 1) begin
            #10;
            $display("binary_in = %b, thermometer_out = %b", binary_in, thermometer_out);
        end
        $finish;
    end

endmodule

