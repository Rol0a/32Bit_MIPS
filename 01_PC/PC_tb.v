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
    // Cada caso pone las entradas y el PC esperado (calculado a mano) e imprime 1 ns después del flanco
    // de subida, cuando el <= ya se asentó.
    reg  [31:0] esperado;
    wire        ok = (current_pc === esperado);   // === compara también la x

    initial begin
        $dumpfile("PC_tb.vcd");
        $dumpvars(0, PC_tb);

        esperado = 32'bx;                                    // antes del primer flanco: aún sin reset
        #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 1;  next_pc = 100;  esperado = 0;            // Caso 1: reset activo
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 1;  next_pc = 200;  esperado = 0;            // Caso 1: reset activo
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 1;    esperado = 1;            // Caso 2: soltar reset
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 2;    esperado = 2;            // Caso 3: avance normal
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 3;    esperado = 3;            // Caso 3: avance normal
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 4;    esperado = 4;            // Caso 3: avance normal
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        // Caso 4: next_pc cambia dos veces entre flancos (#2, sin flanco) y el PC solo lo toma en el flanco
        reset = 0;  next_pc = 50;   esperado = 4;
        #2 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 60;   esperado = 4;
        #2 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 60;   esperado = 60;
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 32'hFFFF_FFFF;  esperado = 32'hFFFF_FFFF;   // Caso 6: 32 bits completos
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 1;  next_pc = 7;    esperado = 0;            // Caso 5: reset a mitad de ejecución
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        reset = 0;  next_pc = 1;    esperado = 1;            // Caso 5: avanza tras el reset
        @(posedge clk) #1 $display("t=%3d ns  reset=%b  next_pc=%10d  ->  current_pc=%10d  %0s", $time, reset, next_pc, current_pc, ok ? "OK" : "ERROR");

        $finish;
    end

endmodule
