// Seq MAC

module sequential_mac #(
    parameter MULTIPLICAND_WIDTH = 16,
    parameter MULTIPLIER_WIDTH = 16
) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire clear_acc,  // To clear accumulator
    input wire [MULTIPLICAND_WIDTH-1:0] multiplicand,
    input wire [MULTIPLIER_WIDTH-1:0] multiplier,
    input wire multiplier_serial_bit_in,
	output wire [(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] mult_result,  //mult o/p 
    output reg [(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] mac_result,    //mac o/p 
    output wire done
);

    // Internal signals for multiplier interface
    // wire [(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] mult_result;
    reg mult_start;

    // Accumulator register
    reg [(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] accumulator;

    // State definitions
    localparam IDLE = 2'b00;
    localparam MULTIPLY = 2'b01;
    localparam ACCUMULATE = 2'b10;
    
    reg [1:0] state, next_state;

    // Instantiate the sequential multiplier
    bitserial_multiplier #(
        .MULTIPLICAND_WIDTH(MULTIPLICAND_WIDTH),
        .MULTIPLIER_WIDTH(MULTIPLIER_WIDTH)
    ) mult_inst (
        .clk(clk),
        .rst(rst),
        .start(mult_start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .multiplier_serial_bit_in(multiplier_serial_bit_in),
        .product(mult_result),
        .done(done)
    );

    // State machine sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            accumulator <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
            mac_result <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
            mult_start <= 1'b0;
        end
        else begin
            state <= next_state;

            // Clear accumulator logic
            if (clear_acc) begin
                accumulator <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
                mac_result <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
            end
            
            case (state)
                IDLE: begin
                    if (start) begin
                        mult_start <= 1'b1;
                    end
                    else begin
                        mult_start <= 1'b0;
                    end
                end

                MULTIPLY: begin
                    mult_start <= 1'b0;  // Clear start signal after multiplication begins
                end

                ACCUMULATE: begin
                    accumulator <= accumulator + mult_result;
                    mac_result <= accumulator + mult_result;
                end

                default: begin
                    mult_start <= 1'b0;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = MULTIPLY;
                else
                    next_state = IDLE;
            end
            
            MULTIPLY: begin
                if (done)
                    next_state = ACCUMULATE;
                else
                    next_state = MULTIPLY;
            end
            
            ACCUMULATE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
