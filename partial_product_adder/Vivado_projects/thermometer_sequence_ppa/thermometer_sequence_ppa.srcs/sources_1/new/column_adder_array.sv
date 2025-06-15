`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Bombay
// Engineer: Karan J.
// 
// Create Date: 
// Design Name: 
// Module Name: column_adder_array
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

module column_adder_array #(
    parameter INPUT_WIDTH = 6,
    parameter NUM_SEQ_INPUTS = 8,
    parameter NUM_COLUMNS = 8
)(
    input wire clk,
    input wire clear,
    input wire input_valid,
    
    // A 2D packed array for input data - NUM_COLUMNS x  INPUT_WIDTH - easier to connect and parameterize
    input wire signed [NUM_COLUMNS-1:0][INPUT_WIDTH-1:0] data_in,
    
    // Packed arrays for outputs - NUM_COLUMNS x Sum Width 
    output wire signed [NUM_COLUMNS-1:0][(INPUT_WIDTH + 1 + NUM_SEQ_INPUTS) - 1:0] column_sum,
    output wire [NUM_COLUMNS-1:0] column_sum_ready
);

    // Internal parameter for output width
    localparam SUM_WIDTH = INPUT_WIDTH + 1 + NUM_SEQ_INPUTS;

    // Generate block for creating column adders
    genvar i;
    generate
        for (i = 0; i < NUM_COLUMNS; i = i + 1) begin : gen_column_adders
            column_adder #(
                .INPUT_WIDTH(INPUT_WIDTH),
                .NUM_SEQ_INPUTS(NUM_SEQ_INPUTS)
            ) column_adder_inst (
                .clk(clk),
                .clear(clear),
                .in(data_in[i]),
                .input_valid(input_valid),
                .column_sum(column_sum[i]),
                .column_sum_ready(column_sum_ready[i])
            );
        end
    endgenerate

endmodule
