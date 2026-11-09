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
    // Cada caso pone la dirección e imprime 10 ns después, con la lectura combinacional ya asentada.
    // === compara también la x.
    reg [31:0] programa [0:25];
    integer    i;

    initial begin
        $dumpfile("IMEM_tb.vcd");
        $dumpvars(0, IMEM_tb);

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
        programa[21] = 32'b000010_00000000000000010000000000;       // #22 JUMP 1024
        programa[22] = 32'b000000_10001_00010_10010_00000_100000;   // #23 ADD $18, $17, $2
        programa[23] = 32'b000000_10010_00101_10011_00000_100010;   // #24 SUB $19, $18, $5
        programa[24] = 32'b001010_00000_10100_0000000011111111;     // #25 MOVI $20, 255
        programa[25] = 32'b001010_00000_00000_0000000011111111;     // #26 MOVI $0, 255

        // Las 26 instrucciones: dos líneas por lectura, la instrucción y sus campos por nombre
        for (i = 0; i < 26; i = i + 1) begin
            addr = i;
            #10 $display("addr=%4d  Instr=%b  hex=%h  %0s\n           opcode=%b rs=%b rt=%b rd=%b shamt=%b funct=%b immediate=%0d address=%0d",
                         addr, instruction, instruction, instruction === programa[i] ? "OK" : "ERROR",
                         opcode, rs, rt, rd, shamt, funct, $signed(immediate), address);
        end

        // Palabras sin programa (26, 1023) y direcciones fuera de la memoria (1024, el destino de JUMP 1024;
        // 1025; 2048, que tiene addr[9:0] = 0): todas leen 0
        addr = 26;    #10 $display("addr=%4d  Instr=%b  hex=%h  %0s", addr, instruction, instruction, instruction === 0 ? "OK" : "ERROR");
        addr = 1023;  #10 $display("addr=%4d  Instr=%b  hex=%h  %0s", addr, instruction, instruction, instruction === 0 ? "OK" : "ERROR");
        addr = 1024;  #10 $display("addr=%4d  Instr=%b  hex=%h  %0s", addr, instruction, instruction, instruction === 0 ? "OK" : "ERROR");
        addr = 1025;  #10 $display("addr=%4d  Instr=%b  hex=%h  %0s", addr, instruction, instruction, instruction === 0 ? "OK" : "ERROR");
        addr = 2048;  #10 $display("addr=%4d  Instr=%b  hex=%h  %0s", addr, instruction, instruction, instruction === 0 ? "OK" : "ERROR");

        $finish;
    end

endmodule
