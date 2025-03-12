
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
    

reg signed [DATA_WIDTH + DATA_WIDTH-1:0] accumulator;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= {(DATA_WIDTH + DATA_WIDTH){1'b0}};
        result <= {(DATA_WIDTH + DATA_WIDTH){1'b0}};
        result_ready <= 1'b0;
        overflow <= 1'b0;
    end
    else begin
        if (partial_product_valid) begin
            // Shift the accumulator right by one position using a barrel shifter
            accumulator <= accumulator >> 1;
            {overflow, accumulator} <= accumulator + partial_product;
            result_ready <= 1'b0;
        end
        else begin
            result <= accumulator;
            result_ready <= 1'b1;
            overflow <= 1'b0;
        end
    end
end

endmodule
