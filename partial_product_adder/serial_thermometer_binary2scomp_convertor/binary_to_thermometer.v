
module binary_to_thermometer #(
    parameter INPUT_WIDTH = 3
)(
    input wire [INPUT_WIDTH:0] binary_in,
    output reg [(2**INPUT_WIDTH-1) - 1 :0] thermometer_out
);

    localparam THERMOMETER_WIDTH = 2**INPUT_WIDTH - 1;
    integer i;

    always @(*) begin
        thermometer_out = {THERMOMETER_WIDTH{1'b0}};
        for (i = 0; i < binary_in; i = i + 1) begin
            // thermometer_out[i] = 1'b1; //set lsb first
			thermometer_out[THERMOMETER_WIDTH-1-i] = 1'b1; //set msb first
        end
    end

endmodule

