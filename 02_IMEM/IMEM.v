// =============================================================================
// IMEM.v — Memoria de Instrucciones
// Memoria de solo lectura de 1024 palabras de 32 bits con el programa de clase
// (26 instrucciones) precargado.
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module IMEM (
    input  [31:0] addr,          // dirección de la instrucción (por palabra)
    output [31:0] instruction    // instrucción leída
);

    // 1024 palabras de 32 bits: índices 0 a 1023 (10 bits de dirección).
    reg [31:0] memory [0:1023];
    integer i;

    // Lectura combinacional: la instrucción cambia en cuanto cambia addr, sin
    // esperar al reloj. Solo existen las direcciones 0 a 1023. Fuera de ese
    // rango (por ejemplo, después de JUMP 1024) la memoria devuelve 0. Sin esa
    // comprobación, addr[9:0] de 1024 sería 0 y el programa volvería a
    // empezar. La palabra 0 es una NOP: tipo R con funct 000000 (ALUControl
    // da 1111, la ALU da 0) y destino $0, que el banco nunca escribe.
    assign instruction = (addr < 32'd1024) ? memory[addr[9:0]] : 32'd0;

    // Programa de clase. Los campos van separados con _ según el formato:
    //   R: opcode_rs_rt_rd_shamt_funct
    //   I: opcode_rs_rt_immediate
    //   J: opcode_address
    // Las palabras 26 a 1023 se ponen en 0 antes de cargar el programa: sin
    // programa también leen la NOP, no x.
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'd0;

        memory[0]  = 32'b001010_00000_00001_0000000000001111;   //  1  I  MOVI $1, 15
        memory[1]  = 32'b001010_00000_00010_0000000000010100;   //  2  I  MOVI $2, 20
        memory[2]  = 32'b001010_00000_00011_0000000000110010;   //  3  I  MOVI $3, 50
        memory[3]  = 32'b001010_00000_00100_0000000000000101;   //  4  I  MOVI $4, 5
        memory[4]  = 32'b001010_00000_00101_0000000000000010;   //  5  I  MOVI $5, 2
        memory[5]  = 32'b000000_00001_00010_00110_00000_100000; //  6  R  ADD  $6, $1, $2
        memory[6]  = 32'b000000_00011_00001_00111_00000_100010; //  7  R  SUB  $7, $3, $1
        memory[7]  = 32'b000000_00010_00011_01000_00000_011000; //  8  R  MUL  $8, $2, $3
        memory[8]  = 32'b000000_00011_00010_01001_00000_011010; //  9  R  DIV  $9, $3, $2
        memory[9]  = 32'b001000_00001_00001_0000000000001010;   // 10  I  ADDI $1, $1, 10
        memory[10] = 32'b001001_00010_00010_0000000000000100;   // 11  I  SUBI $2, $2, 4
        memory[11] = 32'b000000_00110_00100_01010_00000_100000; // 12  R  ADD  $10, $6, $4
        memory[12] = 32'b000000_00110_00101_01011_00000_011000; // 13  R  MUL  $11, $6, $5
        memory[13] = 32'b000000_01010_00101_01100_00000_011010; // 14  R  DIV  $12, $10, $5
        memory[14] = 32'b001000_00100_00100_0000000000010100;   // 15  I  ADDI $4, $4, 20
        memory[15] = 32'b000000_00100_00011_01101_00000_100010; // 16  R  SUB  $13, $4, $3
        memory[16] = 32'b001010_00000_01110_0000000001100100;   // 17  I  MOVI $14, 100
        memory[17] = 32'b000000_01110_00001_01111_00000_100000; // 18  R  ADD  $15, $14, $1
        memory[18] = 32'b001001_00011_00011_0000000000000101;   // 19  I  SUBI $3, $3, 5
        memory[19] = 32'b000000_01111_00010_10000_00000_011000; // 20  R  MUL  $16, $15, $2
        memory[20] = 32'b001000_00001_10001_0000000000000001;   // 21  I  ADDI $17, $1, 1
        memory[21] = 32'b000010_00000000000000010000000000;     // 22  J  JUMP 1024 (sale de la IMEM)
        memory[22] = 32'b000000_10001_00010_10010_00000_100000; // 23  R  ADD  $18, $17, $2 (no se ejecuta)
        memory[23] = 32'b000000_10010_00101_10011_00000_100010; // 24  R  SUB  $19, $18, $5 (no se ejecuta)
        memory[24] = 32'b001010_00000_10100_0000000011111111;   // 25  I  MOVI $20, 255    (no se ejecuta)
        memory[25] = 32'b001010_00000_00000_0000000011111111;   // 26  I  MOVI $0, 255     (no se ejecuta)
    end

endmodule
