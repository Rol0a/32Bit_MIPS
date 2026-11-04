// ALU.v — Unidad aritmético-lógica de 32 bits con signo (complemento a 2). Combinacional.
// Especificación y decisiones: README.md de esta carpeta.
`timescale 1ns / 1ps

module ALU (
    input      [31:0] src1,          // $rs
    input      [31:0] src2,          // $rt o inmediato
    input      [3:0]  alu_control,   // operación, de ALUControl
    output reg [31:0] result,        // va a write_data del banco
    output            zero           // 1 cuando result == 0
);

    always @(*) begin
        // Por defecto 0: lo que dan un control no definido y la división entre cero.
        result = 32'd0;

        case (alu_control)
            4'b0000: result = src2;              // MOVI
            4'b0001: result = src1;              // MOV
            4'b0010: result = src1 + src2;       // ADD, ADDI
            4'b0110: result = src1 - src2;       // SUB, SUBI
            4'b1000: result = src1 * src2;       // MUL: 32 bits bajos
            4'b1001: begin                       // DIV con signo, truncada hacia cero
                // No usar ?: aquí: el literal 32'd0 sin signo anula los $signed.
                if (src2 != 32'd0)
                    result = $signed(src1) / $signed(src2);
            end
            default: ;                           // no definido (1111, x): queda 0
        endcase
    end

    assign zero = (result == 32'd0);

endmodule
