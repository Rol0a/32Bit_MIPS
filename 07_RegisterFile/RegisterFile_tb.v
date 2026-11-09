// RegisterFile_tb.v — Testbench del banco de registros. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module RegisterFile_tb;

    // ---- Módulo bajo prueba ----
    reg         clk        = 0;
    reg         reset      = 1;
    reg         RegWrite   = 0;
    reg  [4:0]  read_reg1  = 0;
    reg  [4:0]  read_reg2  = 0;
    reg  [4:0]  write_reg  = 0;
    reg  [31:0] write_data = 0;
    wire [31:0] read_data1, read_data2;

    RegisterFile uut (
        .clk       (clk),
        .reset     (reset),
        .RegWrite  (RegWrite),
        .read_reg1 (read_reg1),
        .read_reg2 (read_reg2),
        .write_reg (write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    always #5 clk = ~clk;   // periodo de 10 ns: flancos de subida en t = 5, 15, 25, ...

    // Registros que pide imprimir el enunciado
    wire [31:0] R0 = uut.registers[0], R1 = uut.registers[1], R2 = uut.registers[2], R3 = uut.registers[3];

    // ---- Casos de prueba ----
    // Cada caso pone las entradas y lo que deben leer los dos puertos. Una escritura se imprime 1 ns después
    // del flanco de subida; una lectura sola, 1 o 2 ns después y sin flanco, porque es asíncrona.
    reg  [31:0] esperado1, esperado2;
    wire        ok = (read_data1 === esperado1) && (read_data2 === esperado2);   // === compara también la x

    initial begin
        $dumpfile("RegisterFile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);

        // Adicional: antes del reset, $0 ya lee 0 y $1 todavía vale x
        read_reg1 = 0;  read_reg2 = 1;  esperado1 = 0;  esperado2 = 32'bx;
        #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 1: el flanco con reset = 1 pone los 32 registros en 0
        reset = 1;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, todos_valen(0) ? "OK" : "ERROR");

        // Caso 2: escribir y leer $1
        reset = 0;  RegWrite = 1;  write_reg = 1;  write_data = 10;
        read_reg1 = 1;  read_reg2 = 0;  esperado1 = 10;  esperado2 = 0;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 3: escribir $2 no cambia $1; luego $2 y $3 a la vez, y $3 por los dos puertos
        RegWrite = 1;  write_reg = 2;  write_data = 20;
        read_reg1 = 1;  read_reg2 = 0;  esperado1 = 10;  esperado2 = 0;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        RegWrite = 1;  write_reg = 3;  write_data = 30;
        read_reg1 = 2;  read_reg2 = 3;  esperado1 = 20;  esperado2 = 30;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        read_reg1 = 3;  read_reg2 = 3;  esperado1 = 30;  esperado2 = 30;
        #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 4: escribir en $0 no tiene efecto, ni en los puertos ni en el arreglo
        RegWrite = 1;  write_reg = 0;  write_data = 999;
        read_reg1 = 0;  read_reg2 = 0;  esperado1 = 0;  esperado2 = 0;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok && R0 === 0 ? "OK" : "ERROR");

        // Caso 5: con RegWrite = 0, $2 sigue en 20
        RegWrite = 0;  write_reg = 2;  write_data = 777;
        read_reg1 = 2;  read_reg2 = 3;  esperado1 = 20;  esperado2 = 30;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 6: lectura asíncrona, otras dos direcciones sin flanco de por medio
        read_reg1 = 1;  read_reg2 = 2;  esperado1 = 10;  esperado2 = 20;
        #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        read_reg1 = 3;  read_reg2 = 1;  esperado1 = 30;  esperado2 = 10;
        #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 7: escritura síncrona; write_data cambia antes del flanco y se guarda el valor del flanco
        RegWrite = 1;  write_reg = 4;  write_data = 40;
        read_reg1 = 4;  read_reg2 = 0;  esperado1 = 0;  esperado2 = 0;
        #2 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        write_data = 44;  esperado1 = 44;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 8: sobrescribir $2, de 20 a 200
        RegWrite = 1;  write_reg = 2;  write_data = 200;
        read_reg1 = 2;  read_reg2 = 1;  esperado1 = 200;  esperado2 = 10;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 9: los 32 bits de $31
        RegWrite = 1;  write_reg = 31;  write_data = 32'hDEADBEEF;
        read_reg1 = 31;  read_reg2 = 0;  esperado1 = 32'hDEADBEEF;  esperado2 = 0;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 10: leer el registro que se escribe; antes del flanco da el valor viejo y después el nuevo
        RegWrite = 1;  write_reg = 1;  write_data = 99;
        read_reg1 = 1;  read_reg2 = 2;  esperado1 = 10;  esperado2 = 200;
        #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        esperado1 = 99;
        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        // Caso 11: reset con datos y RegWrite = 1; el reset gana y $3 no toma 555
        reset = 1;  RegWrite = 1;  write_reg = 3;  write_data = 555;
        read_reg1 = 1;  read_reg2 = 31;  esperado1 = 99;  esperado2 = 32'hDEADBEEF;
        #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        @(posedge clk) #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                                   $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, todos_valen(0) ? "OK" : "ERROR");

        reset = 0;  RegWrite = 0;
        read_reg1 = 3;  read_reg2 = 31;  esperado1 = 0;  esperado2 = 0;
        #1 $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d  |  R1=%0d, R2=%0d, R3=%0d, R0=%0d  %0s",
                    $time, read_reg1, read_data1, read_reg2, read_data2, R1, R2, R3, R0, ok ? "OK" : "ERROR");

        $finish;
    end

    // 1 si los 32 registros del arreglo valen v (para comprobar el reset)
    function todos_valen(input [31:0] v);
        integer i;
        begin
            todos_valen = 1;
            for (i = 0; i < 32; i = i + 1)
                if (uut.registers[i] !== v) todos_valen = 0;
        end
    endfunction

endmodule
