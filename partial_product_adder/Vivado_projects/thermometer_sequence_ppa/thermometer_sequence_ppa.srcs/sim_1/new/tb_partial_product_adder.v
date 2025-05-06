`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.05.2025 14:53:00
// Design Name: 
// Module Name: tb_partial_product_adder
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


module tb_partial_product_adder();

    parameter DATA_WIDTH = 16;

    // Inputs
    reg clk;
    reg [DATA_WIDTH-1:0] partial_product;
    reg partial_product_valid;
    reg reset;

    // Outputs
    wire [DATA_WIDTH + DATA_WIDTH-1:0] result;
    wire result_ready;
    wire overflow;

    reg TB_DONE = 0;
	
    partial_product_adder #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .partial_product(partial_product),
        .partial_product_valid(partial_product_valid),
        .result(result),
        .result_ready(result_ready),
        .overflow(overflow)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        partial_product = 0;
        partial_product_valid = 0;
        reset = 1;
        #10;
        reset = 0;
		#10

        // Test case 1: Add some positive partial products
        // partial_product = 16'h0; 
        // partial_product_valid = 1;
        // #10;
        partial_product = 16'h100; //
        partial_product_valid = 1;
        #10;
		partial_product = 16'h200; // 
        partial_product_valid = 1;
        #10;
		partial_product = 16'h0;
        partial_product_valid = 0;
        #10;
        $display("Expected result:");   
		$display("\n");

        reset = 1;
        #10;
        reset = 0;
		#10
		
        // Test case 2: Add some negative partial products
        partial_product = 16'h0800; // 2048
        partial_product_valid = 1;
        #10;
        partial_product = 16'hFE00; // -512x2 = -1024
        partial_product_valid = 1;
        #10;
        partial_product = 16'hFF00; // -256x4 = -1024
        partial_product_valid = 1;
        #10;
        partial_product = 16'hFF80; // -128x8 = -1024
        partial_product_valid = 1;
        #10;			
		partial_product = 16'h0;
        partial_product_valid = 0;
        #10;		
        partial_product_valid = 0;
        #10;
        // $display("Expected result: 0x0400");  // +1024
		// $display("\n");
		
        // partial_product = 16'hFC00; // -1024
        // partial_product_valid = 1;
        // #10;
        // partial_product_valid = 0;
        // #10;
        // $display("Expected result: 0x0000");  // 0
		// $display("\n");

        // partial_product = 16'hFC00; // -1024
        // partial_product_valid = 1;
        // #10;
        // partial_product_valid = 0;
        // #10;
        // $display("Expected result: 0xFC00");  // -1024
		// $display("\n");
		
        // Wait for completion
        wait(result_ready);
        #100;
		
		TB_DONE = 1; 
        $finish;
    end

    // initial begin
        // $dumpfile("ppa_waveform.vcd");
        // $dumpvars(0, partial_product_adder_tb);
    // end

    initial begin
        $monitor("partial_product = %h, result = %h, result_ready = %b", partial_product, result, result_ready);
		        // Monitor the signals
        // $monitor("time = %0d, partial_product = %h (%d), result = %h (%d), result_ready = %b",
					// $time, partial_product, $signed(partial_product), result, $signed(result), result_ready);
    end
	
endmodule

