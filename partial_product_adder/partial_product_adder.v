
module partial_product_adder #(
    parameter DATA_WIDTH = 16
)(
    input clk,
    input reset,
    input signed [DATA_WIDTH-1:0] partial_product,
    input partial_product_valid,
    output reg signed [DATA_WIDTH + DATA_WIDTH - 1:0] result,
    output reg result_ready,
	output reg overflow
);
    
//internal registers
reg signed [DATA_WIDTH + DATA_WIDTH-1:0] accumulator;
reg [$clog2(DATA_WIDTH+DATA_WIDTH)-1:0] count;  // Counter for iterations

always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= {(DATA_WIDTH + DATA_WIDTH){1'b0}};
        result <= {(DATA_WIDTH + DATA_WIDTH){1'b0}};
        result_ready <= 1'b0;
        overflow <= 1'b0;
		count <= {$clog2(DATA_WIDTH+DATA_WIDTH){1'b0}};
    end
    else begin
        if (partial_product_valid) begin
            // Shift the accumulator right by one position using a barrel shifter
			// accumulator <= accumulator >> 1;
            accumulator <= accumulator + (partial_product << count);
            result_ready <= 1'b0;
			count <= count + 1;
        end
        else begin
            result <= accumulator;
            result_ready <= 1'b1;
            overflow <= 1'b0;
        end
    end
end

endmodule
