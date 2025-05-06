`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.05.2025 16:18:29
// Design Name: 
// Module Name: tb_thermo_partial_product_system
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

module tb_thermo_partial_product_system();

    parameter SERIAL_INPUT_LENGTH = 33;  // 32 bits + 1 sign bit
    parameter DATA_WIDTH = 6;           // Width for partial product adder
    parameter CLK_PERIOD = 10;          // Clock period in ns
    
    // Common signals
    reg clk;
    reg rst;
    
    // Thermometer module signals
    reg thermo_start;
    reg thermo_serial_in;
    wire thermo_valid_out;
    wire [$clog2(SERIAL_INPUT_LENGTH - 1) - 1:0] thermometer_sum_out;
    wire [$clog2(SERIAL_INPUT_LENGTH - 1):0] thermometer_result_2scomp_out;
    
    // Partial product adder signals
    reg pp_reset;
    reg pp_valid;
    wire [DATA_WIDTH + DATA_WIDTH - 1:0] pp_result;
    wire pp_ready;
    wire pp_overflow;
    
    // Test control
    reg [2:0] state;
    reg [1:0] test_index;
    integer bit_counter;
    reg TB_DONE;
    
    // Define FSM states
    localparam IDLE = 0;
    localparam SEND_TO_THERM = 1;
    localparam WAIT_FOR_THERM = 2;
    localparam ADD_PARTIAL_PRODUCT = 3;
    localparam WAIT_FOR_PP = 4;
    localparam DONE = 5;
    
    // Test patterns for thermometer encoding with sign bit at LSB
    reg [32:0] test_patterns [0:3];
    reg [64:0] pattern_names [0:3];
    
    // Instantiate thermometer_to_binary_2scomplement module
    thermometer_to_binary_2scomplement #(
        .SERIAL_INPUT_LENGTH(SERIAL_INPUT_LENGTH)
    ) thermo_converter (
        .clk(clk),
        .rst(rst),
        .start(thermo_start),
        .serial_in(thermo_serial_in),
        .valid_out(thermo_valid_out),
        .thermometer_sum_out(thermometer_sum_out),
        .thermometer_result_2scomp_out(thermometer_result_2scomp_out)
    );
    
    // Instantiate partial_product_adder module
    partial_product_adder #(
        .DATA_WIDTH(DATA_WIDTH)
    ) pp_adder (
        .clk(clk),
        .reset(pp_reset),
        .partial_product(thermometer_result_2scomp_out),  // Connect to thermometer output
        .partial_product_valid(pp_valid),
        .result(pp_result),
        .result_ready(pp_ready),
        .overflow(pp_overflow)
    );
    
    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Initialize test patterns
    initial begin
        // Define test patterns with sign bit at LSB
        // +7: 7 ones followed by sign bit 0
        test_patterns[0] = 33'b00000000000000000000000001111111_0;
        pattern_names[0] = "Positive 7";
        
        // -4: 28 in 2s complement
        test_patterns[1] = 33'b00011111111111111111111111111111_1;
        pattern_names[1] = "Negative 4";
        
        // +2: 2 ones followed by sign bit 0
        test_patterns[2] = 33'b00000000000000000000000000000011_0;
        pattern_names[2] = "Positive 2";
        
        // +1: 1 one followed by sign bit 0
        test_patterns[3] = 33'b00000000000000000000000000000001_0;
        pattern_names[3] = "Positive 1";
    end

    // Main test procedure
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        pp_reset = 1;
        thermo_start = 0;
        thermo_serial_in = 0;
        pp_valid = 0;
        state = IDLE;
        test_index = 0;
        bit_counter = 0;
        TB_DONE = 0;
        
        // Reset sequence
        #30;
        rst = 0;
        pp_reset = 0;
        #20;
        
        // Move to first state
        state = IDLE;
        
        // Wait for test completion
        wait(TB_DONE);
        #50;
        
        $display("Testbench completed successfully");
        $finish;
    end
    
    // FSM for test control
    always @(posedge clk) begin
        case(state)
            IDLE: begin
                if (!rst && !pp_reset) begin
                    $display("Starting test sequence %0d: %s", test_index, pattern_names[test_index]);
                    state <= SEND_TO_THERM;
                    bit_counter <= 0;
                end
            end
            
            SEND_TO_THERM: begin
                if (bit_counter == 0) begin
                    // Start thermometer conversion and send first bit (sign bit)
                    thermo_start <= 1;
                    thermo_serial_in <= test_patterns[test_index][0];
                    bit_counter <= bit_counter + 1;
                    $display("Sending thermometer pattern %s: %b", pattern_names[test_index], test_patterns[test_index]);
                end
                else if (bit_counter < SERIAL_INPUT_LENGTH) begin
                    // Send the rest of the bits
                    thermo_start <= 0;
                    thermo_serial_in <= test_patterns[test_index][bit_counter];
                    bit_counter <= bit_counter + 1;
                end
                else begin
                    // All bits sent, wait for result
                    thermo_serial_in <= 0;
                    state <= WAIT_FOR_THERM;
                end
            end
            
            WAIT_FOR_THERM: begin
                if (thermo_valid_out) begin
                    $display("Thermometer conversion complete for %s: sum=%0d, 2's comp=%0d", 
                             pattern_names[test_index], thermometer_sum_out, $signed(thermometer_result_2scomp_out));
                    state <= ADD_PARTIAL_PRODUCT;
                end
            end
            
            ADD_PARTIAL_PRODUCT: begin
                // Send the result to the partial product adder for one clock cycle
                pp_valid <= 1;
                state <= WAIT_FOR_PP;
            end
            
            WAIT_FOR_PP: begin
                // De-assert valid after one clock cycle
                pp_valid <= 0;
                
                if (pp_ready) begin
                    $display("Partial product addition complete: result=%0d, overflow=%0b", 
                              $signed(pp_result), pp_overflow);
                    
                    // Move to next test pattern or finish
                    if (test_index < 3) begin
                        test_index <= test_index + 1;
                        state <= IDLE;
                    end
                    else begin
                        state <= DONE;
                    end
                end
            end
            
            DONE: begin
                if (!TB_DONE) begin
                    $display("All tests completed. Final accumulator result = %0d", $signed(pp_result));
                    TB_DONE <= 1;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
    
    // Optional: Monitor signals for debugging
    initial begin
        $monitor("Time=%0t: state=%0d, test=%0d, bit=%0d, thermo_valid=%0b, thermo_out=%0d, pp_ready=%0b, pp_result=%0d", 
                 $time, state, test_index, bit_counter, thermo_valid_out, 
                 $signed(thermometer_result_2scomp_out), pp_ready, $signed(pp_result));
    end

endmodule

