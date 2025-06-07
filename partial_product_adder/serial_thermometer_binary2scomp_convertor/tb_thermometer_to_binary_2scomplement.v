`timescale 1ns / 1ps

module tb_thermometer_to_binary_2scomplement();

    // Parameters
    parameter SERIAL_INPUT_LENGTH = 33;  // 32 bits + 1 sign bit
    parameter CLK_PERIOD = 10;           // Clock period in ns
    
    // Testbench signals
    reg clk;
    reg rst;
    reg start;
    reg serial_in;
    wire valid_out;
    wire [$clog2(SERIAL_INPUT_LENGTH - 1) - 1:0] thermometer_sum_out;
    wire [$clog2(SERIAL_INPUT_LENGTH - 1):0] thermometer_result_2scomp_out;
    
    // Instantiate the DUT (Device Under Test)
    thermometer_to_binary_2scomplement #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .serial_in(serial_in),
        .valid_out(valid_out),
        .thermometer_sum_out(thermometer_sum_out),
        .thermometer_result_2scomp_out(thermometer_result_2scomp_out)
    );
    
    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task to send a 33-bit pattern with sign bit at LSB
    task send_pattern;
        input [32:0] pattern;
        //input [64:0] pattern_name;
        integer i;
        begin
            // $display("Sending pattern %s: %b", pattern_name, pattern);
			$display("Sending pattern: %b", pattern);
            
            // Assert start and send the first bit (sign bit at LSB)
            start = 1;
            serial_in = pattern[0];  // Sign bit at position 0 (LSB)
            @(posedge clk);
            start = 0;
            
            // Send remaining bits one by one
            for (i = 1; i < SERIAL_INPUT_LENGTH; i = i + 1) begin
                serial_in = pattern[i];
                @(posedge clk);
            end
            
            // Wait for valid_out
            wait(valid_out);
            
            // Display results
            // $display("Pattern %s complete: sum=%0d, result=%0d", 
                     // pattern_name, thermometer_sum_out, $signed(thermometer_result_2scomp_out));
			$display("Pattern complete: sum=%0d, result=%0d", 
						thermometer_sum_out, $signed(thermometer_result_2scomp_out));
            
            // Add delay between patterns
            #50;
        end
    endtask
    
    // Main testbench
    initial begin
        // Initialize testbench signals
        clk = 0;
        rst = 1;
        start = 0;
        serial_in = 0;
        
        // Apply reset
        #20 rst = 0;
        #20;
        
        // Test Pattern 1: Positive number with 5 ones
        // Sign bit (at LSB) = 0, 5 data bits = 1, rest = 0
        // send_pattern(33'b00000000000000000000000000011111_0, "Positive 5
		send_pattern(33'b00000000000000000000000000011111_0);
        
        // Test Pattern 2: Negative number with 8 ones
        // Sign bit (at LSB) = 1, 8 data bits = 1, rest = 0
        // send_pattern(33'b00000000000000000000000011111111_1, "Negative 8");
		send_pattern(33'b00000000000000000000000011111111_1);
        
        // // Test Pattern 3: Zero (all zeros)
        // // Sign bit (at LSB) = 0, all data bits = 0
        // send_pattern(33'b00000000000000000000000000000000_0, "Zero");
        
        // // Test Pattern 4: Maximum positive (all ones except sign bit)
        // // Sign bit (at LSB) = 0, all data bits = 1
        // send_pattern(33'b11111111111111111111111111111111_0, "Max Positive");
        
        // // Test Pattern 5: Alternating pattern
        // // Sign bit (at LSB) = 0, alternating data bits
        // send_pattern(33'b10101010101010101010101010101010_0, "Alternating");
        
        // Finish simulation
        $display("Testbench completed");
        $finish;
    end
    
    // Optional: Monitor signals for waveform viewing
    initial begin
        $monitor("Time=%0t: state=%0d, bit_counter=%0d, sum_magnitude=%0d, valid=%0b, sum=%0d, result=%0d", 
                 $time, dut.state, dut.bit_counter, dut.sum_magnitude, valid_out, 
                 thermometer_sum_out, $signed(thermometer_result_2scomp_out));
    end

endmodule

