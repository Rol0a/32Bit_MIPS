// PC.v — Program Counter: registro con la dirección de la instrucción actual.
// Especificación y decisiones: README.md de esta carpeta.
`timescale 1ns / 1ps

module PC (
    input             clk,
    input             reset,       // síncrono, activo en alto
    input      [31:0] next_pc,     // dirección siguiente
    output reg [31:0] current_pc   // dirección actual
);

    // Solo cambia en el flanco de subida: la dirección queda estable todo el ciclo.
    always @(posedge clk) begin
        if (reset)
            current_pc <= 32'd0;
        else
            current_pc <= next_pc;
    end

endmodule
