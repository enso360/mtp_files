// Seq MAC testbench
module sequential_mac_tb;

    reg clk;
    reg rst;
    reg start;
    reg clear_acc;
    reg [3:0] multiplicand;
    reg [3:0] multiplier;
    reg multiplier_serial_bit_in;
    reg [3:0] multiplier_index;  
	wire [7:0] mult_result; 
    wire [7:0] mac_result;
    wire done;

    // Instantiate the MAC with parameterized widths
    sequential_mac #(
        .MULTIPLICAND_WIDTH(4),
        .MULTIPLIER_WIDTH(4)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .clear_acc(clear_acc),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .multiplier_serial_bit_in(multiplier_serial_bit_in),
		.mult_result(mult_result),  
        .mac_result(mac_result),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        clear_acc = 0;
        multiplicand = 0;
        multiplier = 0;
        multiplier_serial_bit_in = 0;
        multiplier_index = 0;

        // Wait for 100 ns
        #100;
        rst = 0;
        #10;
        
        // Clear accumulator before starting tests
        clear_acc = 1;
        #10;
        clear_acc = 0;
        #10;

        // Test case 1: 2 * 6
        multiplicand = 4'h2;
        multiplier = 4'h6;    
        multiplier_index = 0;
        multiplier_serial_bit_in = multiplier[multiplier_index];
        start = 1;
        #10;
        start = 0;
        
        // Feed multiplier bits serially
        while (multiplier_index < 4) begin
            multiplier_index = multiplier_index + 1;    
            if (multiplier_index < 4) begin 
                multiplier_serial_bit_in = multiplier[multiplier_index];
                #10;
            end
        end
        multiplier_serial_bit_in = 0;
        multiplier_index = 0;
        
        // Wait for completion
        wait(done);
        #20;

        // Test case 2: 3 * 4 (accumulating with previous result)
        multiplicand = 4'h3;
        multiplier = 4'h4;        
        multiplier_index = 0;
        multiplier_serial_bit_in = multiplier[multiplier_index];
        start = 1;
        #10;
        start = 0;
        
        // Feed multiplier bits serially
        while (multiplier_index < 4) begin
            multiplier_index = multiplier_index + 1;        
            if (multiplier_index < 4) begin 
                multiplier_serial_bit_in = multiplier[multiplier_index];
                #10;
            end
        end
        multiplier_serial_bit_in = 0;
        multiplier_index = 0;
        
        // Wait for completion
        wait(done);
        #20;

        // Clear accumulator for next set of tests
        clear_acc = 1;
        #10;
        clear_acc = 0;
        #10;

        // Test case 3: F * F
        multiplicand = 4'hF;
        multiplier = 4'hF;        
        multiplier_index = 0;
        multiplier_serial_bit_in = multiplier[multiplier_index];
        start = 1;
        #10;
        start = 0;
        
        // Feed multiplier bits serially
        while (multiplier_index < 4) begin
            multiplier_index = multiplier_index + 1;        
            if (multiplier_index < 4) begin 
                multiplier_serial_bit_in = multiplier[multiplier_index];
                #10;
            end
        end
        multiplier_serial_bit_in = 0;
        multiplier_index = 0;
        
        // Wait for completion
        wait(done);
        #20;

        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t rst=%b clear_acc=%b start=%b multiplicand=%h multiplier=%h multiplier_serial_bit_in=%b multiplier_index=%d mult_result=%h mac_result=%h done=%b",
                 $time, rst, clear_acc, start, multiplicand, multiplier, multiplier_serial_bit_in, multiplier_index, mult_result, mac_result, done);
    end

    // Waveform generation
    initial begin
        $dumpfile("mac_waveforms.vcd");
        $dumpvars(0,dut);
    end
endmodule
