module tx_BRG #(
    parameter CLOCK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk,
    input  wire        rst,
    output reg         baud_tick
);

    localparam COUNTER_MAX = CLOCK_FREQ / BAUD_RATE - 1;

    reg [15:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            baud_tick <= 1'b0;
        end else begin
            if (counter == COUNTER_MAX) begin
                counter <= 0;
                baud_tick <= 1'b1;
            end else begin
                counter <= counter + 1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule
