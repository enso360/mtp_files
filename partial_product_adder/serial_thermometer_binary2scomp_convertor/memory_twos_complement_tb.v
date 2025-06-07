
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
        
        // Wait for memory initialization
        #10;
        
        // Display header
        $display("Address\tData Out");
        
        // Test each address one by one
        for (i = 0; i < 32; i = i + 1) begin
            addr = i[4:0];
            #10; // Wait for read to complete
            $display("%d\t0x%h", addr, data_out);
        end
        
        // End simulation
        #10 $finish;
    end
endmodule
