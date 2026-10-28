// =============================================================================
// ALUControl_tb.v — Testbench del Control de la ALU
// Cambia ALUOp y funct cada 10 ns, imprime una línea por prueba y compara
// alu_control contra el valor esperado, calculado a mano con la tabla del
// enunciado. Los casos siguen el orden de la tabla de la plantilla.
// =============================================================================
`timescale 1ns / 1ps

module ALUControl_tb;

    // Entradas de ALUControl (reg: las maneja el testbench) y salida
    reg  [1:0] ALUOp;
    reg  [5:0] funct;
    wire [3:0] alu_control;

    integer pruebas = 0;   // combinaciones probadas
    integer errores = 0;   // comparaciones fallidas

    // Unidad bajo prueba
    ALUControl uut (
        .ALUOp      (ALUOp),
        .funct      (funct),
        .alu_control(alu_control)
    );

    // Aplica ALUOp y funct, espera a que la salida se asiente y la compara con
    // el esperado. Se usa !== para que una x también cuente como error.
    task probar;
        input [1:0]    op;
        input [5:0]    fn;
        input [3:0]    esperado;
        input [8*44:1] caso;
        begin
            ALUOp = op;
            funct = fn;
            #10;   // el módulo es combinacional: no hace falta reloj
            pruebas = pruebas + 1;
            if (alu_control !== esperado)
                errores = errores + 1;

            $display("%2d  ALUOp=%b, funct=%b -> alu_control=%b | esperado=%b  %s  %0s",
                     pruebas, ALUOp, funct, alu_control, esperado,
                     (alu_control === esperado) ? "OK   " : "ERROR", caso);
        end
    endtask

    initial begin
        $dumpfile("ALUControl_tb.vcd");
        $dumpvars(0, ALUControl_tb);

        $display("=== Testbench ALUControl ===");

        // Casos 1 a 5: instrucciones R. Con ALUOp = 10 manda funct.
        probar(2'b10, 6'b100000, 4'b0010, "Caso 1: ADD");
        probar(2'b10, 6'b100100, 4'b0110, "Caso 2: SUB");
        probar(2'b10, 6'b100001, 4'b1000, "Caso 3: MULT");
        probar(2'b10, 6'b100010, 4'b1001, "Caso 4: DIV");
        probar(2'b10, 6'b100011, 4'b0001, "Caso 5: MOV");

        // Caso 6: MOVI. funct son los 6 bits bajos del inmediato; aquí los de
        // movi $1, 7 (000111).
        probar(2'b00, 6'b000111, 4'b0000, "Caso 6: MOVI (funct = bits de imm 7)");

        // Caso 7: la plantilla supone que ADDI llega con ALUOp = 00. Con la
        // tabla del enunciado eso da 0000 (MOVI): la ALU devolvería solo el
        // inmediato. Por eso nuestra Unidad de Control manda ADDI con 01
        // (caso 10). funct = 001010: bits bajos de addi $9, $8, 10.
        probar(2'b00, 6'b001010, 4'b0000, "Caso 7: ADDI con ALUOp=00 da MOVI");

        // Caso 8: con ALUOp = 00, el funct de la suma no cambia nada.
        probar(2'b00, 6'b100000, 4'b0000, "Caso 8: ALUOp=00 ignora funct de ADD");

        // Caso 9: funct que no está en la tabla. Devuelve nuestro 1111.
        probar(2'b10, 6'b111111, 4'b1111, "Caso 9: funct no definido");

        // Casos 10 y 11: el enunciado no define ALUOp 01 ni 11. El grupo los
        // usa para ADDI (suma) y SUBI (resta); funct se ignora. Bits bajos de
        // addi $9, $8, 10 (001010) y de subi $7, $9, 15 (001111).
        probar(2'b01, 6'b001010, 4'b0010, "Caso 10: ALUOp=01, ADDI (suma)");
        probar(2'b11, 6'b001111, 4'b0110, "Caso 11: ALUOp=11, SUBI (resta)");

        // Adicionales: funct no definidos que podrían colarse.
        probar(2'b10, 6'b000000, 4'b1111, "Adicional: funct 000000 (instr. 0)");
        probar(2'b10, 6'b011000, 4'b1111, "Adicional: funct de MUL en la .xlsx");

        // Adicionales: ADDI y SUBI tampoco miran funct, aunque coincida con
        // el de otra operación R.
        probar(2'b01, 6'b100100, 4'b0010, "Adicional: ADDI con funct de SUB");
        probar(2'b11, 6'b100000, 4'b0110, "Adicional: SUBI con funct de ADD");

        // Adicional: ALUOp con x. Cae en el default: 1111, no x.
        probar(2'bxx, 6'b100000, 4'b1111, "Adicional: ALUOp x");

        if (errores == 0)
            $display("=== %0d pruebas, todas las pruebas OK ===", pruebas);
        else
            $display("=== %0d pruebas, %0d ERRORES ===", pruebas, errores);
        $finish;
    end

endmodule
