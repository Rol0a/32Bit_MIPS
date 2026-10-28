// =============================================================================
// IMEM.v — Memoria de Instrucciones
// Memoria de solo lectura de 16 palabras de 32 bits con el programa precargado.
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module IMEM (
    input  [31:0] addr,          // dirección de la instrucción (por palabra)
    output [31:0] instruction    // instrucción leída
);

    // 16 palabras de 32 bits: índices 0 a 15.
    reg [31:0] memory [0:15];

    // Lectura combinacional: la instrucción cambia en cuanto cambia addr, sin
    // esperar al reloj. Se indexa con los 5 bits bajos, como pide el
    // enunciado: las direcciones 16 a 31 quedan fuera del arreglo y leen x, y
    // la 32 vuelve a la 0 (addr[4:0] = 0).
    assign instruction = memory[addr[4:0]];

    // Programa precargado. Los campos van separados con _ según el formato:
    //   R: opcode_rs_rt_rd_shamt_funct
    //   I: opcode_rs_rt_immediate
    //   J: opcode_address
    // Los funct son los de la tabla de ALUControl y el inmediato se extiende
    // con signo. Los campos que una instrucción no usa van en 0. Las palabras
    // 10 a 15 no se inicializan: leen x.
    initial begin
        memory[0] = 32'b000000_00001_00010_00011_00000_100000; // R  add  $3, $1, $2  (enunciado)
        memory[1] = 32'b001000_01000_01001_0000000000001010;   // I  addi $9, $8, 10  (enunciado)
        memory[2] = 32'b001010_00000_00001_0000000000000111;   // I  movi $1, 7
        memory[3] = 32'b001010_00000_00010_1111111111111101;   // I  movi $2, -3
        memory[4] = 32'b000000_00001_00010_00100_00000_100100; // R  sub  $4, $1, $2
        memory[5] = 32'b000000_00001_00010_00101_00000_100001; // R  mul  $5, $1, $2
        memory[6] = 32'b000000_00101_00001_00110_00000_100010; // R  div  $6, $5, $1
        memory[7] = 32'b001001_01001_00111_0000000000001111;   // I  subi $7, $9, 15
        memory[8] = 32'b000000_00111_00000_01010_00000_100011; // R  mov  $10, $7
        memory[9] = 32'b000010_00000000000000000000001001;     // J  j    9  (salta a sí misma: fin)
    end

endmodule
