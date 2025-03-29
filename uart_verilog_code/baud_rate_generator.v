module baud_rate_generator #(
    parameter CLOCK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst,
    output reg         tx_baud_tick,
    output reg         rx_baud_tick	
);

	//derived params
	localparam BAUD_RATE_16x = 16 * BAUD_RATE; //rx baud ticks = 16x baud rate //1843200 for 115200
    localparam RX_BRG_COUNTER_MAX = $rtoi((CLOCK_FREQ / BAUD_RATE_16x) - 1); //26 for 115200 for rx

	//1st method to calc TX_BRG_COUNTER_MAX  //little off-sync with local rx tick
    // localparam TX_BRG_COUNTER_MAX = $rtoi((CLOCK_FREQ / BAUD_RATE) - 1); //433 for 115200 for tx
	//2nd method to calc TX_BRG_COUNTER_MAX  //perfect synchronous with local rx tick
	localparam TX_BRG_COUNTER_MAX =  $rtoi((16 * (RX_BRG_COUNTER_MAX + 1)) - 1); //431 for 115200 for tx 
	
    reg [15:0] tx_tick_counter;  //to count tx baud ticks
    reg [15:0] rx_tick_counter;  //to count rx baud ticks

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_tick_counter <= 0;
            tx_baud_tick <= 1'b0;
			
            rx_tick_counter <= 0;
            rx_baud_tick <= 1'b0;		
        end else begin
		
            if (tx_tick_counter == TX_BRG_COUNTER_MAX) begin
                tx_tick_counter <= 0;
                tx_baud_tick <= 1'b1;
            end
			else begin 
                tx_tick_counter <= tx_tick_counter + 1;
                tx_baud_tick <= 1'b0;			
			end 
			
            if (rx_tick_counter == RX_BRG_COUNTER_MAX) begin
                rx_tick_counter <= 0;
                rx_baud_tick <= 1'b1;
            end
			else begin						
                rx_tick_counter <= rx_tick_counter + 1;
                rx_baud_tick <= 1'b0;
            end
        end
    end

endmodule

