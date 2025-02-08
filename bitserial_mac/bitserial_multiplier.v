// bit serial mult

module sequential_multiplier #(
    parameter MULTIPLICAND_WIDTH = 16,
    parameter MULTIPLIER_WIDTH = 16
) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [MULTIPLICAND_WIDTH-1:0] multiplicand,
    input wire [MULTIPLIER_WIDTH-1:0] multiplier,
	input wire multiplier_serial_bit_in,  //serial input bit
    output reg [(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] product,
    output reg done
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINISH = 2'b10;

    // Internal registers
    reg [(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] product_out_temp;
    reg [1:0] state, next_state;
    reg [MULTIPLICAND_WIDTH-1:0] mcand_reg;
    reg [MULTIPLIER_WIDTH-1:0] mplier_reg;
    reg [(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] product_temp;
    reg [$clog2(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH)-1:0] count;  // Counter for iterations
	reg multiplier_serial_bit_reg;

    // State machine and sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            mcand_reg <= {MULTIPLICAND_WIDTH{1'b0}};
            mplier_reg <= {MULTIPLIER_WIDTH{1'b0}};
            product_temp <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
            product_out_temp <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
            product <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
            count <= {$clog2(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
            done <= 1'b0;
            multiplier_serial_bit_reg <= 1'b0;			
        end
        else begin
            state <= next_state;
            multiplier_serial_bit_reg <= multiplier_serial_bit_in;			
            
            case (state)
                IDLE: begin
                    if (start) begin
                        mcand_reg <= multiplicand;
                        mplier_reg <= multiplier;
						// multiplier_serial_bit_reg <= multiplier_serial_bit_in;
                        product_temp <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
                        product_out_temp <= {(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
                        count <= {$clog2(MULTIPLICAND_WIDTH+MULTIPLIER_WIDTH){1'b0}};
                        done <= 1'b0;
                    end
                end

                CALC: begin
                    // if (mplier_reg[0]) begin  //if bit is 1
					if (multiplier_serial_bit_reg) begin  //if bit is 1
                        product_temp <= product_temp + (mcand_reg << count); //working
						// product_temp[31:16] <= product_temp[31:16] + mcand_reg;  //adding mcand_reg to higher MSB of product						
                    end
                    
					// product_temp <= product_temp >> 1; //todo: all 0s
                    // mplier_reg <= mplier_reg >> 1;
                    count <= count + 1;
                end

                FINISH: begin
                    product_out_temp <= product_temp;
                    product <= product_temp;
                    done <= 1'b1;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = start ? CALC : IDLE;
            end
            
            CALC: begin
                next_state = (count == (MULTIPLICAND_WIDTH - 1)) ? FINISH : CALC;
                // next_state = (count == (MULTIPLICAND_WIDTH)) ? FINISH : CALC;				
            end
            
            FINISH: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
