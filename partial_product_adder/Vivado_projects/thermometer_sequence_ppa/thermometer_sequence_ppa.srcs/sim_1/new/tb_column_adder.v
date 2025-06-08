`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_column_adder
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


`timescale 1ns / 1ps

module tb_column_adder;

    // Parameters
    localparam INPUT_WIDTH = 6;
    localparam NUM_SEQ_INPUTS = 8;
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;

    // DUT I/O
    reg clk;
    reg clear;
    reg signed [INPUT_WIDTH-1:0] in;
    reg input_valid;
    wire signed [SUM_WIDTH-1:0] column_sum;
    wire column_sum_ready;

    // Instantiate the DUT
    column_adder #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .NUM_SEQ_INPUTS(NUM_SEQ_INPUTS)
    ) dut (
        .clk(clk),
        .clear(clear),
        .in(in),
        .input_valid(input_valid),
        .column_sum(column_sum),
        .column_sum_ready(column_sum_ready)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100 MHz clock

    // Test vector
    reg signed [INPUT_WIDTH-1:0] input_data [0:10];
    integer i;

    initial begin
        $display("Starting test...");
        clk = 0;
        clear = 1;
        input_valid = 0;
        in = 0;

        // Initialize test input: 8 values (mix of positive and negative)
        input_data[0] = 6'sd1;
        input_data[1] = 6'sd1;
        input_data[2] = 6'sd1;
        input_data[3] = 6'sd1;
        input_data[4] = 6'sd1;
        input_data[5] = 6'sd1;
        input_data[6] = 6'sd1;
        input_data[7] = 6'sd1;
		
		//extra inputs 
		input_data[8] = 6'sd0;
		input_data[9] = 6'sd1;

        // Wait for a few cycles with clear asserted
        #20;
        clear = 0;

        // Feed inputs one by one
        for (i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            in <= input_data[i];
            input_valid <= 1;
            @(negedge clk);
            input_valid <= 0;
        end

        // Wait for ready signal
        wait (column_sum_ready == 1);

        @(posedge clk);
        $display("Final Column Sum = %0d (binary: %b)", column_sum, column_sum);

        // Done
        $finish;
    end

endmodule
