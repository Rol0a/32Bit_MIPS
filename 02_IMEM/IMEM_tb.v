// =============================================================================
// IMEM_tb.v — Testbench de la Memoria de Instrucciones
// Recorre el programa de clase (direcciones 0 a 25), dos palabras sin programa
// (26 y 1023) y tres direcciones fuera de la memoria (1024, 1025 y 2048).
// Imprime la instrucción con sus campos separados según el formato (R, I o J)
// y la compara contra el valor esperado.
// =============================================================================
`timescale 1ns / 1ps

module IMEM_tb;

    // Entrada de la IMEM (reg: la maneja el testbench) y salida (wire)
    reg  [31:0] addr;
    wire [31:0] instruction;

    integer lecturas = 0;   // direcciones leídas
    integer errores  = 0;   // comparaciones fallidas

    // Campos de la instrucción. Se declaran como wire para verlos en GTKWave;
    // cada formato usa solo algunos de ellos.
    wire [5:0]  opcode    = instruction[31:26];
    wire [4:0]  rs        = instruction[25:21];
    wire [4:0]  rt        = instruction[20:16];
    wire [4:0]  rd        = instruction[15:11];
    wire [4:0]  shamt     = instruction[10:6];
    wire [5:0]  funct     = instruction[5:0];
    wire [15:0] immediate = instruction[15:0];
    wire [25:0] address   = instruction[25:0];

    // Unidad bajo prueba
    IMEM uut (
        .addr       (addr),
        .instruction(instruction)
    );

    // Lee una dirección, la compara con el valor esperado e imprime dos líneas:
    // la instrucción con sus campos separados por _ y los campos por nombre.
    // El formato se reconoce por el opcode: 000000 es R, 000010 es J y el
    // resto es I. Se usa !== para que una x también cuente como error.
    task leer;
        input [31:0]   a;
        input [31:0]   esperado;
        input [8*40:1] caso;
        begin
            addr = a;
            #10;   // la lectura es combinacional: basta con que se asiente
            lecturas = lecturas + 1;
            if (instruction !== esperado) errores = errores + 1;

            if (^instruction === 1'bx) begin
                // Palabra sin instrucción: no tiene campos que separar.
                $display("addr=%4d  -  Instr=%b       hex=%h  esperado=%h  %s  %0s",
                         addr, instruction, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
            end
            else if (opcode == 6'b000000) begin
                $display("addr=%4d  R  Instr=%b_%b_%b_%b_%b_%b  hex=%h  esperado=%h  %s  %0s",
                         addr, opcode, rs, rt, rd, shamt, funct, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
                $display("              opcode=%b rs=%b rt=%b rd=%b shamt=%b funct=%b",
                         opcode, rs, rt, rd, shamt, funct);
            end
            else if (opcode == 6'b000010) begin
                $display("addr=%4d  J  Instr=%b_%b      hex=%h  esperado=%h  %s  %0s",
                         addr, opcode, address, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
                $display("              opcode=%b address=%b (%0d)",
                         opcode, address, address);
            end
            else begin
                $display("addr=%4d  I  Instr=%b_%b_%b_%b    hex=%h  esperado=%h  %s  %0s",
                         addr, opcode, rs, rt, immediate, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
                $display("              opcode=%b rs=%b rt=%b immediate=%b (%0d)",
                         opcode, rs, rt, immediate, $signed(immediate));
            end
        end
    endtask

    initial begin
        $dumpfile("IMEM_tb.vcd");
        $dumpvars(0, IMEM_tb);

        $display("=== Testbench IMEM ===");

        // Programa de clase (direcciones 0 a 25: instrucción #n en n - 1). El
        // esperado se copia a mano de la tabla de instrucciones de clase.
        leer(32'd0,  32'b001010_00000_00001_0000000000001111,   "#1  MOVI $1, 15");
        leer(32'd1,  32'b001010_00000_00010_0000000000010100,   "#2  MOVI $2, 20");
        leer(32'd2,  32'b001010_00000_00011_0000000000110010,   "#3  MOVI $3, 50");
        leer(32'd3,  32'b001010_00000_00100_0000000000000101,   "#4  MOVI $4, 5");
        leer(32'd4,  32'b001010_00000_00101_0000000000000010,   "#5  MOVI $5, 2");
        leer(32'd5,  32'b000000_00001_00010_00110_00000_100000, "#6  ADD $6, $1, $2");
        leer(32'd6,  32'b000000_00011_00001_00111_00000_100010, "#7  SUB $7, $3, $1");
        leer(32'd7,  32'b000000_00010_00011_01000_00000_011000, "#8  MUL $8, $2, $3");
        leer(32'd8,  32'b000000_00011_00010_01001_00000_011010, "#9  DIV $9, $3, $2");
        leer(32'd9,  32'b001000_00001_00001_0000000000001010,   "#10 ADDI $1, $1, 10");
        leer(32'd10, 32'b001001_00010_00010_0000000000000100,   "#11 SUBI $2, $2, 4");
        leer(32'd11, 32'b000000_00110_00100_01010_00000_100000, "#12 ADD $10, $6, $4");
        leer(32'd12, 32'b000000_00110_00101_01011_00000_011000, "#13 MUL $11, $6, $5");
        leer(32'd13, 32'b000000_01010_00101_01100_00000_011010, "#14 DIV $12, $10, $5");
        leer(32'd14, 32'b001000_00100_00100_0000000000010100,   "#15 ADDI $4, $4, 20");
        leer(32'd15, 32'b000000_00100_00011_01101_00000_100010, "#16 SUB $13, $4, $3");
        leer(32'd16, 32'b001010_00000_01110_0000000001100100,   "#17 MOVI $14, 100");
        leer(32'd17, 32'b000000_01110_00001_01111_00000_100000, "#18 ADD $15, $14, $1");
        leer(32'd18, 32'b001001_00011_00011_0000000000000101,   "#19 SUBI $3, $3, 5");
        leer(32'd19, 32'b000000_01111_00010_10000_00000_011000, "#20 MUL $16, $15, $2");
        leer(32'd20, 32'b001000_00001_10001_0000000000000001,   "#21 ADDI $17, $1, 1");
        leer(32'd21, 32'b000010_00000000000000010000000000,     "#22 JUMP 1024");
        leer(32'd22, 32'b000000_10001_00010_10010_00000_100000, "#23 ADD $18, $17, $2");
        leer(32'd23, 32'b000000_10010_00101_10011_00000_100010, "#24 SUB $19, $18, $5");
        leer(32'd24, 32'b001010_00000_10100_0000000011111111,   "#25 MOVI $20, 255");
        leer(32'd25, 32'b001010_00000_00000_0000000011111111,   "#26 MOVI $0, 255");

        // Palabras 26 a 1023: dentro del arreglo pero sin programa. Se
        // inicializan en 0, así que leen la NOP y no x.
        leer(32'd26,   32'd0, "primera palabra sin programa: 0");
        leer(32'd1023, 32'd0, "ultima palabra del arreglo: 0");

        // Fuera del arreglo devuelve 0. La 1024 es el destino de JUMP 1024:
        // con solo addr[9:0] leería la palabra 0 (MOVI $1, 15) y el programa
        // volvería a empezar.
        leer(32'd1024, 32'd0, "1024 (JUMP 1024): fuera, lee 0");
        leer(32'd1025, 32'd0, "1025: fuera, lee 0");
        leer(32'd2048, 32'd0, "2048: addr[9:0] = 0, pero lee 0");

        if (errores == 0)
            $display("=== %0d lecturas, todas las pruebas OK ===", lecturas);
        else
            $display("=== %0d lecturas, %0d ERRORES ===", lecturas, errores);
        $finish;
    end

endmodule
