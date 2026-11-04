// ALU_tb.v — Testbench de la ALU. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module ALU_tb;

    // ---- Módulo bajo prueba ----
    reg  [31:0] src1, src2;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;

    ALU uut (.src1(src1), .src2(src2), .alu_control(alu_control), .result(result), .zero(zero));

    // ---- Casos de prueba ----
    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, ALU_tb);

        //     control  src1          src2   result        zero
        probar(4'b0010, 50,           15,    65,           0, "Caso 1: suma de positivos");
        probar(4'b0110, 50,           15,    35,           0, "Caso 2: resta positiva");
        probar(4'b0110, 25,           25,    0,            1, "Caso 3: resta con resultado 0");
        probar(4'b0110, 5,            10,    -5,           0, "Caso 4: resta negativa");
        probar(4'b1000, 6,            7,     42,           0, "Caso 5: multiplicacion de positivos");
        probar(4'b1000, 65536,        65536, 0,            1, "Caso 6: multiplicacion con overflow");
        probar(4'b1001, 20,           4,     5,            0, "Caso 7: division exacta");
        probar(4'b1001, 7,            2,     3,            0, "Caso 8: division con residuo");
        probar(4'b1001, 7,            0,     0,            1, "Caso 9: division entre cero");
        probar(4'b0010, 32'hFFFFFFFF, 1,     0,            1, "Caso 10: suma con overflow");
        probar(4'b0010, 0,            0,     0,            1, "Caso 11: operandos en cero");
        probar(4'b1001, -20,          4,     -5,           0, "Caso 12: division con negativo");

        probar(4'b0000, 123,          -3,    -3,           0, "Adicional: MOVI pasa src2");
        probar(4'b0001, -5,           99,    -5,           0, "Adicional: MOV pasa src1");
        probar(4'b1000, 7,            -3,    -21,          0, "Adicional: multiplicacion con negativo");
        probar(4'b1001, -7,           2,     -3,           0, "Adicional: -7 / 2 trunca hacia cero");
        probar(4'b1001, -20,          -4,    5,            0, "Adicional: division de dos negativos");
        probar(4'b0010, 32'h7FFFFFFF, 1,     32'h80000000, 0, "Adicional: suma con overflow con signo");
        probar(4'b1001, 32'h80000000, -1,    32'h80000000, 0, "Adicional: -2147483648 / -1");
        probar(4'b1111, 50,           15,    0,            1, "Adicional: control 1111 (de ALUControl)");
        probar(4'b0011, 50,           15,    0,            1, "Adicional: control sin operacion");
        probar(4'bxxxx, 50,           15,    0,            1, "Adicional: control x");

        $finish;
    end

    // ---- Impresión de resultados ----

    // === compara también la x. $signed imprime en decimal con signo.
    task probar(input [3:0] ctl, input [31:0] a, b, esperado, input esperado_zero, input [8*44:1] caso);
        begin
            alu_control = ctl;
            src1        = a;
            src2        = b;
            #10 $display("ctl=%b src1=%6d src2=%6d -> result=%6d (0x%h) zero=%b | esperado=%6d zero=%b  %s  %0s",
                         alu_control, $signed(src1), $signed(src2),
                         $signed(result), result, zero, $signed(esperado), esperado_zero,
                         (result === esperado && zero === esperado_zero) ? "OK   " : "ERROR", caso);
        end
    endtask

endmodule
