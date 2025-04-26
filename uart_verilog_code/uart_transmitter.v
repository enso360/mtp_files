module uart_transmitter #(
	parameter DATA_BITS = 8    // Number of data bits
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        tx_baud_tick,
    input  wire [7:0]  tx_data,
    input  wire        tx_valid,
    output reg         tx_ready,
    output reg         tx_pin
);
    // State machine states
    localparam IDLE     = 3'b000;
    localparam START    = 3'b001;
    localparam DATA     = 3'b010;
    localparam STOP     = 3'b011;

    // Internal signals
    reg [2:0]   state;
    reg [2:0]   bit_count;
    reg [7:0]   shift_reg;

    // UART Transmitter State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_pin <= 1'b1;  // Idle state is high
            tx_ready <= 1'b1;
            bit_count <= 3'b0;
            shift_reg <= 8'b0;
        end 
        else if (tx_baud_tick) begin
            case (state)
                IDLE: begin
                    tx_pin <= 1'b1;  // Maintain high in idle
                    if (tx_valid) begin
                        state <= START;
                        shift_reg <= tx_data;  //PISO
                        tx_ready <= 1'b0;
                        tx_pin <= 1'b0;  // Start bit is low
                    end
                end

                START: begin
                    state <= DATA;
                    bit_count <= 3'b0;
                    tx_pin <= shift_reg[0];  // Transmit/copy LSB first (in next state)
                    shift_reg <= {1'b0, shift_reg[7:1]};  // Right shift (in next state)
                end

                DATA: begin
                    shift_reg <= {1'b0, shift_reg[7:1]};  // Right shift (in next state)
                    tx_pin <= shift_reg[0]; //(in next state)
                    bit_count <= bit_count + 1'b1;

                    if (bit_count == 3'b111) begin  // 8 bits transmitted
                        state <= STOP;
                        tx_pin <= 1'b1;  // Stop bit is high
                    end
                end

                STOP: begin
                    tx_pin <= 1'b1;  // Hold line high when IDLE
                    state <= IDLE;
                    tx_ready <= 1'b1;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
