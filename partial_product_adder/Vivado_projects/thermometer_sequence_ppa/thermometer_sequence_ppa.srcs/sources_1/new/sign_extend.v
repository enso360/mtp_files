`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: sign_extend
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

module sign_extend #(
    parameter IN_WIDTH  = 6,
    parameter OUT_WIDTH = 24
) (
    input  wire [IN_WIDTH-1:0] in,
    output wire [OUT_WIDTH-1:0] sign_extended_out
);
    
    // Parameter validation - ensure OUT_WIDTH is greater than IN_WIDTH
	// instruct the Synthesis tool to ignore blocks of code 
	// refer https://www.intel.com/content/www/us/en/docs/programmable/683283/18-1/translate-off-and-on-synthesis-off-and-on.html 
	
    // synthesis translate_off
	//simulation-only-block-of-code-start
    initial begin
        if (OUT_WIDTH <= IN_WIDTH) begin
            $error("OUT_WIDTH (%0d) must be greater than IN_WIDTH (%0d)", OUT_WIDTH, IN_WIDTH);
            $finish;
        end
    end
	//simulation-only-block-of-code-end 
    // synthesis translate_on
    
    // Sign extension: replicate the MSB (sign bit) to fill the additional bits
    // For positive numbers (MSB=0): pad with zeros
    // For negative numbers (MSB=1): pad with ones
    assign sign_extended_out = {{(OUT_WIDTH - IN_WIDTH){in[IN_WIDTH-1]}}, in};
    
endmodule

