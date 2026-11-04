// ALUControl_tb.v — Testbench del control de la ALU. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module ALUControl_tb;

    // ---- Módulo bajo prueba ----
    reg  [1:0] ALUOp;
    reg  [5:0] funct;
    wire [3:0] alu_control;

    ALUControl uut (.ALUOp(ALUOp), .funct(funct), .alu_control(alu_control));

    // ---- Casos de prueba ----
    initial begin
        $dumpfile("ALUControl_tb.vcd");
        $dumpvars(0, ALUControl_tb);

        //     ALUOp  funct      esperado
        probar(2'b10, 6'b100000, 4'b0010, "Caso 1: ADD");
        probar(2'b10, 6'b100010, 4'b0110, "Caso 2: SUB");
        probar(2'b10, 6'b011000, 4'b1000, "Caso 3: MULT");
        probar(2'b10, 6'b011010, 4'b1001, "Caso 4: DIV");
        probar(2'b10, 6'b100011, 4'b0001, "Caso 5: MOV");

        // En las tipo I, funct son los 6 bits bajos del inmediato de una instrucción de clase
        probar(2'b00, 6'b001111, 4'b0000, "Caso 6: MOVI (funct = bits de imm 15)");
        probar(2'b00, 6'b001010, 4'b0000, "Caso 7: ADDI con ALUOp=00 da MOVI");
        probar(2'b00, 6'b100000, 4'b0000, "Caso 8: ALUOp=00 ignora funct de ADD");
        probar(2'b10, 6'b111111, 4'b1111, "Caso 9: funct no definido");
        probar(2'b01, 6'b001010, 4'b0010, "Caso 10: ALUOp=01, ADDI (suma)");
        probar(2'b11, 6'b000100, 4'b0110, "Caso 11: ALUOp=11, SUBI (resta)");

        probar(2'b10, 6'b000000, 4'b1111, "Adicional: funct 000000 (palabra 0)");
        probar(2'b10, 6'b100100, 4'b1111, "Adicional: 100100 (SUB del enunciado)");
        probar(2'b10, 6'b100001, 4'b1111, "Adicional: 100001 (MUL del enunciado)");
        probar(2'b01, 6'b100010, 4'b0010, "Adicional: ADDI con funct de SUB");
        probar(2'b11, 6'b100000, 4'b0110, "Adicional: SUBI con funct de ADD");
        probar(2'bxx, 6'b100000, 4'b1111, "Adicional: ALUOp x");

        $finish;
    end

    // ---- Impresión de resultados ----

    // === compara también la x.
    task probar(input [1:0] op, input [5:0] fn, input [3:0] esperado, input [8*44:1] caso);
        begin
            ALUOp = op;
            funct = fn;
            #10 $display("ALUOp=%b, funct=%b -> alu_control=%b | esperado=%b  %s  %0s",
                         ALUOp, funct, alu_control, esperado,
                         (alu_control === esperado) ? "OK   " : "ERROR", caso);
        end
    endtask

endmodule
