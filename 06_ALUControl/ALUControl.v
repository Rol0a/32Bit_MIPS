// =============================================================================
// ALUControl.v — Control de la ALU
// Traduce ALUOp (de la Unidad de Control) y el campo funct (de las tipo R) en
// el código de 4 bits que elige la operación de la ALU. Lógica combinacional:
// no tiene reloj ni estado.
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module ALUControl (
    input      [1:0] ALUOp,          // clase de operación, de la Unidad de Control
    input      [5:0] funct,          // instruction[5:0]: solo cuenta en tipo R
    output reg [3:0] alu_control     // operación para la ALU
);

    // Codificación. Las filas 00 y 10 son la tabla del enunciado; 01 y 11 son
    // decisión del grupo (el enunciado no las define):
    //   ALUOp  funct    instrucción   alu_control
    //   00     x        MOVI          0000   pasa el inmediato
    //   01     x        ADDI          0010   suma
    //   10     100000   ADD           0010
    //   10     100100   SUB           0110
    //   10     100001   MULT          1000
    //   10     100010   DIV           1001
    //   10     100011   MOV           0001
    //   10     otro     no definido   1111   la ALU devuelve 0
    //   11     x        SUBI          0110   resta
    //
    // alu_control es reg solo porque se asigna dentro de un always; no guarda
    // nada entre ciclos. always @(*) se reevalúa en cuanto cambia una entrada.
    always @(*) begin
        // Valor por defecto: 1111, «no definido». Se asigna antes del case para
        // que todos los caminos den un valor: así no se infiere un latch y una
        // combinación no cubierta (funct no definido, o ALUOp con x/z) no deja
        // la salida en x. 1111 no es ninguna operación: la ALU devuelve 0.
        alu_control = 4'b1111;

        case (ALUOp)

            // MOVI: la ALU deja pasar src2, que es el inmediato. funct no
            // importa: en una tipo I esos 6 bits son la parte baja del
            // inmediato y pueden valer cualquier cosa.
            2'b00: alu_control = 4'b0000;

            // ADDI: rs + inmediato, con el mismo código que ADD. funct se
            // ignora, como en MOVI. Si ADDI usara 00, la ALU haría MOVI.
            2'b01: alu_control = 4'b0010;

            // Tipo R: todas comparten el opcode 000000, así que la operación
            // concreta sale de funct.
            2'b10: begin
                case (funct)
                    6'b100000: alu_control = 4'b0010;   // ADD
                    6'b100100: alu_control = 4'b0110;   // SUB
                    6'b100001: alu_control = 4'b1000;   // MULT
                    6'b100010: alu_control = 4'b1001;   // DIV
                    6'b100011: alu_control = 4'b0001;   // MOV

                    // funct no definido: se queda el 1111 por defecto.
                    default: ;
                endcase
            end

            // SUBI: rs - inmediato, con el mismo código que SUB. funct se
            // ignora, como en MOVI.
            2'b11: alu_control = 4'b0110;

            // Los cuatro valores de ALUOp ya están cubiertos: solo se llega
            // aquí si ALUOp trae x o z. Se queda el 1111 por defecto.
            default: ;

        endcase
    end

endmodule
