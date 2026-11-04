// RegisterFile.v — Banco de 32 registros de 32 bits: dos puertos de lectura y uno de escritura.
// Especificación y decisiones: README.md de esta carpeta.
`timescale 1ns / 1ps

module RegisterFile (
    input         clk,
    input         reset,         // síncrono, activo en alto; prioridad sobre RegWrite
    input         RegWrite,      // 1 = escribe write_data en write_reg
    input  [4:0]  read_reg1,     // rs
    input  [4:0]  read_reg2,     // rt
    input  [4:0]  write_reg,     // rd o rt
    input  [31:0] write_data,    // resultado de la ALU
    output [31:0] read_data1,    // contenido de read_reg1
    output [31:0] read_data2     // contenido de read_reg2
);

    reg [31:0] registers [0:31];
    integer i;

    // Lectura asíncrona; $0 lee 0 sin consultar el arreglo.
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 : registers[read_reg2];

    // Escritura síncrona; $0 nunca se escribe.
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end
        else begin
            registers[0] <= 32'd0;
            if (RegWrite && (write_reg != 5'd0))
                registers[write_reg] <= write_data;
        end
    end

endmodule
