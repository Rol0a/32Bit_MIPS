// =============================================================================
// MIPS_tb.v — Testbench del procesador completo (usa MIPS.v y los módulos de
// 01_PC, 02_IMEM, 04_ControlUnit, 05_ALU, 06_ALUControl y 07_RegisterFile)
// Ejecuta el programa de clase (26 instrucciones) que la IMEM carga al empezar
// la simulación (initial de IMEM.v). Por cada instrucción imprime el ciclo
// completo: búsqueda (PC e instrucción), decodificación (campos y señales de
// control), ejecución (rd1, rd2 y ALU) y escritura ($rd<=valor, leído del banco
// después del flanco). Todo se compara contra la traza calculada a mano. Al
// final imprime los 32 registros: esa es la salida que se fotografía.
// =============================================================================
`timescale 1ns / 1ps

module MIPS_tb;

    // Entradas del procesador (reg: las maneja el testbench) y salidas (wire)
    reg         clk;
    reg         reset;
    wire [31:0] current_pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;

    integer ciclo   = 0;   // ciclos impresos (el primero es el 0)
    integer errores = 0;   // comparaciones fallidas
    integer i;

    // Estado final esperado del banco, calculado a mano (se llena abajo).
    reg [31:0] banco_esperado [0:31];

    // Unidad bajo prueba
    MIPS uut (
        .clk        (clk),
        .reset      (reset),
        .current_pc (current_pc),
        .instruction(instruction),
        .alu_result (alu_result)
    );

    // Campos de la instrucción en ejecución, para imprimirlos. Cada formato
    // usa solo algunos.
    wire [5:0]  opcode    = instruction[31:26];
    wire [4:0]  rs        = instruction[25:21];
    wire [4:0]  rt        = instruction[20:16];
    wire [4:0]  rd        = instruction[15:11];
    wire [4:0]  shamt     = instruction[10:6];
    wire [5:0]  funct     = instruction[5:0];
    wire [15:0] immediate = instruction[15:0];
    wire [25:0] address   = instruction[25:0];

    // Registros que usa el programa, para verlos en GTKWave: $dumpvars no
    // vuelca arreglos, así que se leen con una referencia jerárquica al banco
    // (instancia.banco.registros[i]).
    wire [31:0] R1  = uut.rf.registers[1];
    wire [31:0] R2  = uut.rf.registers[2];
    wire [31:0] R3  = uut.rf.registers[3];
    wire [31:0] R4  = uut.rf.registers[4];
    wire [31:0] R5  = uut.rf.registers[5];
    wire [31:0] R6  = uut.rf.registers[6];
    wire [31:0] R7  = uut.rf.registers[7];
    wire [31:0] R8  = uut.rf.registers[8];
    wire [31:0] R9  = uut.rf.registers[9];
    wire [31:0] R10 = uut.rf.registers[10];
    wire [31:0] R11 = uut.rf.registers[11];
    wire [31:0] R12 = uut.rf.registers[12];
    wire [31:0] R13 = uut.rf.registers[13];
    wire [31:0] R14 = uut.rf.registers[14];
    wire [31:0] R15 = uut.rf.registers[15];
    wire [31:0] R16 = uut.rf.registers[16];
    wire [31:0] R17 = uut.rf.registers[17];
    wire [31:0] R18 = uut.rf.registers[18];
    wire [31:0] R19 = uut.rf.registers[19];
    wire [31:0] R20 = uut.rf.registers[20];

    // Reloj de 10 ns: flancos de subida en t = 5, 15, 25, ...
    always #5 clk = ~clk;

    // Un ciclo de instrucción, en dos momentos:
    // 1. Flanco de bajada: el PC cambió en el flanco de subida anterior y toda
    //    la lógica combinacional ya se asentó. Imprime la búsqueda y la
    //    decodificación, y guarda las señales del ciclo para compararlas.
    // 2. 1 ns después del flanco de subida: el banco ya guardó el resultado.
    //    Imprime las señales, los operandos, la ALU y el registro escrito
    //    (leído del banco, no de la ALU), con OK o ERROR.
    // Se compara con !== / === para que una x también cuente como error.
    task ciclo_cpu;
        input [31:0]   pc_esp;
        input [31:0]   instr_esp;
        input [5:0]    ctl_esp;     // RegDst ALUSrc RegWrite Jump ALUOp
        input [3:0]    aluc_esp;    // alu_control
        input [31:0]   rd1_esp;     // read_data1 = $rs
        input [31:0]   rd2_esp;     // read_data2 = $rt
        input [31:0]   alu_esp;     // zero esperado = (alu_esp == 0)
        input [4:0]    wreg_esp;    // registro destino (rd o rt)
        input [31:0]   next_esp;    // siguiente PC
        input [8*36:1] caso;
        reg   [5:0]    ctl;
        reg   [3:0]    aluc;
        reg   [31:0]   rd1, rd2, alu, next;
        reg   [4:0]    wreg;
        reg            ok_ciclo;    // señales del ciclo
        reg            ok_banco;    // registro escrito
        begin
            @(negedge clk);
            ctl  = {uut.RegDst, uut.ALUSrc, uut.RegWrite, uut.Jump, uut.ALUOp};
            aluc = uut.alu_control;
            rd1  = uut.read_data1;
            rd2  = uut.read_data2;
            alu  = alu_result;
            wreg = uut.write_reg;
            next = uut.next_pc;
            ok_ciclo = (current_pc  === pc_esp)    &&
                       (instruction === instr_esp) &&
                       (ctl         === ctl_esp)   &&
                       (aluc        === aluc_esp)  &&
                       (rd1         === rd1_esp)   &&
                       (rd2         === rd2_esp)   &&
                       (alu         === alu_esp)   &&
                       (uut.zero    === (alu_esp == 32'd0)) &&
                       (wreg        === wreg_esp)  &&
                       (next        === next_esp);

            // Búsqueda y decodificación. El formato se reconoce por el opcode:
            // 000000 es R, 000010 es J y el resto es I.
            if (opcode == 6'b000000) begin
                $display("PC=%0d  Instr=%b_%b_%b_%b_%b_%b   %0s   (ciclo %0d, t=%t)",
                         current_pc, opcode, rs, rt, rd, shamt, funct, caso, ciclo, $time);
                $display("     opcode=%b rs=%0d rt=%0d rd=%0d shamt=%0d funct=%b",
                         opcode, rs, rt, rd, shamt, funct);
            end
            else if (opcode == 6'b000010) begin
                $display("PC=%0d  Instr=%b_%b       %0s   (ciclo %0d, t=%t)",
                         current_pc, opcode, address, caso, ciclo, $time);
                $display("     opcode=%b address=%0d",
                         opcode, address);
            end
            else begin
                $display("PC=%0d  Instr=%b_%b_%b_%b     %0s   (ciclo %0d, t=%t)",
                         current_pc, opcode, rs, rt, immediate, caso, ciclo, $time);
                $display("     opcode=%b rs=%0d rt=%0d imm=%0d",
                         opcode, rs, rt, $signed(immediate));
            end

            // Escritura: el banco guarda el resultado en el flanco de subida.
            @(posedge clk); #1;
            if (ctl_esp[3] && wreg_esp != 5'd0) begin
                ok_banco = (uut.rf.registers[wreg_esp] === alu_esp);
                $display("     RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b ALUctl=%b | rd1=%0d rd2=%0d ALU=%0d | $%0d<=%0d    %s",
                         ctl[5], ctl[4], ctl[3], ctl[2], ctl[1:0], aluc,
                         $signed(rd1), $signed(rd2), $signed(alu),
                         wreg_esp, $signed(uut.rf.registers[wreg_esp]),
                         (ok_ciclo && ok_banco) ? "OK" : "ERROR");
            end
            else if (ctl_esp[3]) begin
                // Destino $0 (la NOP): RegWrite = 1, pero el banco no escribe
                // $0, que sigue en 0.
                ok_banco = (uut.rf.registers[0] === 32'd0);
                $display("     RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b ALUctl=%b | rd1=%0d rd2=%0d ALU=%0d | $0 no se escribe ($0=%0d)    %s",
                         ctl[5], ctl[4], ctl[3], ctl[2], ctl[1:0], aluc,
                         $signed(rd1), $signed(rd2), $signed(alu),
                         $signed(uut.rf.registers[0]),
                         (ok_ciclo && ok_banco) ? "OK" : "ERROR");
            end
            else begin
                // RegWrite = 0 (JUMP): no hay registro que revisar. Que el
                // banco no cambió lo comprueba el estado final.
                ok_banco = 1'b1;
                $display("     RegDst=%b ALUSrc=%b RegWrite=%b Jump=%b ALUOp=%b ALUctl=%b | rd1=%0d rd2=%0d ALU=%0d | sin escritura, PC<=%0d    %s",
                         ctl[5], ctl[4], ctl[3], ctl[2], ctl[1:0], aluc,
                         $signed(rd1), $signed(rd2), $signed(alu), next,
                         ok_ciclo ? "OK" : "ERROR");
            end

            // Si algo no coincide, se muestra también lo esperado.
            if (!ok_ciclo)
                $display("     esperado: PC=%0d Instr=%h ctl=%b alu_control=%b rd1=%0d rd2=%0d ALU=%0d write_reg=%0d next_pc=%0d",
                         pc_esp, instr_esp, ctl_esp, aluc_esp, $signed(rd1_esp), $signed(rd2_esp),
                         $signed(alu_esp), wreg_esp, next_esp);
            if (!ok_banco)
                $display("     esperado en el banco: $%0d = %0d", wreg_esp,
                         (wreg_esp == 5'd0) ? 0 : $signed(alu_esp));

            if (!(ok_ciclo && ok_banco)) errores = errores + 1;
            ciclo = ciclo + 1;
        end
    endtask

    // Después del primer flanco con reset = 1: el PC debe valer 0 y los 32
    // registros, 0. Cuenta como una sola comprobación.
    task revisar_reset;
        integer en_cero;
        begin
            en_cero = 0;
            for (i = 0; i < 32; i = i + 1)
                if (uut.rf.registers[i] === 32'd0)
                    en_cero = en_cero + 1;
            if (current_pc !== 32'd0 || en_cero != 32) errores = errores + 1;
            $display("t=%t  tras el flanco con reset: PC=%0d, %0d de 32 registros en 0    %s",
                     $time, current_pc, en_cero,
                     (current_pc === 32'd0 && en_cero == 32) ? "OK" : "ERROR");
        end
    endtask

    // Imprime los 32 registros en dos columnas ($0-$15 y $16-$31) con el
    // valor obtenido, el esperado y OK/ERROR, y los cuenta.
    task revisar_banco;
        integer distintos;
        integer j;
        begin
            distintos = 0;
            for (i = 0; i < 32; i = i + 1)
                if (uut.rf.registers[i] !== banco_esperado[i])
                    distintos = distintos + 1;
            errores = errores + distintos;

            $display("");
            $display("=== Valores finales de los registros (t=%t) ===", $time);
            for (i = 0; i < 16; i = i + 1) begin
                j = i + 16;
                $display("$%-2d = %5d  (esperado %5d)  %s        $%-2d = %5d  (esperado %5d)  %s",
                         i, $signed(uut.rf.registers[i]), $signed(banco_esperado[i]),
                         (uut.rf.registers[i] === banco_esperado[i]) ? "OK   " : "ERROR",
                         j, $signed(uut.rf.registers[j]), $signed(banco_esperado[j]),
                         (uut.rf.registers[j] === banco_esperado[j]) ? "OK   " : "ERROR");
            end
            $display("%0d de 32 registros como se esperaba    %s",
                     32 - distintos, (distintos == 0) ? "OK" : "ERROR");
        end
    endtask

    initial begin
        $dumpfile("MIPS_tb.vcd");
        $dumpvars(0, MIPS_tb);

        // Estado final esperado, calculado a mano: todos en 0 salvo los que
        // escriben las instrucciones 1 a 21. Las 23 a 26 no se ejecutan
        // (JUMP 1024 sale de la IMEM), así que $18, $19 y $20 quedan en 0, y
        // $0 vale 0 siempre.
        for (i = 0; i < 32; i = i + 1)
            banco_esperado[i] = 32'd0;
        banco_esperado[1]  =   25;   // MOVI $1, 15 y luego ADDI $1, $1, 10
        banco_esperado[2]  =   16;   // MOVI $2, 20 y luego SUBI $2, $2, 4
        banco_esperado[3]  =   45;   // MOVI $3, 50 y luego SUBI $3, $3, 5
        banco_esperado[4]  =   25;   // MOVI $4, 5  y luego ADDI $4, $4, 20
        banco_esperado[5]  =    2;   // MOVI $5, 2
        banco_esperado[6]  =   35;   // ADD $6, $1, $2     15 + 20
        banco_esperado[7]  =   35;   // SUB $7, $3, $1     50 - 15
        banco_esperado[8]  = 1000;   // MUL $8, $2, $3     20 * 50
        banco_esperado[9]  =    2;   // DIV $9, $3, $2     50 / 20 (entera)
        banco_esperado[10] =   40;   // ADD $10, $6, $4    35 + 5
        banco_esperado[11] =   70;   // MUL $11, $6, $5    35 * 2
        banco_esperado[12] =   20;   // DIV $12, $10, $5   40 / 2
        banco_esperado[13] =  -25;   // SUB $13, $4, $3    25 - 50
        banco_esperado[14] =  100;   // MOVI $14, 100
        banco_esperado[15] =  125;   // ADD $15, $14, $1   100 + 25
        banco_esperado[16] = 2000;   // MUL $16, $15, $2   125 * 16
        banco_esperado[17] =   26;   // ADDI $17, $1, 1    25 + 1

        // Inicialización: reloj en 0 y reset activo.
        clk   = 0;
        reset = 1;

        // %t imprime el tiempo en ns, sin decimales
        $timeformat(-9, 0, " ns", 6);

        $display("=== Testbench MIPS: programa de clase (26 instrucciones) ===");

        // Antes del primer flanco todo vale x: el PC aún no se reinicia, la
        // IMEM lee memory[x] y los always @(*) de ControlUnit, ALUControl y
        // ALU todavía no se ejecutan (solo lo hacen cuando cambia una entrada,
        // y opcode no cambia hasta el primer flanco), así que RegWrite = x.
        #1 $display("t=%t  antes del primer flanco: PC=%0d, Instr=%h, RegWrite=%b, Jump=%b (x: aun no hay reset)",
                    $time, current_pc, instruction, uut.RegWrite, uut.Jump);

        // El primer flanco de subida con reset = 1 pone el PC y los 32
        // registros en 0. El reset del banco tiene prioridad sobre RegWrite:
        // aunque valga x, no hay escrituras espurias. Se suelta reset 1 ns
        // después: la instrucción 1 se ejecuta un ciclo completo y el
        // siguiente flanco carga next_pc = 1.
        @(posedge clk);
        #1 reset = 0;
        revisar_reset;
        $display("");

        // Ciclos usados: 26, uno por instrucción (monociclo).
        // - 22 ciclos para las instrucciones 1 a 22 (PC 0 a 21). La 22 es
        //   JUMP 1024: el PC pasa a 1024, fuera de la IMEM (0 a 1023).
        // - 4 ciclos más, en PC 1024 a 1027: son los turnos que ocuparían las
        //   instrucciones 23 a 26, que nunca se ejecutan. Fuera de la IMEM se
        //   lee 0, una NOP (tipo R, funct no definido, destino $0): la ALU da
        //   0 y el banco no escribe $0. Así se ve que, después del salto, el
        //   PC sigue avanzando y ningún registro cambia.
        // Lo esperado es la traza de la tabla del README, calculada a mano.
        //         PC    instrucción    RegDst_ALUSrc_RegWrite_Jump_ALUOp
        //                                            alu_control
        //                                                     rd1   rd2    ALU dest next_pc
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

        revisar_banco;

        if (errores == 0)
            $display("=== Reset, %0d ciclos y estado final: todas las pruebas OK ===", ciclo);
        else
            $display("=== Reset, %0d ciclos y estado final: %0d ERRORES ===", ciclo, errores);

        #4 $finish;
    end

endmodule
