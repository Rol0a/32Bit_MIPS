// =============================================================================
// ControlUnit_tb.v — Testbench de la Unidad de Control
// Cambia el opcode cada 10 ns, imprime una línea por opcode con las cinco
// señales y las compara contra el valor esperado, calculado a mano.
// =============================================================================
`timescale 1ns / 1ps

module ControlUnit_tb;

    // Entrada de la Unidad de Control (reg: la maneja el testbench) y salidas
    reg  [5:0] opcode;
    wire       RegDst;
    wire       ALUSrc;
    wire       RegWrite;
    wire       Jump;
    wire [1:0] ALUOp;

    integer pruebas = 0;   // opcodes probados
    integer errores = 0;   // comparaciones fallidas

    // Unidad bajo prueba
    ControlUnit uut (
        .opcode  (opcode),
        .RegDst  (RegDst),
        .ALUSrc  (ALUSrc),
        .RegWrite(RegWrite),
        .Jump    (Jump),
        .ALUOp   (ALUOp)
    );

    // Aplica un opcode, espera a que las salidas se asienten y las compara con
    // el esperado. El esperado agrupa las señales en el orden de la plantilla,
    // {RegDst, ALUSrc, RegWrite, Jump, ALUOp}: por ejemplo 6'b1_0_1_0_10 para
    // tipo R. Se usa !== para que una x también cuente como error.
    task probar;
        input [5:0]    op;
        input [5:0]    esperado;
        input [8*40:1] caso;
        begin
            opcode = op;
            #10;   // el módulo es combinacional: no hace falta reloj
            pruebas = pruebas + 1;
            if ({RegDst, ALUSrc, RegWrite, Jump, ALUOp} !== esperado)
                errores = errores + 1;

            $display("%2d  opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | esperado=%b %b %b %b %b  %s  %0s",
                     pruebas, opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp,
                     esperado[5], esperado[4], esperado[3], esperado[2], esperado[1:0],
                     ({RegDst, ALUSrc, RegWrite, Jump, ALUOp} === esperado) ? "OK   " : "ERROR",
                     caso);
        end
    endtask

    initial begin
        $dumpfile("ControlUnit_tb.vcd");
        $dumpvars(0, ControlUnit_tb);

        $display("=== Testbench ControlUnit ===");

        // Casos 1 a 4: un opcode de cada tipo de la ISA.
        probar(6'b000000, 6'b1_0_1_0_10, "Caso 1: tipo R");
        probar(6'b001010, 6'b0_1_1_0_00, "Caso 2: tipo I, MOVI");
        probar(6'b001000, 6'b0_1_1_0_01, "Caso 3: tipo I, ADDI");
        probar(6'b001001, 6'b0_1_1_0_11, "Caso 3: tipo I, SUBI");
        probar(6'b000010, 6'b0_0_0_1_00, "Caso 4: tipo J");

        // Caso 5: opcode no definido. Debe quedar «seguro»: sin escribir
        // registros (RegWrite = 0) ni saltar (Jump = 0).
        probar(6'b111111, 6'b0_0_0_0_00, "Caso 5: opcode no definido");

        // Adicionales: opcodes a un bit de distancia de uno definido. El case
        // compara los 6 bits, así que no deben confundirse con JUMP ni MOVI.
        probar(6'b000011, 6'b0_0_0_0_00, "Adicional: a 1 bit de JUMP");
        probar(6'b001011, 6'b0_0_0_0_00, "Adicional: a 1 bit de MOVI");

        // Adicional: opcode x, el que llega de una palabra de la IMEM sin
        // instrucción (direcciones 10 a 15). Cae en el default: valores seguros.
        probar(6'bxxxxxx, 6'b0_0_0_0_00, "Adicional: opcode x (IMEM vacia)");

        // Caso 6: secuencia R -> J -> I. Cada señal cambia al menos una vez,
        // así que un valor arrastrado de la instrucción anterior daría ERROR.
        probar(6'b000000, 6'b1_0_1_0_10, "Caso 6: secuencia, R");
        probar(6'b000010, 6'b0_0_0_1_00, "Caso 6: secuencia, J");
        probar(6'b001001, 6'b0_1_1_0_11, "Caso 6: secuencia, I (SUBI)");

        if (errores == 0)
            $display("=== %0d pruebas, todas las pruebas OK ===", pruebas);
        else
            $display("=== %0d pruebas, %0d ERRORES ===", pruebas, errores);
        $finish;
    end

endmodule
