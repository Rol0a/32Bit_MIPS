// =============================================================================
// ALU_tb.v — Testbench de la ALU
// Aplica una operación cada 10 ns, imprime una línea por prueba con control,
// operandos, resultado y zero, y compara resultado y zero contra el valor
// esperado, calculado a mano. Los valores se muestran con signo.
// =============================================================================
`timescale 1ns / 1ps

module ALU_tb;

    // Entradas de la ALU (reg: las maneja el testbench) y salidas
    reg  [31:0] src1;
    reg  [31:0] src2;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;

    integer pruebas = 0;   // operaciones probadas
    integer errores = 0;   // pruebas con resultado o zero distinto del esperado

    // Unidad bajo prueba
    ALU uut (
        .src1       (src1),
        .src2       (src2),
        .alu_control(alu_control),
        .result     (result),
        .zero       (zero)
    );

    // Aplica una operación, espera a que las salidas se asienten y compara
    // result y zero con lo esperado. Los operandos y el resultado esperado
    // pueden escribirse en decimal con signo (-3 queda como 0xFFFFFFFD) o en
    // hexadecimal. Se usa !== para que una x también cuente como error.
    task probar;
        input [3:0]    ctl;
        input [31:0]   a;
        input [31:0]   b;
        input [31:0]   esperado;
        input          esperado_zero;
        input [8*44:1] caso;
        begin
            alu_control = ctl;
            src1        = a;
            src2        = b;
            #10;   // el módulo es combinacional: no hace falta reloj
            pruebas = pruebas + 1;
            if (result !== esperado || zero !== esperado_zero)
                errores = errores + 1;

            // $signed hace que %d imprima en decimal con signo. %6d alinea las
            // columnas; un valor más ancho, como -2147483648, ocupa lo que necesita.
            $display("%2d  ctl=%b src1=%6d src2=%6d -> result=%6d (0x%h) zero=%b | esperado=%6d zero=%b  %s  %0s",
                     pruebas, alu_control, $signed(src1), $signed(src2),
                     $signed(result), result, zero,
                     $signed(esperado), esperado_zero,
                     (result === esperado && zero === esperado_zero) ? "OK   " : "ERROR",
                     caso);
        end
    endtask

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, ALU_tb);

        $display("=== Testbench ALU ===");

        // Casos 1 a 12: los mínimos de la plantilla.
        // Suma y resta
        probar(4'b0010,          50,      15,   65, 1'b0, "Caso 1: suma de positivos");
        probar(4'b0110,          50,      15,   35, 1'b0, "Caso 2: resta positiva");
        probar(4'b0110,          25,      25,    0, 1'b1, "Caso 3: resta con resultado 0");
        probar(4'b0110,           5,      10,   -5, 1'b0, "Caso 4: resta negativa");

        // Multiplicación: 65536 * 65536 = 2^32, que no cabe en 32 bits
        probar(4'b1000,           6,       7,   42, 1'b0, "Caso 5: multiplicacion de positivos");
        probar(4'b1000,       65536,   65536,    0, 1'b1, "Caso 6: multiplicacion con overflow");

        // División: se trunca; entre cero devuelve 0 (decisión del grupo)
        probar(4'b1001,          20,       4,    5, 1'b0, "Caso 7: division exacta");
        probar(4'b1001,           7,       2,    3, 1'b0, "Caso 8: division con residuo");
        probar(4'b1001,           7,       0,    0, 1'b1, "Caso 9: division entre cero");

        // 0xFFFFFFFF es -1 con signo: -1 + 1 = 0, y sin signo da la vuelta
        probar(4'b0010, 32'hFFFFFFFF,      1,    0, 1'b1, "Caso 10: suma con overflow");
        probar(4'b0010,           0,       0,    0, 1'b1, "Caso 11: operandos en cero");

        // Con signo: -5. Sin signo daría 1073741819 (0x3FFFFFFB)
        probar(4'b1001,         -20,       4,   -5, 1'b0, "Caso 12: division con negativo");

        // Adicionales: las dos operaciones de paso, que usan MOVI y MOV.
        // Cada una ignora el otro operando.
        probar(4'b0000,         123,      -3,   -3, 1'b0, "Adicional: MOVI pasa src2");
        probar(4'b0001,          -5,      99,   -5, 1'b0, "Adicional: MOV pasa src1");

        // Adicionales: signo en multiplicación y división.
        probar(4'b1000,           7,      -3,  -21, 1'b0, "Adicional: multiplicacion con negativo");
        probar(4'b1001,          -7,       2,   -3, 1'b0, "Adicional: -7 / 2 trunca hacia cero");
        probar(4'b1001,         -20,      -4,    5, 1'b0, "Adicional: division de dos negativos");

        // Adicionales: desbordes con signo. El resultado da la vuelta sin
        // ningún aviso: 2147483647 + 1 = -2147483648, y -2147483648 / -1
        // (que sería 2147483648) también queda en -2147483648.
        probar(4'b0010, 32'h7FFFFFFF,      1, 32'h80000000, 1'b0, "Adicional: suma con overflow con signo");
        probar(4'b1001, 32'h80000000,     -1, 32'h80000000, 1'b0, "Adicional: -2147483648 / -1");

        // Adicionales: control no definido. Debe dar 0 (y zero = 1) en vez
        // de x: el 1111 que emite ALUControl, un código sin operación y uno
        // con bits x.
        probar(4'b1111,          50,      15,    0, 1'b1, "Adicional: control 1111 (de ALUControl)");
        probar(4'b0011,          50,      15,    0, 1'b1, "Adicional: control sin operacion");
        probar(4'bxxxx,          50,      15,    0, 1'b1, "Adicional: control x");

        if (errores == 0)
            $display("=== %0d pruebas, todas las pruebas OK ===", pruebas);
        else
            $display("=== %0d pruebas, %0d ERRORES ===", pruebas, errores);
        $finish;
    end

endmodule
