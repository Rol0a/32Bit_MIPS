// =============================================================================
// PC_tb.v — Testbench del Program Counter
// Recorre los casos de prueba del README.md de esta carpeta, imprime una línea
// por ciclo y compara current_pc contra el valor esperado.
// =============================================================================
`timescale 1ns / 1ps

module PC_tb;

    // Entradas del PC (reg: las maneja el testbench) y salida (wire)
    reg         clk;
    reg         reset;
    reg  [31:0] next_pc;
    wire [31:0] current_pc;

    integer ciclo   = 0;   // número de flanco de subida
    integer errores = 0;   // comparaciones fallidas

    // Unidad bajo prueba
    PC uut (
        .clk       (clk),
        .reset     (reset),
        .next_pc   (next_pc),
        .current_pc(current_pc)
    );

    // Reloj de 10 ns: flancos de subida en t = 5, 15, 25, ...
    always #5 clk = ~clk;

    // Compara current_pc con el valor esperado e imprime el resultado.
    // Se usa !== para que una x también cuente como error.
    task verificar;
        input [31:0]  esperado;
        input [8*40:1] caso;
        begin
            if (current_pc !== esperado) errores = errores + 1;
            $display("t=%t  reset=%b  next_pc=%10d  ->  current_pc=%10d  esperado=%10d  %s  %0s",
                     $time, reset, next_pc, current_pc, esperado,
                     (current_pc === esperado) ? "OK   " : "ERROR", caso);
        end
    endtask

    // Un ciclo completo: aplica las entradas, espera el flanco de subida e
    // imprime 1 ns después (el <= del PC ya se asentó). Termina en el flanco de
    // bajada, para que el siguiente ciclo cambie las entradas lejos del flanco
    // activo.
    task paso;
        input         r;
        input [31:0]  npc;
        input [31:0]  esperado;
        input [8*40:1] caso;
        begin
            reset   = r;
            next_pc = npc;
            @(posedge clk); #1;
            ciclo = ciclo + 1;
            $write("ciclo %2d  ", ciclo);
            verificar(esperado, caso);
            @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("PC_tb.vcd");
        $dumpvars(0, PC_tb);

        // Inicialización: reloj en 0, reset activo y una dirección siguiente
        // distinta de 0 para comprobar que el reset tiene prioridad.
        clk     = 0;
        reset   = 1;
        next_pc = 32'd100;

        // %t imprime el tiempo en ns, sin decimales
        $timeformat(-9, 0, " ns", 6);

        $display("=== Testbench PC ===");
        #1 $display("t=%t  antes del primer flanco: current_pc=%0d (x: el PC aun no se ha reiniciado)",
                    $time, current_pc);

        // Caso 1: reset activo. Aunque next_pc != 0, el PC queda en 0.
        paso(1, 32'd100, 32'd0, "Caso 1: reset activo");
        paso(1, 32'd200, 32'd0, "Caso 1: reset activo");

        // Caso 2: se suelta reset; el primer flanco carga next_pc.
        paso(0, 32'd1, 32'd1, "Caso 2: soltar reset");

        // Caso 3: next_pc cambia cada ciclo y el PC lo copia en cada flanco.
        paso(0, 32'd2, 32'd2, "Caso 3: avance normal");
        paso(0, 32'd3, 32'd3, "Caso 3: avance normal");
        paso(0, 32'd4, 32'd4, "Caso 3: avance normal");

        // Caso 4: next_pc cambia dos veces entre flancos; el PC no se mueve
        // hasta el siguiente flanco de subida, y entonces toma el último valor.
        #1 next_pc = 32'd50;
        #1 $write("          "); verificar(32'd4, "Caso 4: cambio entre flancos");
        #1 next_pc = 32'd60;
        #1 $write("          "); verificar(32'd4, "Caso 4: cambio entre flancos");
        paso(0, 32'd60, 32'd60, "Caso 4: carga en el flanco");

        // Caso 6 (adicional): dirección con los 32 bits en 1; el PC la guarda
        // completa, sin truncar.
        paso(0, 32'hFFFF_FFFF, 32'hFFFF_FFFF, "Caso 6: 32 bits completos");

        // Caso 5: reset a mitad de ejecución regresa el PC a 0 y, al soltarlo,
        // el PC vuelve a avanzar.
        paso(1, 32'd7, 32'd0, "Caso 5: reset a mitad de ejecucion");
        paso(0, 32'd1, 32'd1, "Caso 5: avanza tras el reset");

        if (errores == 0)
            $display("=== %0d ciclos, todas las pruebas OK ===", ciclo);
        else
            $display("=== %0d ciclos, %0d ERRORES ===", ciclo, errores);
        $finish;
    end

endmodule
