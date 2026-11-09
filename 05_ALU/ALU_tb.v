// ALU_tb.v — Testbench de la ALU. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module ALU_tb;

    // ---- Módulo bajo prueba ----
    reg  signed [31:0] src1, src2;   // signed: %d imprime el valor con signo
    reg         [3:0]  alu_control;
    wire signed [31:0] result;
    wire               zero;

    ALU uut (.src1(src1), .src2(src2), .alu_control(alu_control), .result(result), .zero(zero));

    // ---- Casos de prueba ----
    // Cada caso pone la operación, los operandos y el resultado esperado (calculado a mano) e imprime
    // 10 ns después. zero debe valer 1 solo si el resultado esperado es 0.
    reg  signed [31:0] esperado;
    wire               ok = (result === esperado) && (zero === (esperado == 0));   // === compara también la x

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, ALU_tb);

        alu_control = 4'b0010;  src1 = 50;            src2 = 15;     esperado = 65;            // Caso 1: suma de positivos
        #10 $display("%b:  %0d + %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0110;  src1 = 50;            src2 = 15;     esperado = 35;            // Caso 2: resta positiva
        #10 $display("%b:  %0d - %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0110;  src1 = 25;            src2 = 25;     esperado = 0;             // Caso 3: resta con resultado 0
        #10 $display("%b:  %0d - %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0110;  src1 = 5;             src2 = 10;     esperado = -5;            // Caso 4: resta negativa
        #10 $display("%b:  %0d - %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1000;  src1 = 6;             src2 = 7;      esperado = 42;            // Caso 5: multiplicación de positivos
        #10 $display("%b:  %0d * %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1000;  src1 = 65536;         src2 = 65536;  esperado = 0;             // Caso 6: multiplicación con overflow
        #10 $display("%b:  %0d * %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1001;  src1 = 20;            src2 = 4;      esperado = 5;             // Caso 7: división exacta
        #10 $display("%b:  %0d / %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1001;  src1 = 7;             src2 = 2;      esperado = 3;             // Caso 8: división con residuo
        #10 $display("%b:  %0d / %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1001;  src1 = 7;             src2 = 0;      esperado = 0;             // Caso 9: división entre cero
        #10 $display("%b:  %0d / %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0010;  src1 = 32'hFFFFFFFF;  src2 = 1;      esperado = 0;             // Caso 10: suma con overflow (sin signo)
        #10 $display("%b:  %0d + %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0010;  src1 = 0;             src2 = 0;      esperado = 0;             // Caso 11: operandos en cero
        #10 $display("%b:  %0d + %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1001;  src1 = -20;           src2 = 4;      esperado = -5;            // Caso 12: división con negativo
        #10 $display("%b:  %0d / %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0000;  src1 = 123;           src2 = -3;     esperado = -3;            // Adicional: MOVI pasa src2
        #10 $display("%b:  MOVI %0d, %0d -> %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0001;  src1 = -5;            src2 = 99;     esperado = -5;            // Adicional: MOV pasa src1
        #10 $display("%b:  MOV %0d, %0d -> %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1000;  src1 = 7;             src2 = -3;     esperado = -21;           // Adicional: multiplicación con negativo
        #10 $display("%b:  %0d * %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1001;  src1 = -7;            src2 = 2;      esperado = -3;            // Adicional: -7 / 2 trunca hacia cero
        #10 $display("%b:  %0d / %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1001;  src1 = -20;           src2 = -4;     esperado = 5;             // Adicional: división de dos negativos
        #10 $display("%b:  %0d / %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0010;  src1 = 32'h7FFFFFFF;  src2 = 1;      esperado = 32'h80000000;  // Adicional: suma con overflow con signo
        #10 $display("%b:  %0d + %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1001;  src1 = 32'h80000000;  src2 = -1;     esperado = 32'h80000000;  // Adicional: -2147483648 / -1
        #10 $display("%b:  %0d / %0d = %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b1111;  src1 = 50;            src2 = 15;     esperado = 0;             // Adicional: control 1111 (de ALUControl)
        #10 $display("%b:  %0d, %0d -> %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'b0011;  src1 = 50;            src2 = 15;     esperado = 0;             // Adicional: control sin operación
        #10 $display("%b:  %0d, %0d -> %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        alu_control = 4'bxxxx;  src1 = 50;            src2 = 15;     esperado = 0;             // Adicional: control x
        #10 $display("%b:  %0d, %0d -> %0d  zero=%b  %0s", alu_control, src1, src2, result, zero, ok ? "OK" : "ERROR");

        $finish;
    end

endmodule
