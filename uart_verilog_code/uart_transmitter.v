module uart_transmitter #(
    parameter CLOCK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk,
    input  wire        rst,
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
    wire        baud_tick;
    reg [2:0]   state;
    reg [2:0]   bit_count;
    reg [7:0]   shift_reg;

    // Instantiate Baud Rate Generator
    tx_BRG #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) tx_BRG_dut (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );

    // UART Transmitter State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_pin <= 1'b1;  // Idle state is high
            tx_ready <= 1'b1;
            bit_count <= 3'b0;
            shift_reg <= 8'b0;
        end 
		else if (baud_tick) begin
		// else begin
            case (state)
                IDLE: begin
                    tx_pin <= 1'b1;  // Maintain high in idle
                    if (tx_valid) begin
                        state <= START;
                        shift_reg <= tx_data;
                        tx_ready <= 1'b0;
                        tx_pin <= 1'b0;  // Start bit is low
                    end
                end

                START: begin
                    state <= DATA;
                    bit_count <= 3'b0;
                    tx_pin <= shift_reg[0];  // Transmit LSB first
                end

                DATA: begin
                    shift_reg <= {1'b0, shift_reg[7:1]};  // Right shift
                    tx_pin <= shift_reg[0];
                    bit_count <= bit_count + 1'b1;

                    if (bit_count == 3'b111) begin  // 8 bits transmitted
                        state <= STOP;
                        tx_pin <= 1'b1;  // Stop bit is high
                    end
                end

                STOP: begin
                    tx_pin <= 1'b1;  // Stop bit
                    state <= IDLE;
                    tx_ready <= 1'b1;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule