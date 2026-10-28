// =============================================================================
// RegisterFile.v — Banco de Registros
// 32 registros de 32 bits con dos puertos de lectura y uno de escritura.
// Lectura asíncrona, escritura síncrona en el flanco de subida y $0 siempre
// en 0.
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module RegisterFile (
    input         clk,           // reloj del sistema
    input         reset,         // reinicio síncrono, activo en alto
    input         RegWrite,      // 1 = escribe write_data en write_reg
    input  [4:0]  read_reg1,     // registro que se lee por el puerto 1 (rs)
    input  [4:0]  read_reg2,     // registro que se lee por el puerto 2 (rt)
    input  [4:0]  write_reg,     // registro destino (rd o rt)
    input  [31:0] write_data,    // dato que se escribe (resultado de la ALU)
    output [31:0] read_data1,    // contenido de read_reg1
    output [31:0] read_data2     // contenido de read_reg2
);

    // 32 registros de 32 bits: registers[5] es $5. Las direcciones tienen 5
    // bits porque 2^5 = 32.
    reg [31:0] registers [0:31];
    integer i;

    // Lectura asíncrona: assign es una conexión continua, no espera al reloj.
    // En cuanto cambia read_reg1/read_reg2, o el contenido del registro
    // leído, la salida cambia en ese mismo instante. Así los operandos llegan
    // a la ALU dentro del mismo ciclo. Los dos puertos son independientes.
    // Protección 1 de $0: leerlo devuelve 0 sin consultar el arreglo, aunque
    // el arreglo tenga x (antes del primer reset).
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 : registers[read_reg2];

    // Escritura y reset síncronos: el contenido solo cambia en el flanco de
    // subida. Se usa <= (no bloqueante) porque es lógica secuencial: en el
    // mismo flanco el PC avanza, y el banco debe guardar el resultado de la
    // instrucción que termina, no el de la siguiente.
    always @(posedge clk) begin
        if (reset) begin
            // Reset síncrono, igual que el PC: los 32 registros pasan a 0 en
            // el flanco, con prioridad sobre RegWrite. Hasta ese primer flanco
            // con reset = 1 los registros valen x.
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end
        else begin
            // Protección 3 de $0: el valor interno se mantiene en 0, así
            // también se ve 0 en uut.registers[0] y en GTKWave.
            registers[0] <= 32'd0;

            // Protección 2 de $0: solo se escribe si RegWrite = 1 y el
            // destino no es $0. Con RegWrite = 0 el banco conserva su
            // contenido aunque write_reg y write_data cambien.
            if (RegWrite && (write_reg != 5'd0))
                registers[write_reg] <= write_data;
        end
    end

endmodule
