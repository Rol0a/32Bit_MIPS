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

    // Registros del programa: $dumpvars no vuelca arreglos, así se ven en GTKWave. signed: %d imprime el signo
    wire signed [31:0] R1  = uut.rf.registers[1],  R2  = uut.rf.registers[2],  R3  = uut.rf.registers[3],  R4  = uut.rf.registers[4];
    wire signed [31:0] R5  = uut.rf.registers[5],  R6  = uut.rf.registers[6],  R7  = uut.rf.registers[7],  R8  = uut.rf.registers[8];
    wire signed [31:0] R9  = uut.rf.registers[9],  R10 = uut.rf.registers[10], R11 = uut.rf.registers[11], R12 = uut.rf.registers[12];
    wire signed [31:0] R13 = uut.rf.registers[13], R14 = uut.rf.registers[14], R15 = uut.rf.registers[15], R16 = uut.rf.registers[16];
    wire signed [31:0] R17 = uut.rf.registers[17], R18 = uut.rf.registers[18], R19 = uut.rf.registers[19], R20 = uut.rf.registers[20];

    // Señales internas que se imprimen en cada ciclo, con el nombre de su columna en la consola
    wire               RegDst = uut.RegDst, ALUSrc = uut.ALUSrc, RegWrite = uut.RegWrite, Jump = uut.Jump;
    wire        [1:0]  ALUOp       = uut.ALUOp;
    wire        [3:0]  alu_control = uut.alu_control;
    wire signed [31:0] rd1 = uut.read_data1, rd2 = uut.read_data2, alu = alu_result, wdata = uut.write_data;
    wire        [4:0]  wreg        = uut.write_reg;
    wire        [31:0] next_pc     = uut.next_pc;

    // ---- Casos de prueba ----
    // Cada ciclo pone en esperado sus valores calculados a mano (Arquitectura §7) y lo imprime en el flanco
    // de bajada, cuando la lógica ya se asentó. ok compara el ciclo completo; zero debe valer 1 solo si el
    // resultado de la ALU es 0. === compara también la x.
    reg  [206:0] esperado;
    wire         ok = ({current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, alu_control, rd1, rd2, alu, wreg, next_pc} === esperado)
                      && (uut.zero === (alu == 0));
    integer      i;

    initial begin
        $dumpfile("MIPS_tb.vcd");
        $dumpvars(0, MIPS_tb);

        // El primer flanco con reset = 1 pone el PC y los 32 registros en 0
        @(posedge clk);
        #1 reset = 0;

        // 26 ciclos, uno por instrucción (monociclo): 22 para las instrucciones 1 a 22, y 4 más en
        // PC 1024 a 1027, los turnos de las instrucciones 23 a 26, para ver que tras JUMP 1024 el PC
        // sigue avanzando y ningún registro cambia (fuera de la IMEM se lee 0, una NOP).
        //
        //          PC         instrucción    RegDst_ALUSrc_RegWrite_Jump_ALUOp
        //                                                    alu_control
        //                                                              rd1       rd2      ALU        dest    next_pc
        esperado = {32'd0,     32'h2801000F,  6'b0_1_1_0_00,  4'b0000,  32'd0,    32'd0,   32'd15,    5'd1,   32'd1};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #1  MOVI $1, 15",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd1,     32'h28020014,  6'b0_1_1_0_00,  4'b0000,  32'd0,    32'd0,   32'd20,    5'd2,   32'd2};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #2  MOVI $2, 20",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd2,     32'h28030032,  6'b0_1_1_0_00,  4'b0000,  32'd0,    32'd0,   32'd50,    5'd3,   32'd3};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #3  MOVI $3, 50",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd3,     32'h28040005,  6'b0_1_1_0_00,  4'b0000,  32'd0,    32'd0,   32'd5,     5'd4,   32'd4};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #4  MOVI $4, 5",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd4,     32'h28050002,  6'b0_1_1_0_00,  4'b0000,  32'd0,    32'd0,   32'd2,     5'd5,   32'd5};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #5  MOVI $5, 2",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd5,     32'h00223020,  6'b1_0_1_0_10,  4'b0010,  32'd15,   32'd20,  32'd35,    5'd6,   32'd6};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #6  ADD $6, $1, $2",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd6,     32'h00613822,  6'b1_0_1_0_10,  4'b0110,  32'd50,   32'd15,  32'd35,    5'd7,   32'd7};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #7  SUB $7, $3, $1",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd7,     32'h00434018,  6'b1_0_1_0_10,  4'b1000,  32'd20,   32'd50,  32'd1000,  5'd8,   32'd8};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #8  MUL $8, $2, $3",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd8,     32'h0062481A,  6'b1_0_1_0_10,  4'b1001,  32'd50,   32'd20,  32'd2,     5'd9,   32'd9};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #9  DIV $9, $3, $2",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd9,     32'h2021000A,  6'b0_1_1_0_01,  4'b0010,  32'd15,   32'd15,  32'd25,    5'd1,   32'd10};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #10 ADDI $1, $1, 10",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd10,    32'h24420004,  6'b0_1_1_0_11,  4'b0110,  32'd20,   32'd20,  32'd16,    5'd2,   32'd11};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #11 SUBI $2, $2, 4",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd11,    32'h00C45020,  6'b1_0_1_0_10,  4'b0010,  32'd35,   32'd5,   32'd40,    5'd10,  32'd12};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #12 ADD $10, $6, $4",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd12,    32'h00C55818,  6'b1_0_1_0_10,  4'b1000,  32'd35,   32'd2,   32'd70,    5'd11,  32'd13};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #13 MUL $11, $6, $5",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd13,    32'h0145601A,  6'b1_0_1_0_10,  4'b1001,  32'd40,   32'd2,   32'd20,    5'd12,  32'd14};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #14 DIV $12, $10, $5",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd14,    32'h20840014,  6'b0_1_1_0_01,  4'b0010,  32'd5,    32'd5,   32'd25,    5'd4,   32'd15};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #15 ADDI $4, $4, 20",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd15,    32'h00836822,  6'b1_0_1_0_10,  4'b0110,  32'd25,   32'd50,  -32'd25,   5'd13,  32'd16};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #16 SUB $13, $4, $3",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd16,    32'h280E0064,  6'b0_1_1_0_00,  4'b0000,  32'd0,    32'd0,   32'd100,   5'd14,  32'd17};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #17 MOVI $14, 100",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd17,    32'h01C17820,  6'b1_0_1_0_10,  4'b0010,  32'd100,  32'd25,  32'd125,   5'd15,  32'd18};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #18 ADD $15, $14, $1",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd18,    32'h24630005,  6'b0_1_1_0_11,  4'b0110,  32'd50,   32'd50,  32'd45,    5'd3,   32'd19};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #19 SUBI $3, $3, 5",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd19,    32'h01E28018,  6'b1_0_1_0_10,  4'b1000,  32'd125,  32'd16,  32'd2000,  5'd16,  32'd20};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #20 MUL $16, $15, $2",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd20,    32'h20310001,  6'b0_1_1_0_01,  4'b0010,  32'd25,   32'd0,   32'd26,    5'd17,  32'd21};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #21 ADDI $17, $1, 1",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd21,    32'h08000400,  6'b0_0_0_1_00,  4'b0000,  32'd0,    32'd0,   32'd0,     5'd0,   32'd1024};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  #22 JUMP 1024",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd1024,  32'h00000000,  6'b1_0_1_0_10,  4'b1111,  32'd0,    32'd0,   32'd0,     5'd0,   32'd1025};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  NOP (fuera de la IMEM)",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd1025,  32'h00000000,  6'b1_0_1_0_10,  4'b1111,  32'd0,    32'd0,   32'd0,     5'd0,   32'd1026};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  NOP (fuera de la IMEM)",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd1026,  32'h00000000,  6'b1_0_1_0_10,  4'b1111,  32'd0,    32'd0,   32'd0,     5'd0,   32'd1027};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  NOP (fuera de la IMEM)",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        esperado = {32'd1027,  32'h00000000,  6'b1_0_1_0_10,  4'b1111,  32'd0,    32'd0,   32'd0,     5'd0,   32'd1028};
        @(negedge clk) $display("PC=%-4d  Instr=%h  RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b | rd1=%-3d rd2=%-3d ALU=%-4d | $%-2d<=%-4d  %0s  NOP (fuera de la IMEM)",
                                current_pc, instruction, RegDst, ALUSrc, RegWrite, Jump, ALUOp, rd1, rd2, alu, wreg, wdata, ok ? "OK" : "ERROR");

        // Tras el último flanco, los 32 registros contra su valor final, calculado a mano
        @(posedge clk) #1;
        $display("$0  = %-5d %0s", uut.rf.registers[0], uut.rf.registers[0] === 0 ? "OK" : "ERROR");
        $display("$1  = %-5d %0s", R1,  R1  === 25   ? "OK" : "ERROR");
        $display("$2  = %-5d %0s", R2,  R2  === 16   ? "OK" : "ERROR");
        $display("$3  = %-5d %0s", R3,  R3  === 45   ? "OK" : "ERROR");
        $display("$4  = %-5d %0s", R4,  R4  === 25   ? "OK" : "ERROR");
        $display("$5  = %-5d %0s", R5,  R5  === 2    ? "OK" : "ERROR");
        $display("$6  = %-5d %0s", R6,  R6  === 35   ? "OK" : "ERROR");
        $display("$7  = %-5d %0s", R7,  R7  === 35   ? "OK" : "ERROR");
        $display("$8  = %-5d %0s", R8,  R8  === 1000 ? "OK" : "ERROR");
        $display("$9  = %-5d %0s", R9,  R9  === 2    ? "OK" : "ERROR");
        $display("$10 = %-5d %0s", R10, R10 === 40   ? "OK" : "ERROR");
        $display("$11 = %-5d %0s", R11, R11 === 70   ? "OK" : "ERROR");
        $display("$12 = %-5d %0s", R12, R12 === 20   ? "OK" : "ERROR");
        $display("$13 = %-5d %0s", R13, R13 === -25  ? "OK" : "ERROR");
        $display("$14 = %-5d %0s", R14, R14 === 100  ? "OK" : "ERROR");
        $display("$15 = %-5d %0s", R15, R15 === 125  ? "OK" : "ERROR");
        $display("$16 = %-5d %0s", R16, R16 === 2000 ? "OK" : "ERROR");
        $display("$17 = %-5d %0s", R17, R17 === 26   ? "OK" : "ERROR");

        // $18 a $31 quedan en 0: JUMP 1024 salta las instrucciones 23 a 26
        for (i = 18; i < 32; i = i + 1)
            $display("$%-2d = %-5d %0s", i, uut.rf.registers[i], uut.rf.registers[i] === 0 ? "OK" : "ERROR");

        #4 $finish;
    end

endmodule
