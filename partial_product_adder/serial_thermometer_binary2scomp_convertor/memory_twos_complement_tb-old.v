
`timescale 1ns/1ps

module memory_twos_complement_tb;
    // Testbench signals
    reg [4:0] addr;
    wire [4:0] data_out;
    integer i;
    
    // Instantiate the device under test (DUT)
    memory_twos_complement dut (
        .addr(addr),
        .data_out(data_out)
    );
    
    // VCD dump
    initial begin
        $dumpfile("memory_twos_complement.vcd");
        $dumpvars(0, memory_twos_complement_tb);
        
        // Wait for memory initialization to complete
        #5;
        
        // Display the memory contents first
        $display("Memory Contents:");
        $display("Address\tValue");
        for (i = 0; i < 32; i = i + 1) begin
            $display("%d\t0x%h", i, dut.mem[i]);
        end
        
        // Display header for test
        $display("\nTest Sequence:");
        $display("Time\tAddress\tData Out");
        $monitor("%0t\t%d\t0x%h", $time, addr, data_out);
        
        // Initialize inputs
        addr = 5'b00000;
        #10; // Wait for first read to complete
        
        // Test all addresses
        repeat (31) begin
            addr = addr + 1'b1;
            #10; // Wait for each read to complete
        end
        
        // End simulation
        #10 $finish;
    end
    
    // For Icarus Verilog - use a separate process to log memory values periodically
    initial begin
        #5; // Wait for initialization
        
        // Log memory values at specific time points
        repeat (35) begin
            #10;
            $display("Time %0t: Memory[%0d] = 0x%h", $time, addr, dut.mem[addr]);
        end
    end
endmodule
