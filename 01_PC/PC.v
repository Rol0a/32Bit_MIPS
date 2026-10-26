// =============================================================================
// PC.v — Program Counter
// Registro de 32 bits que guarda la dirección de la instrucción actual.
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module PC (
    input             clk,         // reloj
    input             reset,       // reinicia el PC a 0 (activo en alto)
    input      [31:0] next_pc,     // dirección siguiente
    output reg [31:0] current_pc   // dirección actual
);

    // El PC es un registro: solo cambia en el flanco de subida del reloj, así
    // la dirección actual se mantiene estable durante todo el ciclo mientras
    // la IMEM lee la instrucción.
    // - reset = 1 -> vuelve a la dirección 0 (inicio del programa).
    // - reset = 0 -> carga la dirección siguiente que le llega por next_pc.
    // El reset es síncrono (se evalúa en el flanco), por eso current_pc vale x
    // hasta el primer flanco de subida. Se usa <= (no bloqueante) porque es
    // lógica secuencial.
    always @(posedge clk) begin
        if (reset)
            current_pc <= 32'd0;
        else
            current_pc <= next_pc;
    end

endmodule
