// 16x16-seq-mult
module sequential_multiplier (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [15:0] multiplicand,
    input wire [15:0] multiplier,
    output reg [31:0] product,
    output reg done
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINISH = 2'b10;

    // Internal registers
    reg [31:0] product_out_temp;
    reg [1:0] state, next_state;
    reg [15:0] mcand_reg;
    reg [15:0] mplier_reg;
    reg [31:0] product_temp;
    reg [4:0] count;  // Counter for 16 iterations

    // State machine and sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            mcand_reg <= 16'b0;
            mplier_reg <= 16'b0;
            product_temp <= 32'b0;
			product_out_temp <= 32'b0;
            product <= 32'b0;
            count <= 5'b0;
            done <= 1'b0;
        end
        else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        mcand_reg <= multiplicand;
                        mplier_reg <= multiplier;
                        product_temp <= 32'b0;
						product_out_temp <= 32'b0;
                        count <= 5'b0;
                        done <= 1'b0;
                    end
                end

                CALC: begin
                    if (mplier_reg[0]) begin  //if bit is 1
                        product_temp <= product_temp + (mcand_reg << count); //working
						// product_temp[31:16] <= product_temp[31:16] + mcand_reg;  //adding mcand_reg to higher MSB of product
					end
					
					// product_temp <= product_temp >> 1; //todo: all 0s
					mplier_reg <= mplier_reg >> 1;
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
                next_state = (count == 16) ? FINISH : CALC;
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
