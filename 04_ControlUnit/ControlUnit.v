// =============================================================================
// ControlUnit.v — Unidad de Control
// Decodifica el opcode de la instrucción y genera las señales que controlan el
// resto del procesador. Lógica combinacional: no tiene reloj ni estado.
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module ControlUnit (
    input      [5:0] opcode,     // instruction[31:26]
    output reg       RegDst,     // 1 = se escribe en rd (tipo R); 0 = en rt (tipo I)
    output reg       ALUSrc,     // 1 = el segundo operando de la ALU es el inmediato
    output reg       RegWrite,   // 1 = escribe el resultado en el banco de registros
    output reg       Jump,       // 1 = salto incondicional: PC = address
    output reg [1:0] ALUOp       // clase de operación para ALUControl
);

    // Las salidas son reg solo porque se asignan dentro de un always; no
    // guardan nada entre ciclos. always @(*) se reevalúa en cuanto cambia el
    // opcode.
    always @(*) begin
        // Valores por defecto: el estado «seguro», que no escribe registros ni
        // salta. Se asignan TODAS las salidas antes del case para que cada rama
        // solo cambie las señales que necesita: una salida que una rama no toca
        // conserva este valor, en vez de quedar en latch o en x (por ejemplo
        // Jump en R e I, o RegWrite en J). Un opcode no definido se queda con
        // estos valores.
        RegDst   = 1'b0;
        ALUSrc   = 1'b0;
        RegWrite = 1'b0;
        Jump     = 1'b0;
        ALUOp    = 2'b00;

        // Señales de cada rama, en el orden RegDst ALUSrc RegWrite Jump ALUOp.
        case (opcode)

            // Tipo R (ADD, SUB, MUL, DIV, MOV): opera dos registros y escribe
            // en rd. La operación concreta está en funct, que decodifica
            // ALUControl.                                       1 0 1 0 10
            6'b000000: begin
                RegDst   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
            end

            // MOVI: escribe el inmediato en rt. ALUOp 00 hace que la ALU
            // deje pasar src2, que es el inmediato.             0 1 1 0 00
            6'b001010: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
            end

            // ADDI: rt = rs + inmediato. ALUOp 01 pide una suma (decisión
            // del grupo: el enunciado solo define 00 y 10).     0 1 1 0 01
            6'b001000: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 2'b01;
            end

            // SUBI: rt = rs - inmediato. ALUOp 11 pide una resta
            // (decisión del grupo).                             0 1 1 0 11
            6'b001001: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 2'b11;
            end

            // JUMP: solo cambia el PC. No escribe registros; RegDst, ALUSrc
            // y ALUOp no afectan el resultado, así que se dejan en 0 (los
            // valores por defecto) en vez de x.                 0 0 0 1 00
            6'b000010: begin
                Jump     = 1'b1;
            end

            // Opcode no definido, o con bits x/z (por ejemplo, una palabra
            // de la IMEM sin instrucción): se quedan los valores por
            // defecto. El procesador no escribe ni salta.       0 0 0 0 00
            default: ;

        endcase
    end

endmodule
