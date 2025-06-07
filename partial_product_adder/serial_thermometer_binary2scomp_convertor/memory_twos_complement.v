
module memory_twos_complement (
    input [4:0] addr,
    output reg [4:0] data_out
);

    // Memory array to store 5-bit 2's complement values
    reg [4:0] mem [0:31];
    
    // Initialize memory with hardcoded 2's complement values
    initial begin
        // Explicitly initialize each memory location
        mem[0] = 5'h00;  // 2's complement of 0
        mem[1] = 5'h1F;  // 2's complement of 1
        mem[2] = 5'h1E;  // 2's complement of 2
        mem[3] = 5'h1D;  // 2's complement of 3
        mem[4] = 5'h1C;  // 2's complement of 4
        mem[5] = 5'h1B;  // 2's complement of 5
        mem[6] = 5'h1A;  // 2's complement of 6
        mem[7] = 5'h19;  // 2's complement of 7
        mem[8] = 5'h18;  // 2's complement of 8
        mem[9] = 5'h17;  // 2's complement of 9
        mem[10] = 5'h16; // 2's complement of 10
        mem[11] = 5'h15; // 2's complement of 11
        mem[12] = 5'h14; // 2's complement of 12
        mem[13] = 5'h13; // 2's complement of 13
        mem[14] = 5'h12; // 2's complement of 14
        mem[15] = 5'h11; // 2's complement of 15
        mem[16] = 5'h10; // 2's complement of 16
        mem[17] = 5'h0F; // 2's complement of 17
        mem[18] = 5'h0E; // 2's complement of 18
        mem[19] = 5'h0D; // 2's complement of 19
        mem[20] = 5'h0C; // 2's complement of 20
        mem[21] = 5'h0B; // 2's complement of 21
        mem[22] = 5'h0A; // 2's complement of 22
        mem[23] = 5'h09; // 2's complement of 23
        mem[24] = 5'h08; // 2's complement of 24
        mem[25] = 5'h07; // 2's complement of 25
        mem[26] = 5'h06; // 2's complement of 26
        mem[27] = 5'h05; // 2's complement of 27
        mem[28] = 5'h04; // 2's complement of 28
        mem[29] = 5'h03; // 2's complement of 29
        mem[30] = 5'h02; // 2's complement of 30
        mem[31] = 5'h01; // 2's complement of 31
    end
    
    // Read operation
    always @(*) begin
        data_out = mem[addr];
    end

endmodule
