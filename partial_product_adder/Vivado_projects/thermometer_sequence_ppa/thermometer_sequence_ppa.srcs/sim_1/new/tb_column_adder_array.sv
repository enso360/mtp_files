`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: tb_column_adder_array
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

module tb_column_adder_array;

    // Parameters
    parameter INPUT_WIDTH = 6;
    parameter NUM_SEQ_INPUTS = 8;
    parameter NUM_COLUMNS = 8;
	// Declare Final_Vector_Sum
	parameter FINAL_VECTOR_SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS + 1 + NUM_COLUMNS;  //24 bits 
	
    parameter CLK_PERIOD = 10;

	parameter SERIAL_INPUT_LENGTH = 33;
	localparam LAST_BIT_COUNT = SERIAL_INPUT_LENGTH - 1;

    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;  // 15 bits
	
    // Testbench signals
    reg clk;
    reg clear;
    reg input_valid;
    reg signed [NUM_COLUMNS-1:0][INPUT_WIDTH-1:0] data_in;
    wire signed [NUM_COLUMNS-1:0][SUM_WIDTH-1:0] column_sum;
    wire column_sum_ready;

	wire signed [FINAL_VECTOR_SUM_WIDTH - 1:0] Final_Vector_Sum;
	wire array_processing_complete;
	
    // reg signed [NUM_SEQ_INPUTS-1:0][NUM_COLUMNS-1:0][INPUT_WIDTH-1:0] test_data;  //3D MDA 
	reg signed [INPUT_WIDTH-1:0] test_data [0:NUM_SEQ_INPUTS-1][0:NUM_COLUMNS-1]; // 1D x 2D MDA vector
	
	reg TB_DONE;
	
    // DUT instantiation
    column_adder_array #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .NUM_SEQ_INPUTS(NUM_SEQ_INPUTS),
        .NUM_COLUMNS(NUM_COLUMNS),
		.FINAL_VECTOR_SUM_WIDTH(FINAL_VECTOR_SUM_WIDTH)
    ) dut (
        .clk(clk),
        .clear(clear),
        .input_valid(input_valid),
        .data_in(data_in),
        .column_sum(column_sum),
        .out_column_sum_ready(column_sum_ready),
		.Final_Vector_Sum(Final_Vector_Sum),
		.array_processing_complete(array_processing_complete)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test sequence
    integer i, j;
	
    initial begin
        clear = 1;
        input_valid = 0;
        data_in = 0;
		
		TB_DONE = 0;

        // Wait for reset deassertion
        #(2 * CLK_PERIOD);
        clear = 0;
		
        // Apply 8 sequential inputs
        for (i = 0; i < NUM_SEQ_INPUTS; i = i + 1) begin
		
			//emulate delay of 33 clk cycles for T2B module output to become valid 
			repeat(LAST_BIT_COUNT) @(posedge clk); // Wait for 32 clock cycles
			//repeat(LAST_BIT_COUNT + 1) @(posedge clk);
			
			@(posedge clk);
            input_valid <= 1;
            for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
                data_in[j] <= test_data[i][j];
            end
			
            // #(CLK_PERIOD);
			@(posedge clk);
			input_valid <= 0;
			
        end

		// Test robustness: extra input_valid pulses with no data_in change
		@(posedge clk);
		input_valid <= 1;
		@(posedge clk);		
        input_valid <= 0;
		@(posedge clk);
		input_valid <= 1;
		@(posedge clk);		
        input_valid <= 0;
		
        // Wait to observe outputs
        repeat(100) @(posedge clk);
		
		//Test clear again 
		clear = 1;
		repeat(1) @(posedge clk);
		clear = 0; 
        repeat(10) @(posedge clk);
		
		TB_DONE = 1; 
		
		repeat(100) @(posedge clk);
		
        $display("Final Column Sums:");
        for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
            $display("Column %0d: Sum = %0d, Ready = %b", j, column_sum[j], column_sum_ready);
        end

        $finish;
    end

    //Local TB Bit Counter for 0 to 32, starts incrementing on posedge clk when input_valid is high
	// to keep track of ongoing bit count value in T2B module 
    integer iteration_bit_count;
    reg count_enable;
 
    initial begin
        iteration_bit_count = 0;
        count_enable = 0;
    end

    always @(posedge clk) begin
        if (input_valid) begin
            iteration_bit_count <= 0;
            count_enable <= 1;
        end else if (count_enable) begin
            if (iteration_bit_count == 32) begin
                iteration_bit_count <= 0;
                count_enable <= 0;
            end else begin
                iteration_bit_count <= iteration_bit_count + 1;
            end
        end
    end

    // Test data initialization
    initial begin
        // Test data of 8 sequences top-down columnwise (test_data[7][x] to test_data[0][x]) format for 8 columns each
		// Column 0 test data (all +1) = 255
		test_data[7][0] = 6'sd1;
		test_data[6][0] = 6'sd1;
		test_data[5][0] = 6'sd1;
		test_data[4][0] = 6'sd1;
		test_data[3][0] = 6'sd1;
		test_data[2][0] = 6'sd1;
		test_data[1][0] = 6'sd1;
		test_data[0][0] = 6'sd1;

		// Column 1 test data (all -1) = -255
		test_data[7][1] = -6'sd1;
		test_data[6][1] = -6'sd1;
		test_data[5][1] = -6'sd1;
		test_data[4][1] = -6'sd1;
		test_data[3][1] = -6'sd1;
		test_data[2][1] = -6'sd1;
		test_data[1][1] = -6'sd1;
		test_data[0][1] = -6'sd1;

		// Column 2 test data (alternating 1 and 0 starting with 1) = 170
		test_data[7][2] = 6'sd1;
		test_data[6][2] = 6'sd0;
		test_data[5][2] = 6'sd1;
		test_data[4][2] = 6'sd0;
		test_data[3][2] = 6'sd1;
		test_data[2][2] = 6'sd0;
		test_data[1][2] = 6'sd1;
		test_data[0][2] = 6'sd0;

		// Column 3 test data (alternating -1 and 0 starting with -1) = -170
		test_data[7][3] = -6'sd1;
		test_data[6][3] = 6'sd0;
		test_data[5][3] = -6'sd1;
		test_data[4][3] = 6'sd0;
		test_data[3][3] = -6'sd1;
		test_data[2][3] = 6'sd0;
		test_data[1][3] = -6'sd1;
		test_data[0][3] = 6'sd0;

		// Column 4 test data (all +31) = 11111111 (255) x 31 = 7905 
		test_data[7][4] = 6'sd31;
		test_data[6][4] = 6'sd31;
		test_data[5][4] = 6'sd31;
		test_data[4][4] = 6'sd31;
		test_data[3][4] = 6'sd31;
		test_data[2][4] = 6'sd31;
		test_data[1][4] = 6'sd31;
		test_data[0][4] = 6'sd31;

		// Column 5 test data (all -32) = 11111111 (255) x -32 = -8160 
		test_data[7][5] = -6'sd32;
		test_data[6][5] = -6'sd32;
		test_data[5][5] = -6'sd32;
		test_data[4][5] = -6'sd32;
		test_data[3][5] = -6'sd32;
		test_data[2][5] = -6'sd32;
		test_data[1][5] = -6'sd32;
		test_data[0][5] = -6'sd32;

		// Column 6 test data
		test_data[7][6] = 6'sd6;
		test_data[6][6] = 6'sd3;
		test_data[5][6] = 6'sd14;
		test_data[4][6] = -6'sd7;
		test_data[3][6] = 6'sd5;
		test_data[2][6] = 6'sd9;
		test_data[1][6] = -6'sd2;
		test_data[0][6] = 6'sd12;

		// Column 7 test data
		test_data[7][7] = 6'sd1;
		test_data[6][7] = 6'sd10;
		test_data[5][7] = -6'sd6;
		test_data[4][7] = 6'sd2;
		test_data[3][7] = 6'sd15;
		test_data[2][7] = -6'sd11;
		test_data[1][7] = 6'sd8;
		test_data[0][7] = 6'sd4;
	end

endmodule
