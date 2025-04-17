
`timescale 1ns/1ps

module priority_encoder_tb();
    // Parameters
    parameter WIDTH = 64;
    parameter LOG_WIDTH = $clog2(WIDTH);
    
    // Signals
    reg [WIDTH-1:0] data_in;
    reg clear;
    wire [LOG_WIDTH-1:0] data_out;
    wire [LOG_WIDTH:0] signed_out;
    wire valid;
    
    // Instantiate the unit under test (UUT)
    priority_encoder #(
        .WIDTH(WIDTH),
        .LOG_WIDTH(LOG_WIDTH)
    ) uut (
        .data_in(data_in),
        .clear(clear),
        .data_out(data_out),
        .signed_out(signed_out),
        .valid(valid)
    );
    
    // Setup waveform dumping
    initial begin
        $dumpfile("priority_encoder_waveform.vcd");
        $dumpvars(0, priority_encoder_tb);
        
        // Monitor outputs
        $monitor("Time=%0t, clear=%b, data_in=%h, data_out=%d, signed_out=%d, valid=%b", 
                 $time, clear, data_in, data_out, signed_out, valid);
    end
    
    // Test sequence
    initial begin
        // Initialize inputs
        data_in = 64'h0;
        clear = 0;
        
        // Wait for global reset
        #10;
        
        // Test case 1: No bits set, clear inactive
        data_in = 64'h0;
        clear = 0;
        #10;
        
        // Test case 2: Lowest bit set (bit 0)
        data_in = 64'h1;
        #10;
        
        // Test case 3: Bit 5 set
        data_in = 64'h20;
        #10;
        
        // Test case 4: Multiple bits set (should pick highest)
        data_in = 64'h88;  // Bits 3 and 7 set
        #10;
        
        // Test case 5: Highest bit set (bit 63)
        data_in = 64'h8000000000000000;
        #10;
        
        // Test case 6: Multiple bits across the range
        data_in = 64'h8010000200004001;  // Bits 0, 14, 33, 52, 63
        #10;
        
        // Test case 7: All bits set
        data_in = {WIDTH{1'b1}};
        #10;
        
        // Test case 8: Clear signal active with bits set
        data_in = 64'hFFFFFFFFFFFFFFFF;
        clear = 1;
        #10;
        
        // Test case 9: Clear inactive again
        clear = 0;
        #10;


        data_in = 64'h0000000000000001;
        #10;
        
        data_in = 64'h0000000000000008;
        #10;

        data_in = 64'h0000000000000010;
        #10;
		
        data_in = 64'h0000000000000100;
        #10;		
		
        data_in = 64'h000000000000A000;
        #10;
		
        // End simulation
        #10;
        $display("Simulation completed successfully");
        $finish;
    end
endmodule
