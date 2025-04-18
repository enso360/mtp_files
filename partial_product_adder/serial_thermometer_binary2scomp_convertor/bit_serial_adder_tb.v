
`timescale 1ns / 1ps

module bit_serial_adder_tb;

    // Testbench parameters
    parameter SERIAL_INPUT_LENGTH = 6;

    // Signals
    reg clk;
    reg rst;
    reg start;
    reg serial_in;
    wire valid;
    wire [$clog2(SERIAL_INPUT_LENGTH):0] parallel_sum_out;

    // Instantiate the bit_serial_adder module
    bit_serial_adder #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .serial_in(serial_in),
        .valid(valid),
        .parallel_sum_out(parallel_sum_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Waveform dumping
    initial begin
        $dumpfile("bit_serial_adder_tb.vcd");
        $dumpvars(0, bit_serial_adder_tb);
    end

    // Monitor
    initial begin
        $monitor("Time: %0t, clk: %b, rst: %b, start: %b, serial_in: %b, valid: %b, parallel_sum_out: %d",
                 $time, clk, rst, start, serial_in, valid, parallel_sum_out);
    end

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        serial_in = 0;

        // Reset the module
        @(posedge clk);
        rst = 0;

        // Start the module and pass 6 bits sequentially
        @(posedge clk);
        start = 1;
        serial_in = 1;
        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;
        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;
        @(posedge clk);
        serial_in = 1;
        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;
        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;		

        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;
        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;
		
        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;
        @(posedge clk);
        serial_in = 0;
        @(posedge clk);
        serial_in = 1;
		
		#20;
        // Wait for the module to finish
        //@(posedge valid);
        $display("Parallel sum output: %d", parallel_sum_out);

        // End the simulation
        $finish;
    end

endmodule

