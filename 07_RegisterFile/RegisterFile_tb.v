// =============================================================================
// RegisterFile_tb.v — Testbench del Banco de Registros
// Recorre los casos de la plantilla en orden: reset, escrituras, intento de
// escribir en $0, RegWrite = 0, lectura asíncrona, escritura síncrona y reset
// con datos. Imprime los registros después de cada ciclo de escritura y
// compara cada lectura contra el valor esperado, calculado a mano.
// =============================================================================
`timescale 1ns / 1ps

module RegisterFile_tb;

    // Entradas del banco (reg: las maneja el testbench) y salidas (wire)
    reg         clk;
    reg         reset;
    reg         RegWrite;
    reg  [4:0]  read_reg1;
    reg  [4:0]  read_reg2;
    reg  [4:0]  write_reg;
    reg  [31:0] write_data;
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    integer pruebas = 0;   // comprobaciones hechas
    integer errores = 0;   // comparaciones fallidas
    integer i;

    // Unidad bajo prueba
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

    // Reloj de 10 ns: flancos de subida en t = 5, 15, 25, ...
    always #5 clk = ~clk;

    // Imprime los registros con el formato del enunciado y, al final, el
    // registro destino. El arreglo está dentro del módulo: se lee con el
    // nombre de la instancia, uut.registers[i].
    task mostrar;
        begin
            $display("    t=%t  RegWrite=%b write_reg=%0d write_data=%0d -> R1=%0d, R2=%0d, R3=%0d, R0=%0d | R%0d=%0d",
                     $time, RegWrite, write_reg, write_data,
                     uut.registers[1], uut.registers[2], uut.registers[3], uut.registers[0],
                     write_reg, uut.registers[write_reg]);
        end
    endtask

    // Un ciclo de escritura: prepara las entradas en el flanco de bajada
    // (lejos del flanco activo), espera el flanco de subida y muestra los
    // registros 1 ns después, cuando los <= del banco ya se asentaron.
    task ciclo;
        input        we;
        input [4:0]  dir;
        input [31:0] dato;
        begin
            @(negedge clk);
            RegWrite   = we;
            write_reg  = dir;
            write_data = dato;
            @(posedge clk); #1;
            mostrar;
            RegWrite = 0;
        end
    endtask

    // Pone dos direcciones en los puertos de lectura, espera 1 ns SIN flanco
    // de reloj (la lectura es asíncrona) y compara las dos salidas con el
    // esperado. Se usa !== para que una x también cuente como error.
    task leer;
        input [4:0]    r1;
        input [4:0]    r2;
        input [31:0]   esp1;
        input [31:0]   esp2;
        input [8*44:1] caso;
        begin
            read_reg1 = r1;
            read_reg2 = r2;
            #1;
            pruebas = pruebas + 1;
            if (read_data1 !== esp1 || read_data2 !== esp2)
                errores = errores + 1;
            $display("%2d  t=%t  read_reg1=%0d -> %0d  read_reg2=%0d -> %0d | esperado=%0d, %0d  %s  %0s",
                     pruebas, $time, read_reg1, read_data1, read_reg2, read_data2,
                     esp1, esp2,
                     (read_data1 === esp1 && read_data2 === esp2) ? "OK   " : "ERROR",
                     caso);
        end
    endtask

    // Compara un valor suelto (por ejemplo, del arreglo interno) con el
    // esperado.
    task comprobar;
        input [31:0]   obtenido;
        input [31:0]   esperado;
        input [8*44:1] caso;
        begin
            pruebas = pruebas + 1;
            if (obtenido !== esperado)
                errores = errores + 1;
            $display("%2d  t=%t  valor=%0d | esperado=%0d  %s  %0s",
                     pruebas, $time, obtenido, esperado,
                     (obtenido === esperado) ? "OK   " : "ERROR", caso);
        end
    endtask

    // Revisa los 32 registros del arreglo después de un reset. Cuenta como
    // una sola prueba e imprime cuántos no valen 0.
    task revisar_reset;
        input [8*44:1] caso;
        integer distintos;
        begin
            distintos = 0;
            for (i = 0; i < 32; i = i + 1)
                if (uut.registers[i] !== 32'd0)
                    distintos = distintos + 1;
            pruebas = pruebas + 1;
            if (distintos != 0)
                errores = errores + 1;
            $display("%2d  t=%t  registros distintos de 0: %0d de 32 | esperado=0  %s  %0s",
                     pruebas, $time, distintos,
                     (distintos == 0) ? "OK   " : "ERROR", caso);
        end
    endtask

    initial begin
        $dumpfile("RegisterFile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);

        // Inicialización: reloj en 0 y reset activo.
        clk        = 0;
        reset      = 1;
        RegWrite   = 0;
        read_reg1  = 0;
        read_reg2  = 0;
        write_reg  = 0;
        write_data = 0;

        // %t imprime el tiempo en ns, sin decimales
        $timeformat(-9, 0, " ns", 6);

        $display("=== Testbench RegisterFile ===");

        // Adicional: antes del primer flanco, el reset síncrono todavía no
        // actuó y el arreglo vale x. $0 ya se lee como 0 (protección 1 del
        // módulo); $1 da x.
        leer(5'd0, 5'd1, 32'd0, 32'bx, "Adicional: antes del reset, $0 lee 0");

        // Caso 1: reset = 1 durante un flanco de subida pone los 32
        // registros en 0. Se suelta justo después de ese flanco.
        @(posedge clk); #1;
        revisar_reset("Caso 1: reset = 1, los 32 en 0");
        mostrar;
        reset = 0;

        // Caso 2: escribir y leer un registro distinto de $0.
        ciclo(1, 5'd1, 32'd10);
        leer(5'd1, 5'd0, 32'd10, 32'd0, "Caso 2: escribir y leer $1");

        // Caso 3: dos registros por los dos puertos a la vez, y el mismo
        // registro por ambos puertos.
        ciclo(1, 5'd2, 32'd20);
        ciclo(1, 5'd3, 32'd30);
        leer(5'd2, 5'd3, 32'd20, 32'd30, "Caso 3: $2 y $3 a la vez");
        leer(5'd3, 5'd3, 32'd30, 32'd30, "Caso 3: $3 por los dos puertos");

        // Caso 4: intento de escribir en $0 con RegWrite = 1. Sigue en 0 por
        // los puertos y también en el arreglo interno.
        ciclo(1, 5'd0, 32'd999);
        leer(5'd0, 5'd0, 32'd0, 32'd0, "Caso 4: $0 sigue en 0 (puertos)");
        comprobar(uut.registers[0], 32'd0, "Caso 4: $0 sigue en 0 (arreglo)");

        // Caso 5: RegWrite = 0. Cambian la dirección y el dato, pero no se
        // escribe nada: $2 conserva 20.
        ciclo(0, 5'd2, 32'd777);
        leer(5'd2, 5'd3, 32'd20, 32'd30, "Caso 5: RegWrite=0, $2 sigue en 20");

        // Caso 6: lectura asíncrona. Las direcciones cambian dos veces más
        // dentro del mismo ciclo (mirar t: no hay flanco de por medio) y la
        // salida cambia de inmediato.
        leer(5'd1, 5'd2, 32'd10, 32'd20, "Caso 6: otra direccion, sin flanco");
        leer(5'd3, 5'd1, 32'd30, 32'd10, "Caso 6: otra direccion, sin flanco");

        // Caso 7: escritura síncrona. write_data cambia entre flancos (40 y
        // luego 44): antes del flanco $4 no cambia, y en el flanco se guarda
        // lo que haya en ese momento, 44.
        @(negedge clk);
        RegWrite   = 1;
        write_reg  = 5'd4;
        write_data = 32'd40;
        leer(5'd4, 5'd0, 32'd0, 32'd0, "Caso 7: antes del flanco $4 = 0");
        #1 write_data = 32'd44;
        @(posedge clk); #1;
        mostrar;
        RegWrite = 0;
        leer(5'd4, 5'd0, 32'd44, 32'd0, "Caso 7: se guarda 44, el dato del flanco");

        // Caso 8: sobrescribir. $2 tenía 20 y pasa a 200.
        ciclo(1, 5'd2, 32'd200);
        leer(5'd2, 5'd1, 32'd200, 32'd10, "Caso 8: $2 sobrescrito, 20 -> 200");

        // Caso 9: último registro, con los 32 bits en uso.
        ciclo(1, 5'd31, 32'hDEADBEEF);
        leer(5'd31, 5'd0, 32'hDEADBEEF, 32'd0, "Caso 9: $31 = 0xDEADBEEF");

        // Caso 10: leer el registro que se está escribiendo. Antes del flanco
        // se ve el valor viejo (10); después, el nuevo (99).
        @(negedge clk);
        RegWrite   = 1;
        write_reg  = 5'd1;
        write_data = 32'd99;
        leer(5'd1, 5'd2, 32'd10, 32'd200, "Caso 10: antes del flanco, $1 viejo");
        @(posedge clk); #1;
        mostrar;
        RegWrite = 0;
        leer(5'd1, 5'd2, 32'd99, 32'd200, "Caso 10: despues del flanco, $1 nuevo");

        // Caso 11: reset con datos, y RegWrite = 1 intentando escribir $3. El
        // reset es síncrono: al activarlo los datos siguen ahí; en el flanco
        // de subida los 32 registros pasan a 0 y $3 no toma 555.
        @(negedge clk);
        reset      = 1;
        RegWrite   = 1;
        write_reg  = 5'd3;
        write_data = 32'd555;
        leer(5'd1, 5'd31, 32'd99, 32'hDEADBEEF, "Caso 11: reset=1, sin flanco aun");
        @(posedge clk); #1;
        revisar_reset("Caso 11: en el flanco, los 32 en 0");
        mostrar;
        reset    = 0;
        RegWrite = 0;
        leer(5'd3, 5'd31, 32'd0, 32'd0, "Caso 11: $3 no tomo 555");

        if (errores == 0)
            $display("=== %0d pruebas, todas las pruebas OK ===", pruebas);
        else
            $display("=== %0d pruebas, %0d ERRORES ===", pruebas, errores);
        $finish;
    end

endmodule
