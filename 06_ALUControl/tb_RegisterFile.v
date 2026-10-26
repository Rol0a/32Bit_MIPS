`timescale 1ns/1ns

module tb_RegisterFile;

    reg clk;
    reg reset;
    reg RegWrite;
    reg [4:0] read_reg1;
    reg [4:0] read_reg2;
    reg [4:0] write_reg;
    reg [31:0] write_data;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    integer pruebas;
    integer errores;
    integer i;

    RegisterFile uut (
        .clk(clk),
        .reset(reset),
        .RegWrite(RegWrite),
        .read_reg1(read_reg1),
        .read_reg2(read_reg2),
        .write_reg(write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Periodo de reloj: 10 ns.
    always #5 clk = ~clk;

    task verificar;
        input [31:0] obtenido;
        input [31:0] esperado;
        begin
            pruebas = pruebas + 1;
            if (obtenido !== esperado) begin
                errores = errores + 1;
                $display("ERROR prueba %0d: obtenido=%0d, esperado=%0d",
                         pruebas, obtenido, esperado);
            end
        end
    endtask

    task escribir;
        input [4:0] direccion;
        input [31:0] dato;
        begin
            // Preparar entradas lejos del flanco de escritura.
            @(negedge clk);
            RegWrite = 1;
            write_reg = direccion;
            write_data = dato;

            @(posedge clk);
            #1; // Esperar las asignaciones no bloqueantes.

            $display("Escritura R%0d <- %0d | R1=%0d R2=%0d R3=%0d R0=%0d",
                     direccion, dato,
                     uut.registers[1], uut.registers[2],
                     uut.registers[3], uut.registers[0]);

            RegWrite = 0;
        end
    endtask

    task leer_y_verificar;
        input [4:0] direccion1;
        input [4:0] direccion2;
        input [31:0] esperado1;
        input [31:0] esperado2;
        begin
            read_reg1 = direccion1;
            read_reg2 = direccion2;
            #1;

            $display("Lectura: R%0d=%0d | R%0d=%0d",
                     direccion1, read_data1,
                     direccion2, read_data2);

            verificar(read_data1, esperado1);
            verificar(read_data2, esperado2);
        end
    endtask

    initial begin
        $dumpfile("RegisterFile.vcd");
        $dumpvars(0, tb_RegisterFile);

        clk = 0;
        reset = 1;
        RegWrite = 0;
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;
        pruebas = 0;
        errores = 0;

        $display("=== Pruebas de RegisterFile ===");

        // 1. Reset sincronico: mantenerlo hasta un flanco positivo.
        @(posedge clk);
        #1;
        for (i = 0; i < 32; i = i + 1)
            verificar(uut.registers[i], 32'd0);

        reset = 0;
        $display("Reset inicial: 32 registros comprobados.");

        // 2. Escrituras y lecturas normales.
        escribir(5'd1, 32'd10);
        leer_y_verificar(5'd1, 5'd0, 32'd10, 32'd0);

        escribir(5'd2, 32'd20);
        leer_y_verificar(5'd1, 5'd2, 32'd10, 32'd20);

        escribir(5'd3, 32'd30);
        leer_y_verificar(5'd3, 5'd0, 32'd30, 32'd0);

        // 3. Intentar escribir en R0: debe seguir en cero.
        escribir(5'd0, 32'd999);
        leer_y_verificar(5'd0, 5'd1, 32'd0, 32'd10);
        verificar(uut.registers[0], 32'd0);

        // 4. RegWrite=0 debe impedir la escritura.
        @(negedge clk);
        RegWrite = 0;
        write_reg = 5'd2;
        write_data = 32'd777;

        @(posedge clk);
        #1;
        leer_y_verificar(5'd2, 5'd3, 32'd20, 32'd30);

        // 5. Comprobar el ultimo registro y los 32 bits.
        escribir(5'd31, 32'hDEADBEEF);
        leer_y_verificar(5'd31, 5'd0, 32'hDEADBEEF, 32'd0);

        // 6. La escritura no ocurre antes del flanco positivo.
        @(negedge clk);
        RegWrite = 1;
        write_reg = 5'd1;
        write_data = 32'd99;
        read_reg1 = 5'd1;

        #1;
        verificar(read_data1, 32'd10);

        @(posedge clk);
        #1;
        verificar(read_data1, 32'd99);
        RegWrite = 0;
        $display("Escritura sincronica: R1=%0d", read_data1);

        // 7. Cambiar direcciones sin esperar otro flanco.
        leer_y_verificar(5'd2, 5'd3, 32'd20, 32'd30);
        leer_y_verificar(5'd1, 5'd31, 32'd99, 32'hDEADBEEF);

        // 8. Reset tiene prioridad sobre RegWrite.
        @(negedge clk);
        reset = 1;
        RegWrite = 1;
        write_reg = 5'd3;
        write_data = 32'd555;

        @(posedge clk);
        #1;
        for (i = 0; i < 32; i = i + 1)
            verificar(uut.registers[i], 32'd0);

        reset = 0;
        RegWrite = 0;
        leer_y_verificar(5'd3, 5'd0, 32'd0, 32'd0);

        $display("=== Fin: pruebas=%0d, errores=%0d ===",
                 pruebas, errores);
        $finish;
    end

endmodule