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
    // Cada caso pone el opcode y las señales esperadas (RegDst_ALUSrc_RegWrite_Jump_ALUOp, de la tabla de
    // control) e imprime 10 ns después, con la salida ya asentada.
    reg  [5:0] esperado;
    wire       ok = ({RegDst, ALUSrc, RegWrite, Jump, ALUOp} === esperado);   // === compara también la x

    initial begin
        $dumpfile("ControlUnit_tb.vcd");
        $dumpvars(0, ControlUnit_tb);

        opcode = 6'b000000;  esperado = 6'b1_0_1_0_10;   // Caso 1: tipo R
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b001010;  esperado = 6'b0_1_1_0_00;   // Caso 2: tipo I, MOVI
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b001000;  esperado = 6'b0_1_1_0_01;   // Caso 3: tipo I, ADDI
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b001001;  esperado = 6'b0_1_1_0_11;   // Caso 3: tipo I, SUBI
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b000010;  esperado = 6'b0_0_0_1_00;   // Caso 4: tipo J
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b111111;  esperado = 6'b0_0_0_0_00;   // Caso 5: opcode no definido
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b000011;  esperado = 6'b0_0_0_0_00;   // Adicional: a 1 bit de JUMP
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b001011;  esperado = 6'b0_0_0_0_00;   // Adicional: a 1 bit de MOVI
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'bxxxxxx;  esperado = 6'b0_0_0_0_00;   // Adicional: opcode x (IMEM vacía)
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        // Caso 6: secuencia R -> J -> I; un valor arrastrado de la instrucción anterior daría ERROR
        opcode = 6'b000000;  esperado = 6'b1_0_1_0_10;   // R
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b000010;  esperado = 6'b0_0_0_1_00;   // J
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        opcode = 6'b001001;  esperado = 6'b0_1_1_0_11;   // I (SUBI)
        #10 $display("opcode=%b -> RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b  %0s", opcode, RegDst, ALUSrc, RegWrite, Jump, ALUOp, ok ? "OK" : "ERROR");

        $finish;
    end

endmodule
