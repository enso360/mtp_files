
// Testbench
module sequential_multiplier_tb;
    reg clk;
    reg rst;
    reg start;
    reg [15:0] multiplicand;
    reg [15:0] multiplier;
    wire [31:0] product;
    wire done;

    // Instantiate the multiplier
    sequential_multiplier dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
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

        // Wait for 100 ns
        #100;
        rst = 0;
        
        // Test case 1: 16'h00FF * 16'h00FF
        multiplicand = 16'h00FF;
        multiplier = 16'h00FF;
        start = 1;
        #10;
        start = 0;
        
        // Wait for completion
        wait(done);
        #20;
        
        // Test case 2: 16'hFFFF * 16'h0001
        multiplicand = 16'hFFFF;
        multiplier = 16'hFFFF;
        start = 1;
        #10;
        start = 0;
        
        // Wait for completion
        wait(done);
        #20;
                
        $finish;
    end

    // Monitor changes
    initial begin
      $monitor("Time=%0t rst=%b start=%b multiplicand=%h multiplier=%h product=%h done=%b",
                 $time, rst, start, multiplicand, multiplier, product, done);
    end

    initial
    begin
      $dumpfile("waveforms.vcd");
      $dumpvars(0,dut);
    end  
  
endmodule
