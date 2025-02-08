// Testbench
module sequential_multiplier_tb;
    reg clk;
    reg rst;
    reg start;
    // reg [15:0] multiplicand;
    // reg [15:0] multiplier;
    // wire [31:0] product;
    reg [3:0] multiplicand;
    reg [3:0] multiplier;
    reg multiplier_serial_bit_in;
    reg [3:0] multiplier_index;	
    wire [7:0] product;
    wire done;

    // Instantiate the multiplier with parameterized widths
    sequential_multiplier #(
        // .MULTIPLICAND_WIDTH(16),
        // .MULTIPLIER_WIDTH(16)
		.MULTIPLICAND_WIDTH(4),
        .MULTIPLIER_WIDTH(4)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
		.multiplier_serial_bit_in(multiplier_serial_bit_in),
        .product(product),
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
        multiplicand = 0;
        multiplier = 0;
		multiplier_serial_bit_in = 0; //reset serial bit
        multiplier_index = 0;

        // Wait for 100 ns
        #100;
        rst = 0;
		#10;
        
        // Test case 1: 16'h00FF * 16'h00FF
        // multiplicand = 16'h00FF;
        // multiplier = 16'h00FF;
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
		multiplier_serial_bit_in = 0; //reset serial bit
		multiplier_index = 0;
		multiplicand = 4'h0;
        multiplier = 4'h0;	
		
        // Wait for completion
        wait(done);
        #20;
        
        // Test case 2: 16'hFFFF * 16'hFFFF
        // multiplicand = 16'hFFFF;
        // multiplier = 16'hFFFF;
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
		multiplier_serial_bit_in = 0; //reset serial bit
		multiplier_index = 0;
		multiplicand = 4'h0;
        multiplier = 4'h0;	
		
        // Wait for completion
        wait(done);
        #20;
		
        $finish;
    end

    // Monitor changes
    initial begin
      $monitor("Time=%0t rst=%b start=%b multiplicand=%h multiplier=%h multiplier_serial_bit_in=%b multiplier_index=%d product=%h done=%b",
                 $time, rst, start, multiplicand, multiplier, multiplier_serial_bit_in, multiplier_index, product, done);
    end

    initial
    begin
      $dumpfile("waveforms.vcd");
      $dumpvars(0,dut);
    end  
  
endmodule
