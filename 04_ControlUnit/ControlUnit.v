// ControlUnit.v — Unidad de control: opcode -> señales de control. Combinacional.
// Especificación y decisiones: README.md de esta carpeta.
`timescale 1ns / 1ps

module ControlUnit (
    input      [5:0] opcode,     // instruction[31:26]
    output reg       RegDst,     // 1 = escribe en rd (tipo R); 0 = en rt (tipo I)
    output reg       ALUSrc,     // 1 = src2 de la ALU es el inmediato
    output reg       RegWrite,   // 1 = escribe el resultado en el banco
    output reg       Jump,       // 1 = PC = address
    output reg [1:0] ALUOp       // clase de operación para ALUControl
);

    always @(*) begin
        // Por defecto no escribe ni salta. Van antes del case para que una señal
        // que una rama no toca no quede en latch o en x.
        RegDst   = 1'b0;
        ALUSrc   = 1'b0;
        RegWrite = 1'b0;
        Jump     = 1'b0;
        ALUOp    = 2'b00;

        case (opcode)
            6'b000000: begin RegDst = 1'b1; RegWrite = 1'b1; ALUOp = 2'b10; end  // tipo R: rd = rs (funct) rt
            6'b001010: begin ALUSrc = 1'b1; RegWrite = 1'b1; end                 // MOVI: rt = imm
            6'b001000: begin ALUSrc = 1'b1; RegWrite = 1'b1; ALUOp = 2'b01; end  // ADDI: rt = rs + imm
            6'b001001: begin ALUSrc = 1'b1; RegWrite = 1'b1; ALUOp = 2'b11; end  // SUBI: rt = rs - imm
            6'b000010: begin Jump = 1'b1; end                                    // JUMP: PC = address
            default: ;                                                           // no definido o x: NOP
        endcase
    end

endmodule
