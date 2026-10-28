// =============================================================================
// IMEM_tb.v — Testbench de la Memoria de Instrucciones
// Recorre las direcciones 0 a 16 y la 32, imprime la instrucción con sus campos
// separados según el formato (R, I o J) y la compara contra el valor esperado.
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
                $display("addr=%2d  -  Instr=%b       hex=%h  esperado=%h  %s  %0s",
                         addr, instruction, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
            end
            else if (opcode == 6'b000000) begin
                $display("addr=%2d  R  Instr=%b_%b_%b_%b_%b_%b  hex=%h  esperado=%h  %s  %0s",
                         addr, opcode, rs, rt, rd, shamt, funct, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
                $display("            opcode=%b rs=%b rt=%b rd=%b shamt=%b funct=%b",
                         opcode, rs, rt, rd, shamt, funct);
            end
            else if (opcode == 6'b000010) begin
                $display("addr=%2d  J  Instr=%b_%b      hex=%h  esperado=%h  %s  %0s",
                         addr, opcode, address, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
                $display("            opcode=%b address=%b (%0d)",
                         opcode, address, address);
            end
            else begin
                $display("addr=%2d  I  Instr=%b_%b_%b_%b    hex=%h  esperado=%h  %s  %0s",
                         addr, opcode, rs, rt, immediate, instruction, esperado,
                         (instruction === esperado) ? "OK   " : "ERROR", caso);
                $display("            opcode=%b rs=%b rt=%b immediate=%b (%0d)",
                         opcode, rs, rt, immediate, $signed(immediate));
            end
        end
    endtask

    initial begin
        $dumpfile("IMEM_tb.vcd");
        $dumpvars(0, IMEM_tb);

        $display("=== Testbench IMEM ===");

        // Programa precargado (direcciones 0 a 9). El esperado se escribe a
        // mano con los campos separados, igual que en la tabla del README.
        leer(32'd0, 32'b000000_00001_00010_00011_00000_100000, "add  $3, $1, $2");
        leer(32'd1, 32'b001000_01000_01001_0000000000001010,   "addi $9, $8, 10");
        leer(32'd2, 32'b001010_00000_00001_0000000000000111,   "movi $1, 7");
        leer(32'd3, 32'b001010_00000_00010_1111111111111101,   "movi $2, -3");
        leer(32'd4, 32'b000000_00001_00010_00100_00000_100100, "sub  $4, $1, $2");
        leer(32'd5, 32'b000000_00001_00010_00101_00000_100001, "mul  $5, $1, $2");
        leer(32'd6, 32'b000000_00101_00001_00110_00000_100010, "div  $6, $5, $1");
        leer(32'd7, 32'b001001_01001_00111_0000000000001111,   "subi $7, $9, 15");
        leer(32'd8, 32'b000000_00111_00000_01010_00000_100011, "mov  $10, $7");
        leer(32'd9, 32'b000010_00000000000000000000001001,     "j    9");

        // Palabras 10 a 15: dentro del arreglo pero nunca escritas, leen x.
        leer(32'd10, 32'bx, "palabra sin instruccion");
        leer(32'd11, 32'bx, "palabra sin instruccion");
        leer(32'd12, 32'bx, "palabra sin instruccion");
        leer(32'd13, 32'bx, "palabra sin instruccion");
        leer(32'd14, 32'bx, "palabra sin instruccion");
        leer(32'd15, 32'bx, "ultima palabra del arreglo");

        // Dirección 16: addr[4:0] = 16 queda fuera de memory[0:15] y lee x.
        leer(32'd16, 32'bx, "fuera del arreglo");

        // Caso adicional: con 5 bits, la dirección 32 se ve como 0 y lee la
        // primera instrucción.
        leer(32'd32, 32'b000000_00001_00010_00011_00000_100000, "32: addr[4:0] = 0, lee la 0");

        if (errores == 0)
            $display("=== %0d lecturas, todas las pruebas OK ===", lecturas);
        else
            $display("=== %0d lecturas, %0d ERRORES ===", lecturas, errores);
        $finish;
    end

endmodule
