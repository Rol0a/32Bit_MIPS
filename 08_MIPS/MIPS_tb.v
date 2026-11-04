// MIPS_tb.v — Testbench del procesador completo: ejecuta el programa de clase, imprime una línea
// por instrucción y al final los 32 registros. Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module MIPS_tb;

    // ---- Módulo bajo prueba ----
    reg         clk   = 0;
    reg         reset = 1;
    wire [31:0] current_pc, instruction, alu_result;

    MIPS uut (
        .clk        (clk),
        .reset      (reset),
        .current_pc (current_pc),
        .instruction(instruction),
        .alu_result (alu_result)
    );

    always #5 clk = ~clk;   // periodo de 10 ns: flancos de subida en t = 5, 15, 25, ...

    // Registros del programa: $dumpvars no vuelca arreglos, así se ven en GTKWave
    wire [31:0] R1  = uut.rf.registers[1],  R2  = uut.rf.registers[2],  R3  = uut.rf.registers[3],  R4  = uut.rf.registers[4];
    wire [31:0] R5  = uut.rf.registers[5],  R6  = uut.rf.registers[6],  R7  = uut.rf.registers[7],  R8  = uut.rf.registers[8];
    wire [31:0] R9  = uut.rf.registers[9],  R10 = uut.rf.registers[10], R11 = uut.rf.registers[11], R12 = uut.rf.registers[12];
    wire [31:0] R13 = uut.rf.registers[13], R14 = uut.rf.registers[14], R15 = uut.rf.registers[15], R16 = uut.rf.registers[16];
    wire [31:0] R17 = uut.rf.registers[17], R18 = uut.rf.registers[18], R19 = uut.rf.registers[19], R20 = uut.rf.registers[20];

    // ---- Casos de prueba ----
    integer i;
    reg [31:0] banco_esperado [0:31];

    initial begin
        $dumpfile("MIPS_tb.vcd");
        $dumpvars(0, MIPS_tb);

        // Estado final, calculado a mano. $18 a $31 quedan en 0: JUMP 1024 salta las instrucciones 23 a 26.
        for (i = 0; i < 32; i = i + 1)
            banco_esperado[i] = 0;
        banco_esperado[1]  = 25;   banco_esperado[2]  = 16;   banco_esperado[3]  = 45;    banco_esperado[4]  = 25;
        banco_esperado[5]  = 2;    banco_esperado[6]  = 35;   banco_esperado[7]  = 35;    banco_esperado[8]  = 1000;
        banco_esperado[9]  = 2;    banco_esperado[10] = 40;   banco_esperado[11] = 70;    banco_esperado[12] = 20;
        banco_esperado[13] = -25;  banco_esperado[14] = 100;  banco_esperado[15] = 125;   banco_esperado[16] = 2000;
        banco_esperado[17] = 26;

        // El primer flanco con reset = 1 pone el PC y los 32 registros en 0
        @(posedge clk);
        #1 reset = 0;

        // 26 ciclos, uno por instrucción (monociclo): 22 para las instrucciones 1 a 22, y 4 más en
        // PC 1024 a 1027, los turnos de las instrucciones 23 a 26, para ver que tras JUMP 1024 el PC
        // sigue avanzando y ningún registro cambia (fuera de la IMEM se lee 0, una NOP).
        //
        //         PC    instrucción   RegDst_ALUSrc_RegWrite_Jump_ALUOp
        //                                           alu_control
        //                                                    rd1   rd2   ALU  dest next_pc
        ciclo_cpu(   0, 32'h2801000F, 6'b0_1_1_0_00, 4'b0000,    0,    0,    15,  1,    1, "#1  MOVI $1, 15");
        ciclo_cpu(   1, 32'h28020014, 6'b0_1_1_0_00, 4'b0000,    0,    0,    20,  2,    2, "#2  MOVI $2, 20");
        ciclo_cpu(   2, 32'h28030032, 6'b0_1_1_0_00, 4'b0000,    0,    0,    50,  3,    3, "#3  MOVI $3, 50");
        ciclo_cpu(   3, 32'h28040005, 6'b0_1_1_0_00, 4'b0000,    0,    0,     5,  4,    4, "#4  MOVI $4, 5");
        ciclo_cpu(   4, 32'h28050002, 6'b0_1_1_0_00, 4'b0000,    0,    0,     2,  5,    5, "#5  MOVI $5, 2");
        ciclo_cpu(   5, 32'h00223020, 6'b1_0_1_0_10, 4'b0010,   15,   20,    35,  6,    6, "#6  ADD $6, $1, $2");
        ciclo_cpu(   6, 32'h00613822, 6'b1_0_1_0_10, 4'b0110,   50,   15,    35,  7,    7, "#7  SUB $7, $3, $1");
        ciclo_cpu(   7, 32'h00434018, 6'b1_0_1_0_10, 4'b1000,   20,   50,  1000,  8,    8, "#8  MUL $8, $2, $3");
        ciclo_cpu(   8, 32'h0062481A, 6'b1_0_1_0_10, 4'b1001,   50,   20,     2,  9,    9, "#9  DIV $9, $3, $2");
        ciclo_cpu(   9, 32'h2021000A, 6'b0_1_1_0_01, 4'b0010,   15,   15,    25,  1,   10, "#10 ADDI $1, $1, 10");
        ciclo_cpu(  10, 32'h24420004, 6'b0_1_1_0_11, 4'b0110,   20,   20,    16,  2,   11, "#11 SUBI $2, $2, 4");
        ciclo_cpu(  11, 32'h00C45020, 6'b1_0_1_0_10, 4'b0010,   35,    5,    40, 10,   12, "#12 ADD $10, $6, $4");
        ciclo_cpu(  12, 32'h00C55818, 6'b1_0_1_0_10, 4'b1000,   35,    2,    70, 11,   13, "#13 MUL $11, $6, $5");
        ciclo_cpu(  13, 32'h0145601A, 6'b1_0_1_0_10, 4'b1001,   40,    2,    20, 12,   14, "#14 DIV $12, $10, $5");
        ciclo_cpu(  14, 32'h20840014, 6'b0_1_1_0_01, 4'b0010,    5,    5,    25,  4,   15, "#15 ADDI $4, $4, 20");
        ciclo_cpu(  15, 32'h00836822, 6'b1_0_1_0_10, 4'b0110,   25,   50,   -25, 13,   16, "#16 SUB $13, $4, $3");
        ciclo_cpu(  16, 32'h280E0064, 6'b0_1_1_0_00, 4'b0000,    0,    0,   100, 14,   17, "#17 MOVI $14, 100");
        ciclo_cpu(  17, 32'h01C17820, 6'b1_0_1_0_10, 4'b0010,  100,   25,   125, 15,   18, "#18 ADD $15, $14, $1");
        ciclo_cpu(  18, 32'h24630005, 6'b0_1_1_0_11, 4'b0110,   50,   50,    45,  3,   19, "#19 SUBI $3, $3, 5");
        ciclo_cpu(  19, 32'h01E28018, 6'b1_0_1_0_10, 4'b1000,  125,   16,  2000, 16,   20, "#20 MUL $16, $15, $2");
        ciclo_cpu(  20, 32'h20310001, 6'b0_1_1_0_01, 4'b0010,   25,    0,    26, 17,   21, "#21 ADDI $17, $1, 1");
        ciclo_cpu(  21, 32'h08000400, 6'b0_0_0_1_00, 4'b0000,    0,    0,     0,  0, 1024, "#22 JUMP 1024");
        ciclo_cpu(1024, 32'h00000000, 6'b1_0_1_0_10, 4'b1111,    0,    0,     0,  0, 1025, "NOP (fuera de la IMEM)");
        ciclo_cpu(1025, 32'h00000000, 6'b1_0_1_0_10, 4'b1111,    0,    0,     0,  0, 1026, "NOP (fuera de la IMEM)");
        ciclo_cpu(1026, 32'h00000000, 6'b1_0_1_0_10, 4'b1111,    0,    0,     0,  0, 1027, "NOP (fuera de la IMEM)");
        ciclo_cpu(1027, 32'h00000000, 6'b1_0_1_0_10, 4'b1111,    0,    0,     0,  0, 1028, "NOP (fuera de la IMEM)");

        // Tras el último flanco, los 32 registros contra su valor final
        @(posedge clk); #1;
        for (i = 0; i < 32; i = i + 1)
            imprimir(uut.rf.registers[i] === banco_esperado[i], i, uut.rf.registers[i], "registro final");

        #4 $finish;
    end

    // ---- Impresión de resultados ----

    // En el flanco de bajada la lógica ya se asentó: compara el ciclo con lo esperado.
    task ciclo_cpu(input [31:0] pc_esp, instr_esp, input [5:0] ctl_esp, input [3:0] aluc_esp,
                   input [31:0] rd1_esp, rd2_esp, alu_esp, input [4:0] wreg_esp,
                   input [31:0] next_esp, input [8*24:1] caso);
        reg ok;
        begin
            @(negedge clk);
            ok = {current_pc, instruction, uut.RegDst, uut.ALUSrc, uut.RegWrite, uut.Jump, uut.ALUOp, uut.alu_control,
                  uut.read_data1, uut.read_data2, alu_result, uut.zero, uut.write_reg, uut.next_pc}
             === {pc_esp, instr_esp, ctl_esp, aluc_esp, rd1_esp, rd2_esp, alu_esp, alu_esp == 32'd0, wreg_esp, next_esp};
            imprimir(ok, uut.write_reg, uut.write_data, caso);
        end
    endtask

    task imprimir(input ok, input [4:0] r, input [31:0] valor, input [8*24:1] caso);
        $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %s  %0s",
                 current_pc, instruction, uut.RegDst, uut.ALUSrc, uut.RegWrite, uut.Jump, uut.ALUOp,
                 $signed(uut.read_data1), $signed(uut.read_data2), $signed(alu_result),
                 r, $signed(valor), ok ? "OK   " : "ERROR", caso);
    endtask

endmodule
