// ControlUnit_tb.v — Testbench de la unidad de control. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module ControlUnit_tb;

    // ---- Módulo bajo prueba ----
    reg  [5:0] opcode;
    wire       RegDst, ALUSrc, RegWrite, Jump;
    wire [1:0] ALUOp;

    ControlUnit uut (
        .opcode  (opcode),
        .RegDst  (RegDst),
        .ALUSrc  (ALUSrc),
        .RegWrite(RegWrite),
        .Jump    (Jump),
        .ALUOp   (ALUOp)
    );

    // ---- Casos de prueba ----
    initial begin
        $dumpfile("ControlUnit_tb.vcd");
        $dumpvars(0, ControlUnit_tb);

        //     opcode     RegDst_ALUSrc_RegWrite_Jump_ALUOp
        probar(6'b000000, 6'b1_0_1_0_10, "Caso 1: tipo R");
        probar(6'b001010, 6'b0_1_1_0_00, "Caso 2: tipo I, MOVI");
        probar(6'b001000, 6'b0_1_1_0_01, "Caso 3: tipo I, ADDI");
        probar(6'b001001, 6'b0_1_1_0_11, "Caso 3: tipo I, SUBI");
        probar(6'b000010, 6'b0_0_0_1_00, "Caso 4: tipo J");
        probar(6'b111111, 6'b0_0_0_0_00, "Caso 5: opcode no definido");
        probar(6'b000011, 6'b0_0_0_0_00, "Adicional: a 1 bit de JUMP");
        probar(6'b001011, 6'b0_0_0_0_00, "Adicional: a 1 bit de MOVI");
        probar(6'bxxxxxx, 6'b0_0_0_0_00, "Adicional: opcode x (IMEM vacia)");

        // Secuencia R -> J -> I: un valor arrastrado de la instrucción anterior daría ERROR
        probar(6'b000000, 6'b1_0_1_0_10, "Caso 6: secuencia, R");
        probar(6'b000010, 6'b0_0_0_1_00, "Caso 6: secuencia, J");
        probar(6'b001001, 6'b0_1_1_0_11, "Caso 6: secuencia, I (SUBI)");

        $finish;
    end

    // ---- Impresión de resultados ----

    // === compara también la x.
    task probar(input [5:0] op, esperado, input [8*40:1] caso);
        begin
            opcode = op;
            #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | esperado=%b %b %b %b %b  %s  %0s",
                         opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp,
                         esperado[5], esperado[4], esperado[3], esperado[2], esperado[1:0],
                         ({RegDst, ALUSrc, RegWrite, Jump, ALUOp} === esperado) ? "OK   " : "ERROR", caso);
        end
    endtask

endmodule
