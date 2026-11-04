// IMEM_tb.v — Testbench de la memoria de instrucciones. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module IMEM_tb;

    // ---- Módulo bajo prueba ----
    reg  [31:0] addr;
    wire [31:0] instruction;

    IMEM uut (.addr(addr), .instruction(instruction));

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
    initial begin
        $dumpfile("IMEM_tb.vcd");
        $dumpvars(0, IMEM_tb);

        // Programa de clase: esperado copiado a mano de la tabla de instrucciones
        leer(0,  32'b001010_00000_00001_0000000000001111,   "#1  MOVI $1, 15");
        leer(1,  32'b001010_00000_00010_0000000000010100,   "#2  MOVI $2, 20");
        leer(2,  32'b001010_00000_00011_0000000000110010,   "#3  MOVI $3, 50");
        leer(3,  32'b001010_00000_00100_0000000000000101,   "#4  MOVI $4, 5");
        leer(4,  32'b001010_00000_00101_0000000000000010,   "#5  MOVI $5, 2");
        leer(5,  32'b000000_00001_00010_00110_00000_100000, "#6  ADD $6, $1, $2");
        leer(6,  32'b000000_00011_00001_00111_00000_100010, "#7  SUB $7, $3, $1");
        leer(7,  32'b000000_00010_00011_01000_00000_011000, "#8  MUL $8, $2, $3");
        leer(8,  32'b000000_00011_00010_01001_00000_011010, "#9  DIV $9, $3, $2");
        leer(9,  32'b001000_00001_00001_0000000000001010,   "#10 ADDI $1, $1, 10");
        leer(10, 32'b001001_00010_00010_0000000000000100,   "#11 SUBI $2, $2, 4");
        leer(11, 32'b000000_00110_00100_01010_00000_100000, "#12 ADD $10, $6, $4");
        leer(12, 32'b000000_00110_00101_01011_00000_011000, "#13 MUL $11, $6, $5");
        leer(13, 32'b000000_01010_00101_01100_00000_011010, "#14 DIV $12, $10, $5");
        leer(14, 32'b001000_00100_00100_0000000000010100,   "#15 ADDI $4, $4, 20");
        leer(15, 32'b000000_00100_00011_01101_00000_100010, "#16 SUB $13, $4, $3");
        leer(16, 32'b001010_00000_01110_0000000001100100,   "#17 MOVI $14, 100");
        leer(17, 32'b000000_01110_00001_01111_00000_100000, "#18 ADD $15, $14, $1");
        leer(18, 32'b001001_00011_00011_0000000000000101,   "#19 SUBI $3, $3, 5");
        leer(19, 32'b000000_01111_00010_10000_00000_011000, "#20 MUL $16, $15, $2");
        leer(20, 32'b001000_00001_10001_0000000000000001,   "#21 ADDI $17, $1, 1");
        leer(21, 32'b000010_00000000000000010000000000,     "#22 JUMP 1024");
        leer(22, 32'b000000_10001_00010_10010_00000_100000, "#23 ADD $18, $17, $2");
        leer(23, 32'b000000_10010_00101_10011_00000_100010, "#24 SUB $19, $18, $5");
        leer(24, 32'b001010_00000_10100_0000000011111111,   "#25 MOVI $20, 255");
        leer(25, 32'b001010_00000_00000_0000000011111111,   "#26 MOVI $0, 255");

        // Palabras sin programa y direcciones fuera de la memoria
        leer(26,   0, "primera palabra sin programa: 0");
        leer(1023, 0, "ultima palabra del arreglo: 0");
        leer(1024, 0, "1024 (JUMP 1024): fuera, lee 0");
        leer(1025, 0, "1025: fuera, lee 0");
        leer(2048, 0, "2048: addr[9:0] = 0, pero lee 0");

        $finish;
    end

    // ---- Impresión de resultados ----

    // Dos líneas por lectura: la instrucción y sus campos por nombre. === compara también la x.
    task leer(input [31:0] a, esperado, input [8*40:1] caso);
        begin
            addr = a;
            #10 $display("addr=%4d  Instr=%b  hex=%h  esperado=%h  %s  %0s\n", addr, instruction, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso,
                         "           opcode=%b rs=%b rt=%b rd=%b shamt=%b funct=%b immediate=%0d address=%0d",
                         opcode, rs, rt, rd, shamt, funct, $signed(immediate), address);
        end
    endtask

endmodule
