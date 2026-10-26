`timescale 1ns/1ns

module RegisterFile (
    input wire clk,
    input wire reset,
    input wire RegWrite,
    input wire [4:0] read_reg1,
    input wire [4:0] read_reg2,
    input wire [4:0] write_reg,
    input wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    // 32 registros, cada uno de 32 bits.
    reg [31:0] registers [0:31];
    integer i;

    // Lectura asincrona: no necesita un flanco del reloj.
    // Leer el registro cero siempre devuelve cero.
    assign read_data1 = (read_reg1 == 5'd0)
                      ? 32'd0 : registers[read_reg1];

    assign read_data2 = (read_reg2 == 5'd0)
                      ? 32'd0 : registers[read_reg2];

    // Reset y escritura sincronos.
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end
        else begin
            registers[0] <= 32'd0;

            // Solo escribir si esta habilitado y no es R0.
            if (RegWrite && (write_reg != 5'd0)) begin
                registers[write_reg] <= write_data;
            end
        end
    end

endmodule