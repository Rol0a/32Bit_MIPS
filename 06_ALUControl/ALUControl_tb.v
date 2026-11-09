// ALUControl_tb.v — Testbench del control de la ALU. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module ALUControl_tb;

    // ---- Módulo bajo prueba ----
    reg  [1:0] ALUOp;
    reg  [5:0] funct;
    wire [3:0] alu_control;

    ALUControl uut (.ALUOp(ALUOp), .funct(funct), .alu_control(alu_control));

    // ---- Casos de prueba ----
    // Cada caso pone ALUOp, funct y el alu_control esperado (de la tabla de ALUControl) e imprime 10 ns
    // después, con la salida ya asentada.
    reg  [3:0] esperado;
    wire       ok = (alu_control === esperado);   // === compara también la x

    initial begin
        $dumpfile("ALUControl_tb.vcd");
        $dumpvars(0, ALUControl_tb);

        ALUOp = 2'b10;  funct = 6'b100000;  esperado = 4'b0010;   // Caso 1: ADD
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b100010;  esperado = 4'b0110;   // Caso 2: SUB
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b011000;  esperado = 4'b1000;   // Caso 3: MULT
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b011010;  esperado = 4'b1001;   // Caso 4: DIV
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b100011;  esperado = 4'b0001;   // Caso 5: MOV
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        // En las tipo I, funct son los 6 bits bajos del inmediato de una instrucción de clase
        ALUOp = 2'b00;  funct = 6'b001111;  esperado = 4'b0000;   // Caso 6: MOVI (funct = bits de imm 15)
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b00;  funct = 6'b001010;  esperado = 4'b0000;   // Caso 7: ADDI con ALUOp=00 da MOVI
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b00;  funct = 6'b100000;  esperado = 4'b0000;   // Caso 8: ALUOp=00 ignora funct de ADD
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b111111;  esperado = 4'b1111;   // Caso 9: funct no definido
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b01;  funct = 6'b001010;  esperado = 4'b0010;   // Caso 10: ALUOp=01, ADDI (suma)
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b11;  funct = 6'b000100;  esperado = 4'b0110;   // Caso 11: ALUOp=11, SUBI (resta)
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b000000;  esperado = 4'b1111;   // Adicional: funct 000000 (palabra 0)
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b100100;  esperado = 4'b1111;   // Adicional: 100100 (SUB del enunciado)
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b10;  funct = 6'b100001;  esperado = 4'b1111;   // Adicional: 100001 (MUL del enunciado)
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b01;  funct = 6'b100010;  esperado = 4'b0010;   // Adicional: ADDI con funct de SUB
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'b11;  funct = 6'b100000;  esperado = 4'b0110;   // Adicional: SUBI con funct de ADD
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        ALUOp = 2'bxx;  funct = 6'b100000;  esperado = 4'b1111;   // Adicional: ALUOp x
        #10 $display("ALUOp=%b, funct=%b -> alu_control=%b  %0s", ALUOp, funct, alu_control, ok ? "OK" : "ERROR");

        $finish;
    end

endmodule
