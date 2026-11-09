// PC_IMEM_tb.v — Testbench de integración PC + IMEM (usa ../01_PC/PC.v y ../02_IMEM/IMEM.v).
// Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module PC_IMEM_tb;

    // ---- Módulos bajo prueba ----
    reg         clk   = 0;
    reg         reset = 1;
    wire [31:0] current_pc, instruction;
    wire [31:0] next_pc = current_pc + 32'd1;   // el PC avanza una palabra por ciclo

    PC   uut_pc   (.clk(clk), .reset(reset), .next_pc(next_pc), .current_pc(current_pc));
    IMEM uut_imem (.addr(current_pc), .instruction(instruction));

    always #5 clk = ~clk;   // periodo de 10 ns: flancos de subida en t = 5, 15, 25, ...

    // Campos de la instrucción, para verlos en GTKWave
    wire [5:0]  opcode    = instruction[31:26];
    wire [4:0]  rs        = instruction[25:21];
    wire [4:0]  rt        = instruction[20:16];
    wire [4:0]  rd        = instruction[15:11];
    wire [4:0]  shamt     = instruction[10:6];
    wire [5:0]  funct     = instruction[5:0];
    wire [15:0] immediate = instruction[15:0];
    wire [25:0] address   = instruction[25:0];

    // ---- Casos de prueba ----
    reg [31:0] programa [0:26];
    integer    i;

    initial begin
        $dumpfile("PC_IMEM_tb.vcd");
        $dumpvars(0, PC_IMEM_tb);

        // Esperado: el programa de clase, copiado a mano de la tabla de instrucciones
        programa[0]  = 32'b001010_00000_00001_0000000000001111;     // #1  MOVI $1, 15
        programa[1]  = 32'b001010_00000_00010_0000000000010100;     // #2  MOVI $2, 20
        programa[2]  = 32'b001010_00000_00011_0000000000110010;     // #3  MOVI $3, 50
        programa[3]  = 32'b001010_00000_00100_0000000000000101;     // #4  MOVI $4, 5
        programa[4]  = 32'b001010_00000_00101_0000000000000010;     // #5  MOVI $5, 2
        programa[5]  = 32'b000000_00001_00010_00110_00000_100000;   // #6  ADD $6, $1, $2
        programa[6]  = 32'b000000_00011_00001_00111_00000_100010;   // #7  SUB $7, $3, $1
        programa[7]  = 32'b000000_00010_00011_01000_00000_011000;   // #8  MUL $8, $2, $3
        programa[8]  = 32'b000000_00011_00010_01001_00000_011010;   // #9  DIV $9, $3, $2
        programa[9]  = 32'b001000_00001_00001_0000000000001010;     // #10 ADDI $1, $1, 10
        programa[10] = 32'b001001_00010_00010_0000000000000100;     // #11 SUBI $2, $2, 4
        programa[11] = 32'b000000_00110_00100_01010_00000_100000;   // #12 ADD $10, $6, $4
        programa[12] = 32'b000000_00110_00101_01011_00000_011000;   // #13 MUL $11, $6, $5
        programa[13] = 32'b000000_01010_00101_01100_00000_011010;   // #14 DIV $12, $10, $5
        programa[14] = 32'b001000_00100_00100_0000000000010100;     // #15 ADDI $4, $4, 20
        programa[15] = 32'b000000_00100_00011_01101_00000_100010;   // #16 SUB $13, $4, $3
        programa[16] = 32'b001010_00000_01110_0000000001100100;     // #17 MOVI $14, 100
        programa[17] = 32'b000000_01110_00001_01111_00000_100000;   // #18 ADD $15, $14, $1
        programa[18] = 32'b001001_00011_00011_0000000000000101;     // #19 SUBI $3, $3, 5
        programa[19] = 32'b000000_01111_00010_10000_00000_011000;   // #20 MUL $16, $15, $2
        programa[20] = 32'b001000_00001_10001_0000000000000001;     // #21 ADDI $17, $1, 1
        programa[21] = 32'b000010_00000000000000010000000000;       // #22 JUMP 1024 (aquí no salta)
        programa[22] = 32'b000000_10001_00010_10010_00000_100000;   // #23 ADD $18, $17, $2
        programa[23] = 32'b000000_10010_00101_10011_00000_100010;   // #24 SUB $19, $18, $5
        programa[24] = 32'b001010_00000_10100_0000000011111111;     // #25 MOVI $20, 255
        programa[25] = 32'b001010_00000_00000_0000000011111111;     // #26 MOVI $0, 255
        programa[26] = 0;                                           // sin programa: lee 0

        // Se suelta reset justo después del primer flanco: el PC se queda en 0 un ciclo completo
        @(posedge clk);
        #1 reset = 0;

        // Sin Unidad de Control el PC siempre hace + 1: JUMP 1024 no salta y se leen las 26 palabras y una vacía.
        // En el flanco de bajada el PC y la IMEM ya están estables. Dos líneas por ciclo, como pide la
        // plantilla: la instrucción y sus campos por nombre. === compara también la x.
        for (i = 0; i < 27; i = i + 1)
            @(negedge clk) $display("PC=%2d, Instr=%b  %0s\n       opcode=%b rs=%b rt=%b rd=%b shamt=%b funct=%b immediate=%0d address=%0d",
                                    current_pc, instruction, (current_pc === i && instruction === programa[i]) ? "OK" : "ERROR",
                                    opcode, rs, rt, rd, shamt, funct, $signed(immediate), address);

        #4 $finish;   // antes del siguiente flanco de subida
    end

endmodule
