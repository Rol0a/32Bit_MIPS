// =============================================================================
// ALU.v — Unidad Aritmético-Lógica
// Suma, resta, multiplica o divide dos operandos de 32 bits según alu_control,
// e indica con zero si el resultado es 0. Lógica combinacional: no tiene reloj
// ni estado. Todas las operaciones son con signo (complemento a 2).
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module ALU (
    input      [31:0] src1,          // primer operando: read_data1 ($rs)
    input      [31:0] src2,          // segundo operando: read_data2 ($rt) o inmediato
    input      [3:0]  alu_control,   // operación, generada por ALUControl
    output reg [31:0] result,        // resultado: va a write_data del banco
    output            zero           // 1 cuando result == 0
);

    // Codificación de alu_control: la misma que genera ALUControl, para que la
    // ALU no cambie al integrarla.
    //   0000  result = src2            MOVI: pasa el inmediato
    //   0001  result = src1            MOV: pasa el registro
    //   0010  result = src1 + src2     ADD, ADDI
    //   0110  result = src1 - src2     SUB, SUBI
    //   1000  result = src1 * src2     MUL
    //   1001  result = src1 / src2     DIV (con signo; entre cero da 0)
    //   otro  result = 0               control no definido (p. ej. 1111)
    //
    // result es reg solo porque se asigna dentro de un always; no guarda nada
    // entre ciclos. always @(*) se reevalúa en cuanto cambia una entrada.
    always @(*) begin
        // Valor por defecto: 0. Es lo que devuelve un control no definido y la
        // división entre cero. Al asignarlo antes del case, result tiene valor
        // en todos los caminos y no se infiere un latch.
        result = 32'd0;

        case (alu_control)

            // MOVI: el segundo operando es el inmediato extendido con signo;
            // src1 se ignora.
            4'b0000: result = src2;

            // MOV: copia el registro rs; src2 se ignora.
            4'b0001: result = src1;

            // Suma y resta: en complemento a 2 los bits del resultado son los
            // mismos con o sin signo, así que no hace falta $signed. Un
            // desborde da la vuelta (módulo 2^32): 0xFFFFFFFF + 1 = 0.
            4'b0010: result = src1 + src2;
            4'b0110: result = src1 - src2;

            // Multiplicación: el producto completo tiene 64 bits y se guardan
            // los 32 bajos, que tampoco dependen del signo:
            // 65536 * 65536 = 2^32 se trunca a 0.
            4'b1000: result = src1 * src2;

            // División con signo, truncada hacia cero (-7 / 2 = -3). Aquí el
            // signo sí cambia el resultado: sin $signed, -20 / 4 daría
            // 1073741819. Entre cero, Icarus devuelve x; el if lo evita y
            // result se queda en 0. No se escribe con ?: porque
            // (src2 == 0) ? 32'd0 : $signed(...) / $signed(...) divide sin
            // signo: el literal 32'd0 es sin signo y anula los $signed.
            4'b1001: begin
                if (src2 != 32'd0)
                    result = $signed(src1) / $signed(src2);
            end

            // Control no definido (1111 de ALUControl, o un código con bits
            // x/z): se queda el valor por defecto, 0, en vez de propagar x.
            default: ;

        endcase
    end

    // zero no depende de alu_control: sube con cualquier resultado 0, también
    // con los de la división entre cero y del control no definido.
    assign zero = (result == 32'd0);

endmodule
