module memory_twos_complement (
    input [4:0] addr,
    output reg [4:0] data_out
);

    // Memory array to store 5-bit 2's complement values
    reg [4:0] mem [0:31];
    
    // Using a 5-bit integer to match data_out width
    reg [4:0] i;
    
    // Initialize memory with 2's complement values calculated on-the-fly
    initial begin
        // First explicitly initialize all memory locations to prevent X
        for (i = 5'b00000; i < 5'b11111 + 1'b1; i = i + 1'b1) begin
            mem[i] = 5'b00000;
        end
        
        // Then calculate and store 2's complement values
        for (i = 5'b00000; i < 5'b11111 + 1'b1; i = i + 1'b1) begin
            // 2's complement calculation: invert all bits and add 1
            if (i == 5'b00000)
                mem[i] = 5'b00000;  // Special case: 2's complement of 0 is 0
            else
                mem[i] = (~i + 1'b1);  // Calculate 2's complement
        end
        
        // Force an initial read to ensure data_out is updated
        data_out = mem[5'b00000];
    end
    
    // Read operation
    always @(*) begin
        data_out = mem[addr];
    end

endmodule
