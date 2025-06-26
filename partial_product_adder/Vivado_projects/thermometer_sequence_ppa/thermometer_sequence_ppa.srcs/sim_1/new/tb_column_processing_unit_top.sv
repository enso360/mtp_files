`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_column_processing_unit_top
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

module tb_column_processing_unit_top();

    // Parameters
    parameter SERIAL_INPUT_LENGTH = 33;
    parameter T2B_OUT_WIDTH = 6;
    parameter NUM_COLUMNS = 8;
    parameter NUM_SEQ_INPUTS = 8;
    parameter FINAL_VECTOR_SUM_WIDTH = 24;
    parameter CLK_PERIOD = 10;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg clear;
    reg start_conversion;
    reg [NUM_COLUMNS-1:0] serial_thermo_in;
    
    // Outputs
    wire signed [NUM_COLUMNS-1:0][(T2B_OUT_WIDTH + 1 + NUM_SEQ_INPUTS) - 1:0] column_sum;
    wire signed [FINAL_VECTOR_SUM_WIDTH - 1:0] final_vector_sum;
    wire conversion_valid;
    wire column_sum_ready;
    wire processing_complete;
    
    // Test control
    reg TB_DONE = 0;
    integer iteration_count = 0;
    
    // DUT instantiation
    column_processing_unit_top #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH),
        .T2B_OUT_WIDTH(T2B_OUT_WIDTH),
        .NUM_COLUMNS(NUM_COLUMNS),
        .NUM_SEQ_INPUTS(NUM_SEQ_INPUTS),
        .FINAL_VECTOR_SUM_WIDTH(FINAL_VECTOR_SUM_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .start_conversion(start_conversion),
        .serial_thermo_in(serial_thermo_in),
        .column_sum(column_sum),
        .final_vector_sum(final_vector_sum),
        .conversion_valid(conversion_valid),
        .column_sum_ready(column_sum_ready),
        .processing_complete(processing_complete)
    );
    
    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task to send a 33-bit thermometer code pattern to all columns
    task send_pattern_to_all_columns;
        input [32:0] pattern;
        input [127:0] pattern_name; // Increased width for longer names
        integer i, j;
        begin
            $display("Iteration %0d: Sending pattern %s: %b", iteration_count, pattern_name, pattern);
            
            @(posedge clk);
            // Send the start signal and first bit (inverted sign bit)
            start_conversion <= 1;
            
            @(posedge clk);
            // Send sign bit to all columns
            for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
                serial_thermo_in[j] <= pattern[0]; // Sign bit at position 0
            end
            start_conversion <= 0;
            
            // Send remaining 32 bits
            for (i = 1; i < SERIAL_INPUT_LENGTH; i = i + 1) begin
                @(posedge clk);
                for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
                    serial_thermo_in[j] <= pattern[i];
                end
            end
            
            // Idle input
            @(posedge clk);
            for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
                serial_thermo_in[j] <= 0;
            end
            
            // Wait for conversion to complete
            wait(conversion_valid);
            $display("Conversion %0d completed. T2B results ready.", iteration_count);
            
            // Wait one more clock cycle to ensure data is stable
            @(posedge clk);
            
            iteration_count = iteration_count + 1;
        end
    endtask
    
    // Task to wait for column processing to complete
    task wait_for_processing_complete;
        begin
            $display("Waiting for all column processing to complete...");
            wait(processing_complete);
            $display("All processing completed!");
            
            // Display final results
            $display("\n=== FINAL RESULTS ===");
            $display("Final Vector Sum: %0d", final_vector_sum);
            $display("Column Sum Ready: %b", column_sum_ready);
            
            $display("\nIndividual Column Sums:");
            for (integer k = 0; k < NUM_COLUMNS; k = k + 1) begin
                $display("Column %0d Sum: %0d", k, column_sum[k]);
            end
            $display("=====================\n");
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        clear = 1;
        start_conversion = 0;
        serial_thermo_in = 0;
        iteration_count = 0;
        
        // Reset sequence
        repeat(3) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);
        clear = 0;
        repeat(2) @(posedge clk);
        
        $display("Starting Column Processing Unit Top Testbench");
        $display("SERIAL_INPUT_LENGTH = %0d, T2B_OUT_WIDTH = %0d", SERIAL_INPUT_LENGTH, T2B_OUT_WIDTH);
        $display("NUM_COLUMNS = %0d, NUM_SEQ_INPUTS = %0d", NUM_COLUMNS, NUM_SEQ_INPUTS);
        $display("FINAL_VECTOR_SUM_WIDTH = %0d", FINAL_VECTOR_SUM_WIDTH);
        
        // Send the same pattern (+1) to all columns for NUM_SEQ_INPUTS iterations
        repeat(NUM_SEQ_INPUTS) begin
            // send_pattern_to_all_columns(33'b00000000000000000000000000000001_1, "Positive 1");
			// send_pattern_to_all_columns(33'b00000000000000000000000000000011_1, "Test input +2");
			// send_pattern_to_all_columns(33'b00111111111111111111111111111111_0, "Negative 2");  //-2
			// send_pattern_to_all_columns(33'b01111111111111111111111111111111_1, "Positive 31"); // +31
			send_pattern_to_all_columns(33'b00000000000000000000000000000000_0, "Negative 32");  // -32
			
            #20; // Small delay between iterations
        end
        
        // Wait for all processing to complete
        wait_for_processing_complete();
        
        // Additional delay for observation
        #100;
        
        // Test clear functionality
        $display("Testing clear functionality...");
        clear = 1;
        repeat(2) @(posedge clk);
        clear = 0;
        repeat(2) @(posedge clk);
        
        $display("After clear - Column Sum Ready: %b", column_sum_ready);
        $display("After clear - Processing Complete: %b", processing_complete);
        
        #100;
        TB_DONE = 1;
        #100;
		
        $display("Testbench completed successfully!");
        $finish;
    end
    
    // // Monitor for debugging
    // initial begin
        // $monitor("Time: %0t | Iteration: %0d | Conv_Valid: %b | Sum_Ready: %b | Proc_Complete: %b | Final_Sum: %0d", 
                 // $time, iteration_count, conversion_valid, column_sum_ready, processing_complete, final_vector_sum);
    // end
    
    // Timeout protection
    initial begin
        #100000; // 100us timeout
        if (!TB_DONE) begin
            $display("ERROR: Testbench timeout!");
            $finish;
        end
    end

endmodule

