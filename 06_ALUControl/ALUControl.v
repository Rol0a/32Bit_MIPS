`timescale 1ns/1ns

// Decodifica la operacion solicitada.
// Los codigos funct siguen exactamente la tabla de la tarea.
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

            // Instrucciones tipo R: decodificar funct.
            2'b10: begin
                case (funct)
                    6'b100000: alu_control = 4'b0010; // ADD
                    6'b100100: alu_control = 4'b0110; // SUB
                    6'b100001: alu_control = 4'b1000; // MULT
                    6'b100010: alu_control = 4'b1001; // DIV
                    6'b100011: alu_control = 4'b0001; // MOV

                    // Combinacion no definida en la tabla.
                    default: alu_control = 4'b1111;
                endcase
            end

            // ALUOp no definido en la tabla.
            default: alu_control = 4'b1111;

        endcase
    end

endmodule