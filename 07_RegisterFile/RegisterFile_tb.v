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

    // ---- Casos de prueba ----
    initial begin
        $dumpfile("RegisterFile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);

        leer(0, 1, 0, 32'bx, "Adicional: antes del reset, $0 lee 0");
        flanco_con_reset("Caso 1: reset = 1, los 32 en 0");

        ciclo(1, 1, 10);
        leer(1, 0, 10, 0, "Caso 2: escribir y leer $1");

        ciclo(1, 2, 20);
        leer(1, 0, 10, 0, "Caso 3: escribir $2 no cambia $1");
        ciclo(1, 3, 30);
        leer(2, 3, 20, 30, "Caso 3: $2 y $3 a la vez");
        leer(3, 3, 30, 30, "Caso 3: $3 por los dos puertos");

        ciclo(1, 0, 999);
        leer(0, 0, 0, 0, "Caso 4: $0 sigue en 0 (puertos)");
        imprimir(uut.registers[0] === 32'd0, 0, 0, "Caso 4: $0 sigue en 0 (arreglo)");

        ciclo(0, 2, 777);
        leer(2, 3, 20, 30, "Caso 5: RegWrite=0, $2 sigue en 20");

        // Lectura asíncrona: dos direcciones más sin flanco de por medio
        leer(1, 2, 10, 20, "Caso 6: otra direccion, sin flanco");
        leer(3, 1, 30, 10, "Caso 6: otra direccion, sin flanco");

        // Escritura síncrona: write_data cambia antes del flanco y se guarda el último valor
        preparar(1, 4, 40);
        leer(4, 0, 0, 0, "Caso 7: antes del flanco $4 = 0");
        #1 write_data = 44;
        flanco;
        leer(4, 0, 44, 0, "Caso 7: se guarda 44, el dato del flanco");

        ciclo(1, 2, 200);
        leer(2, 1, 200, 10, "Caso 8: $2 sobrescrito, 20 -> 200");

        ciclo(1, 31, 32'hDEADBEEF);
        leer(31, 0, 32'hDEADBEEF, 0, "Caso 9: $31 = 0xDEADBEEF");

        // Leer el registro que se está escribiendo: antes del flanco, el valor viejo
        preparar(1, 1, 99);
        leer(1, 2, 10, 200, "Caso 10: antes del flanco, $1 viejo");
        flanco;
        leer(1, 2, 99, 200, "Caso 10: despues del flanco, $1 nuevo");

        // Reset con datos y RegWrite = 1: el reset gana y $3 no toma 555
        preparar(1, 3, 555);
        reset = 1;
        leer(1, 31, 99, 32'hDEADBEEF, "Caso 11: reset=1, sin flanco aun");
        flanco_con_reset("Caso 11: en el flanco, los 32 en 0");
        leer(3, 31, 0, 0, "Caso 11: $3 no tomo 555");

        $finish;
    end

    // ---- Impresión de resultados ----

    // Un ciclo de escritura completo.
    task ciclo(input we, input [4:0] dir, input [31:0] dato);
        begin
            preparar(we, dir, dato);
            flanco;
        end
    endtask

    // Las entradas cambian en el flanco de bajada, lejos del flanco activo.
    task preparar(input we, input [4:0] dir, input [31:0] dato);
        begin
            @(negedge clk);
            RegWrite   = we;
            write_reg  = dir;
            write_data = dato;
        end
    endtask

    task flanco;
        begin
            @(posedge clk);
            #1 RegWrite = 0;
        end
    endtask

    // Revisa los 32 registros del arreglo tras un flanco con reset = 1 y suelta reset.
    task flanco_con_reset(input [8*44:1] caso);
        reg     todos_en_0;
        integer i;
        begin
            @(posedge clk); #1;
            todos_en_0 = 1;
            for (i = 0; i < 32; i = i + 1)
                if (uut.registers[i] !== 32'd0) todos_en_0 = 0;
            imprimir(todos_en_0, 0, 0, caso);
            reset    = 0;
            RegWrite = 0;
        end
    endtask

    // Lee los dos puertos 1 ns después, sin flanco: la lectura es asíncrona. === compara también la x.
    task leer(input [4:0] r1, r2, input [31:0] esp1, esp2, input [8*44:1] caso);
        begin
            read_reg1 = r1;
            read_reg2 = r2;
            #1 imprimir(read_data1 === esp1 && read_data2 === esp2, esp1, esp2, caso);
        end
    endtask

    // Cada línea lleva los dos puertos y R1, R2, R3, R0 con el formato del enunciado.
    task imprimir(input ok, input [31:0] esp1, esp2, input [8*44:1] caso);
        $display("t=%3d ns  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d | esperado=%0d, %0d | R1=%0d, R2=%0d, R3=%0d, R0=%0d  %s  %0s",
                 $time, read_reg1, read_data1, read_reg2, read_data2, esp1, esp2,
                 uut.registers[1], uut.registers[2], uut.registers[3], uut.registers[0],
                 ok ? "OK   " : "ERROR", caso);
    endtask

endmodule
