// PC_tb.v — Testbench del Program Counter. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module PC_tb;

    // ---- Módulo bajo prueba ----
    reg         clk     = 0;
    reg         reset   = 1;
    reg  [31:0] next_pc = 100;
    wire [31:0] current_pc;

    PC uut (.clk(clk), .reset(reset), .next_pc(next_pc), .current_pc(current_pc));

    always #5 clk = ~clk;   // periodo de 10 ns: flancos de subida en t = 5, 15, 25, ...

    // ---- Casos de prueba ----
    initial begin
        $dumpfile("PC_tb.vcd");
        $dumpvars(0, PC_tb);

        #1 verificar(32'bx, "antes del primer flanco: aun sin reset");

        //   reset  next_pc  esperado
        paso(1,     100,     0,  "Caso 1: reset activo");
        paso(1,     200,     0,  "Caso 1: reset activo");
        paso(0,     1,       1,  "Caso 2: soltar reset");
        paso(0,     2,       2,  "Caso 3: avance normal");
        paso(0,     3,       3,  "Caso 3: avance normal");
        paso(0,     4,       4,  "Caso 3: avance normal");

        // Caso 4: next_pc cambia dos veces entre flancos y el PC no se mueve hasta el flanco
        #1 next_pc = 50;
        #1 verificar(4, "Caso 4: cambio entre flancos");
        #1 next_pc = 60;
        #1 verificar(4, "Caso 4: cambio entre flancos");
        paso(0,     60,      60, "Caso 4: carga en el flanco");

        paso(0,     32'hFFFF_FFFF, 32'hFFFF_FFFF, "Caso 6: 32 bits completos");
        paso(1,     7,       0,  "Caso 5: reset a mitad de ejecucion");
        paso(0,     1,       1,  "Caso 5: avanza tras el reset");

        $finish;
    end

    // ---- Impresión de resultados ----

    // Aplica las entradas e imprime 1 ns después del flanco, cuando el <= ya se asentó.
    task paso(input r, input [31:0] npc, esperado, input [8*40:1] caso);
        begin
            reset   = r;
            next_pc = npc;
            @(posedge clk);
            #1 verificar(esperado, caso);
            @(negedge clk);
        end
    endtask

    // === compara también la x.
    task verificar(input [31:0] esperado, input [8*40:1] caso);
        $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  esperado=%10d  %s  %0s",
                 $time, reset, next_pc, current_pc, esperado,
                 (current_pc === esperado) ? "OK   " : "ERROR", caso);
    endtask

endmodule
