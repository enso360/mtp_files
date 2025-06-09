`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb2_column_adder
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

module tb2_column_adder;

    // Parameters
    parameter INPUT_WIDTH = 6;
    parameter NUM_SEQ_INPUTS = 8;
    parameter SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;
    
    // Clock period
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz
    
    // Testbench signals
    reg clk;
    reg clear;
    reg signed [INPUT_WIDTH-1:0] in;
    reg input_valid;
    wire signed [SUM_WIDTH-1:0] column_sum;
    wire column_sum_ready;
    
    // Test data storage
    reg signed [INPUT_WIDTH-1:0] test_inputs [0:NUM_SEQ_INPUTS-1];
    integer i;
    
    // DUT instantiation
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
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // // Initialize waveform dump
        // $dumpfile("column_adder_tb.vcd");
        // $dumpvars(0, tb_column_adder);
        
        // Initialize signals
        clear = 0;
        in = 0;
        input_valid = 0;
        
        // Initialize test data (using signed notation for clarity)
        test_inputs[0] = 6'sd1;   // +1
        test_inputs[1] = 6'sd2;   // +2  
        test_inputs[2] = 6'sd4;   // +4
        test_inputs[3] = 6'sd8;   // +8
        test_inputs[4] = 6'sd16;  // +16
        test_inputs[5] = 6'sd31;  // +31 (max positive for 6-bit signed)
        test_inputs[6] = -6'sd1;  // -1
        test_inputs[7] = -6'sd16; // -16
        
        $display("=== Column Adder Testbench Start ===");
        $display("Time\t\tClear\tValid\tInput\tCount\tSum\t\tReady");
        
        // Wait for a few clocks
        repeat(3) @(posedge clk);
        
        // Test Case 1: Normal operation
        $display("\n--- Test Case 1: Normal Operation ---");
        test_sequence("Normal");
        
        // Wait between tests
        repeat(5) @(posedge clk);
        
        // Test Case 2: Test with different values
        $display("\n--- Test Case 2: Different Values ---");
        test_inputs[0] = 6'sd10;
        test_inputs[1] = 6'sd20;
        test_inputs[2] = 6'sd30;
        test_inputs[3] = -6'sd5;
        test_inputs[4] = -6'sd10;
        test_inputs[5] = 6'sd15;
        test_inputs[6] = 6'sd25;
        test_inputs[7] = -6'sd20;
        test_sequence("Different");
        
        // Test Case 3: Edge case - all zeros
        repeat(5) @(posedge clk);
        $display("\n--- Test Case 3: All Zeros ---");
        for (i = 0; i < NUM_SEQ_INPUTS; i = i + 1) begin
            test_inputs[i] = 6'sd0;
        end
        test_sequence("Zeros");
        
        // Test Case 4: Edge case - alternating max/min
        repeat(5) @(posedge clk);
        $display("\n--- Test Case 4: Max/Min Values ---");
        for (i = 0; i < NUM_SEQ_INPUTS; i = i + 1) begin
            test_inputs[i] = (i % 2 == 0) ? 6'sd31 : -6'sd32;
        end
        test_sequence("MaxMin");
        
        // Test Case 5: Test invalid input after completion
        repeat(5) @(posedge clk);
        $display("\n--- Test Case 5: Input After Completion ---");
        test_input_after_complete();
        
        repeat(10) @(posedge clk);
        $display("\n=== Testbench Complete ===");
        $finish;
    end
    
    // Task to run a complete test sequence
    task test_sequence;
        input [63:0] test_name;
        integer j;
        begin
            // Apply clear
            @(posedge clk);
            clear = 1;
            @(posedge clk);
            clear = 0;
            
            // Wait one clock for clear to take effect
            @(posedge clk);
            
            // Apply inputs sequentially
            for (j = 0; j < NUM_SEQ_INPUTS; j = j + 1) begin
                @(posedge clk);
                in = test_inputs[j];
                input_valid = 1;
                @(posedge clk);
                input_valid = 0;
                
                // Monitor progress
                if (j < NUM_SEQ_INPUTS - 1) begin
                    $display("%0t ps\t%b\t%b\t%0d\t%0d\t%0d\t\t%b", 
                             $time, clear, input_valid, in, 
                             dut.iteration_count, column_sum, column_sum_ready);
                end
            end
            
            // Wait for completion and check ready signal
            @(posedge clk);
            if (column_sum_ready) begin
                $display("%s Test: PASS - Final sum = %0d (0x%h)", 
                         test_name, column_sum, column_sum);
            end else begin
                $display("%s Test: FAIL - Ready signal not asserted", test_name);
            end
        end
    endtask
    
    // Task to test behavior after completion
    task test_input_after_complete;
        integer k;
        reg signed [SUM_WIDTH-1:0] final_sum;
        begin
            // Run a normal sequence first
            @(posedge clk);
            clear = 1;
            @(posedge clk);
            clear = 0;
            
            // Apply all inputs
            for (k = 0; k < NUM_SEQ_INPUTS; k = k + 1) begin
                @(posedge clk);
                in = k + 1;  // Simple test pattern
                input_valid = 1;
                @(posedge clk);
                input_valid = 0;
            end
            
            // Store final sum
            @(posedge clk);
            final_sum = column_sum;
            
            // Try to apply more inputs after completion
            $display("Attempting input after completion...");
            for (k = 0; k < 3; k = k + 1) begin
                @(posedge clk);
                in = 6'sd31;  // Max positive value
                input_valid = 1;
                @(posedge clk);
                input_valid = 0;
                
                if (column_sum == final_sum) begin
                    $display("PASS - Sum held constant after completion");
                end else begin
                    $display("FAIL - Sum changed after completion: %0d -> %0d", 
                             final_sum, column_sum);
                end
            end
        end
    endtask
    
    // Monitor for debugging (optional - can be commented out)
    always @(posedge clk) begin
        if (input_valid || column_sum_ready) begin
            $display("%0t: in=%0d, valid=%b, count=%0d, sum=%0d, ready=%b", 
                     $time, in, input_valid, dut.iteration_count, 
                     column_sum, column_sum_ready);
        end
    end

endmodule
