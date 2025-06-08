`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_sign_extend
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

module tb_sign_extend();

    // Parameters - matching DUT
    parameter IN_WIDTH  = 6;
    parameter OUT_WIDTH = 24;
    
    // Testbench signals
    reg [IN_WIDTH-1:0] tb_in;
    wire [OUT_WIDTH-1:0] tb_sign_extended_out;
    
    sign_extend #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .in(tb_in),
        .sign_extended_out(tb_sign_extended_out)
    );
    
    initial begin
        $display("Starting sign_extend testbench");
        $display("Input Width: %0d, Output Width: %0d", IN_WIDTH, OUT_WIDTH);
        $display("Time\t Input\t\t Output\t\t\t Expected");
        $display("----\t -----\t\t ------\t\t\t --------");
        
        // Test case 1: Positive number (MSB = 0)
        #10;
        tb_in = 6'b010101; // +21 in decimal
        #1;
        $display("%0t\t %b(%0d)\t %h\t Should be 0x000015", $time, tb_in, $signed(tb_in), tb_sign_extended_out);
        
        // Test case 2: Another positive number
        #10;
        tb_in = 6'b011111; // +31 in decimal (max positive for 6-bit)
        #1;
        $display("%0t\t %b(%0d)\t %h\t Should be 0x00001F", $time, tb_in, $signed(tb_in), tb_sign_extended_out);
        
        // Test case 3: Zero
        #10;
        tb_in = 6'b000000; // 0
        #1;
        $display("%0t\t %b(%0d)\t %h\t Should be 0x000000", $time, tb_in, $signed(tb_in), tb_sign_extended_out);
        
        // Test case 4: Negative number (MSB = 1)
        #10;
        tb_in = 6'b111111; // -1 in two's complement
        #1;
        $display("%0t\t %b(%0d)\t %h\t Should be 0xFFFFFF", $time, tb_in, $signed(tb_in), tb_sign_extended_out);
        
        // Test case 5: Another negative number
        #10;
        tb_in = 6'b101010; // -22 in two's complement
        #1;
        $display("%0t\t %b(%0d)\t %h\t Should be 0xFFFFEA", $time, tb_in, $signed(tb_in), tb_sign_extended_out);
        
        // Test case 6: Most negative number
        #10;
        tb_in = 6'b100000; // -32 in two's complement (most negative for 6-bit)
        #1;
        $display("%0t\t %b(%0d)\t %h\t Should be 0xFFFFE0", $time, tb_in, $signed(tb_in), tb_sign_extended_out);
        
        // Test case 7: Edge case - just negative
        #10;
        tb_in = 6'b111110; // -2 in two's complement
        #1;
        $display("%0t\t %b(%0d)\t %h\t Should be 0xFFFFFE", $time, tb_in, $signed(tb_in), tb_sign_extended_out);
        
		
		
        // Verification with assertions
        #10;
        $display("\nRunning verification checks...");
        
        // Check positive number
        tb_in = 6'b010101;
        #1;
        if (tb_sign_extended_out == 24'h000015)
            $display("Positive number test PASSED");
        else
            $display("Positive number test FAILED: Expected 0x000015, Got 0x%06h", tb_sign_extended_out);
            
        // Check negative number
        tb_in = 6'b111111;
        #1;
        if (tb_sign_extended_out == 24'hFFFFFF)
            $display("Negative number test PASSED");
        else
            $display("Negative number test FAILED: Expected 0xFFFFFF, Got 0x%06h", tb_sign_extended_out);
            
        // Check zero
        tb_in = 6'b000000;
        #1;
        if (tb_sign_extended_out == 24'h000000)
            $display("Zero test PASSED");
        else
            $display("Zero test FAILED: Expected 0x000000, Got 0x%06h", tb_sign_extended_out);
        
        #10;
        $display("\nTestbench completed");
        $finish;
    end
    
    // Optional: Monitor changes
    initial begin
        $monitor("Time=%0t: in=%b(%0d) -> sign_extended_out=%h", 
                 $time, tb_in, $signed(tb_in), tb_sign_extended_out);
    end

endmodule

