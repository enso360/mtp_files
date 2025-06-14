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

module tb_column_adder;

    // Parameters
    localparam INPUT_WIDTH = 6;
    localparam NUM_SEQ_INPUTS = 8;
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;
	
	localparam MAX_TEST_INPUTS = 10;

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
    always #10 clk = ~clk;  

    // Test vector
    reg signed [INPUT_WIDTH-1:0] input_data [0:MAX_TEST_INPUTS+2];
    integer i;
	reg TB_COMPLETED;

    initial begin
        $display("Starting test...");
        clk = 0;
        clear = 1;
        input_valid = 0;
        in = 0;
		TB_COMPLETED = 0;

        // Initialize test input: 8 values (mix of positive and negative 1s) = -170 
        // input_data[0] = 6'sd0;
        // input_data[1] = -6'sd1;
        // input_data[2] = 6'sd0;
        // input_data[3] = -6'sd1;
        // input_data[4] = 6'sd0;
        // input_data[5] = -6'sd1;
        // input_data[6] = 6'sd0;
        // input_data[7] = -6'sd1;
		
		// //extra inputs 
		// input_data[8] = 6'sd0;
		// input_data[9] = 6'sd1;
		// input_data[10] = 6'sd0;

		// all max positive signed values (11111111 = 255) x +31 = 7905 
        // input_data[1] = 6'sd31;
        // input_data[2] = 6'sd31;
        // input_data[3] = 6'sd31;
        // input_data[4] = 6'sd31;
        // input_data[5] = 6'sd31;
        // input_data[6] = 6'sd31;
        // input_data[7] = 6'sd31;

		// all max negative signed values = (11111111 = 255) x -32 = 8160
        input_data[0] = -6'sd32;
        input_data[1] = -6'sd32;
        input_data[2] = -6'sd32;
        input_data[3] = -6'sd32;
        input_data[4] = -6'sd32;
        input_data[5] = -6'sd32;
        input_data[6] = -6'sd32;
        input_data[7] = -6'sd32;
		
		//extra inputs 
		input_data[8] = 6'sd0;
		input_data[9] = 6'sd1;
		input_data[10] = 6'sd0;
		
        // Wait for a few cycles with clear asserted
        #20;
        clear = 0;

		#5
        // Feed inputs one by one
        for (i = 0; i < MAX_TEST_INPUTS; i = i + 1) begin
            @(posedge clk);
            in <= input_data[i];
            input_valid <= 1;
			
            @(posedge clk);
            input_valid <= 0;
        end

        // Wait for ready signal
        wait (column_sum_ready == 1);

        @(posedge clk);
        $display("Final Column Sum = %0d (binary: %b)", column_sum, column_sum);

        // Done
		TB_COMPLETED = 1;
		#20;
        $finish;
    end

	//manual workaround to display state names in waveform 
	reg [8*12:1] state_str;  // 12-char string max

	always @(*) begin
		//access dut internal signal like this to avoid simulation error 
		case (dut.state)
			2'b00: state_str = "IDLE";
			2'b01: state_str = "PROCESSING";
			2'b10: state_str = "DONE";
			2'b11: state_str = "HALT";
			default: state_str = "UNKNOWN";
		endcase
	end

endmodule
