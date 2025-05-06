`timescale 1ns / 1ps

module tb_thermometer_to_binary_2scomplement();

    parameter SERIAL_INPUT_LENGTH = 33;  // 32 bits + 1 sign bit
    parameter CLK_PERIOD = 10;           // Clock period in ns
    
    reg clk;
    reg rst;
    reg start;
    reg serial_in;
    wire valid_out;
    wire [$clog2(SERIAL_INPUT_LENGTH - 1) - 1:0] thermometer_sum_out;
    wire [$clog2(SERIAL_INPUT_LENGTH - 1):0] thermometer_result_2scomp_out;
    
	reg TB_DONE = 0;
	
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
    
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task to send a 33-bit pattern with sign bit at LSB
    task send_pattern;
        input [32:0] pattern;
        input [64:0] pattern_name;
        integer i;
        begin
		
			@(posedge clk);
            $display("Sending pattern %s: %b", pattern_name, pattern);
            
            // Assert start and send the first bit (sign bit at LSB)
			start = 1;
            serial_in = pattern[0];  // Sign bit at position 0 (LSB)			
			@(posedge clk);
			#5;
            start = 0;
			// @(posedge clk);
			#5;
			
            // Send remaining bits one by one
            for (i = 1; i < (SERIAL_INPUT_LENGTH); i = i + 1) begin  //todo //hack
				@(posedge clk);
                serial_in = pattern[i];
            end
            
			// @(posedge clk);
			#5;
			serial_in = 0;  //diable serial input to prevent invalid computation  //todo
			
            wait(valid_out); 
            
            $display("Pattern %s complete: sum=%0d, result=%0d", 
                     pattern_name, thermometer_sum_out, $signed(thermometer_result_2scomp_out));
            
            // Add delay between patterns
            #50;
        end
    endtask
    

    initial begin
        
        clk = 0;
        rst = 1;
        start = 0;
        serial_in = 0;
        
        #20 rst = 0;
        #20;
        
        // Test Patterns: 

        send_pattern(33'b00000000000000000000000000011111_0, "Positive 5");
        #20;

        send_pattern(33'b00000000000000000000000000011111_1, "Negative 5");
        #20;

        send_pattern(33'b01111111111111111111111111111111_0, "Max Positive");  //max is +31, not +32
        #20;

        send_pattern(33'b11111111111111111111111111111111_0, "Overflow");  //32 will overflow to 0
        #20;

        send_pattern(33'b11111111111111111111111111111111_1, "Max negative");  //-32
        #20;
		
        send_pattern(33'b01111111111111111111111111111111_1, "Negative -31");
        #20;		
		
        send_pattern(33'b10101010101010101010101010101010_0, "Alternating");  //+16
        #20;
		
        send_pattern(33'b00000000000000000000000111111111_1, "Negative 9");
        #20;		
        
		TB_DONE = 1; 
		#50;
		
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

