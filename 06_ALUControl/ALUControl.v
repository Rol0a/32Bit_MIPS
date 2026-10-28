`timescale 1ns/1ns

// Decodifica la operacion solicitada.
// Los codigos funct siguen exactamente la tabla de la tarea.
// ALUOp 01 (ADDI) y 11 (SUBI) son decision del grupo: la tabla de
// la tarea solo define 00 (MOVI) y 10 (tipo R).
module ALUControl (
    input  wire [1:0] ALUOp,
    input  wire [5:0] funct,
    output reg  [3:0] alu_control
);

    // Logica combinacional: responde a cambios en las entradas.
    always @(*) begin
        case (ALUOp)

            // MOVI: el campo funct no afecta esta seleccion.
            2'b00: alu_control = 4'b0000;

            // ADDI: suma el registro con el inmediato.
            // Como en MOVI, funct se ignora: son bits del inmediato.
            2'b01: alu_control = 4'b0010;

            // Instrucciones tipo R: decodificar funct.
            2'b10: begin
                case (funct)
                    6'b100000: alu_control = 4'b0010; // ADD
                    6'b100100: alu_control = 4'b0110; // SUB
                    6'b100001: alu_control = 4'b1000; // MULT
                    6'b100010: alu_control = 4'b1001; // DIV
                    6'b100011: alu_control = 4'b0001; // MOV

                    // Combinacion no definida en la tabla.
                    // La ALU devuelve 0 con este codigo.
                    default: alu_control = 4'b1111;
                endcase
            end

            // SUBI: resta el inmediato al registro.
            // Como en MOVI, funct se ignora: son bits del inmediato.
            2'b11: alu_control = 4'b0110;

            // Los cuatro valores de ALUOp ya estan cubiertos: solo se
            // llega aqui si ALUOp trae x o z. Evita latches y valores x.
            default: alu_control = 4'b1111;

        endcase
    end

endmodule