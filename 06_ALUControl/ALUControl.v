// ALUControl.v — Control de la ALU: ALUOp + funct -> operación de la ALU. Combinacional.
// Especificación y decisiones: README.md de esta carpeta.
`timescale 1ns / 1ps

module ALUControl (
    input      [1:0] ALUOp,          // clase de operación, de ControlUnit
    input      [5:0] funct,          // instruction[5:0]: solo cuenta en tipo R
    output reg [3:0] alu_control     // operación para la ALU
);

    always @(*) begin
        // Por defecto 1111, «no definido»: la ALU devuelve 0. Va antes del case
        // para que ninguna combinación deje la salida en latch o en x.
        alu_control = 4'b1111;

        case (ALUOp)
            2'b00: alu_control = 4'b0000;               // MOVI: pasa el inmediato
            2'b01: alu_control = 4'b0010;               // ADDI: suma
            2'b10: begin                                // tipo R: la operación sale de funct
                case (funct)
                    6'b100000: alu_control = 4'b0010;   // ADD
                    6'b100010: alu_control = 4'b0110;   // SUB
                    6'b011000: alu_control = 4'b1000;   // MUL
                    6'b011010: alu_control = 4'b1001;   // DIV
                    6'b100011: alu_control = 4'b0001;   // MOV
                    default: ;                          // funct no definido: queda 1111
                endcase
            end
            2'b11: alu_control = 4'b0110;               // SUBI: resta
            default: ;                                  // ALUOp con x/z: queda 1111
        endcase
    end

endmodule
