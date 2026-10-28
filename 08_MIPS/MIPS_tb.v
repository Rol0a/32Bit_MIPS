// =============================================================================
// MIPS_tb.v — Testbench del procesador completo (usa MIPS.v y los módulos de
// 01_PC, 02_IMEM, 04_ControlUnit, 05_ALU, 06_ALUControl y 07_RegisterFile)
// Ejecuta el programa de la IMEM. En cada ciclo compara el PC, la instrucción,
// las señales de control, la operación, los operandos, el resultado, el
// destino y el siguiente PC contra la traza calculada a mano; después del
// flanco comprueba el registro escrito. Al final compara los 32 registros.
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

    // Registros que usa el programa, para verlos en GTKWave: $dumpvars no
    // vuelca arreglos, así que se leen con una referencia jerárquica al banco.
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

    // Reloj de 10 ns: flancos de subida en t = 5, 15, 25, ...
    always #5 clk = ~clk;

    // Un ciclo de instrucción, en dos momentos:
    // 1. Flanco de bajada: el PC cambió en el flanco de subida anterior y toda
    //    la lógica combinacional ya se asentó. Compara las señales internas
    //    (uut.<señal>) con lo esperado e imprime una línea.
    // 2. 1 ns después del flanco de subida: el banco ya guardó el resultado.
    //    Si la instrucción escribe, compara el registro destino. Imprime una
    //    segunda línea con la escritura, OK/ERROR y el mnemónico.
    // Se compara con !== / === para que una x también cuente como error.
    task ciclo_cpu;
        input [31:0]   pc_esp;
        input [31:0]   instr_esp;
        input [5:0]    ctl_esp;     // RegDst ALUSrc RegWrite Jump ALUOp
        input [3:0]    aluc_esp;
        input [31:0]   src1_esp;
        input [31:0]   src2_esp;
        input [31:0]   res_esp;     // zero esperado = (res_esp == 0)
        input [4:0]    wreg_esp;
        input [31:0]   next_esp;
        input [8*20:1] caso;
        reg   [5:0]    ctl;
        reg            ok_ciclo;    // señales del ciclo
        reg            ok_banco;    // registro escrito
        begin
            @(negedge clk);
            ctl = {uut.RegDst, uut.ALUSrc, uut.RegWrite, uut.Jump, uut.ALUOp};
            ok_ciclo = (current_pc      === pc_esp)    &&
                       (instruction     === instr_esp) &&
                       (ctl             === ctl_esp)   &&
                       (uut.alu_control === aluc_esp)  &&
                       (uut.read_data1  === src1_esp)  &&
                       (uut.src2        === src2_esp)  &&
                       (alu_result      === res_esp)   &&
                       (uut.zero        === (res_esp == 32'd0)) &&
                       (uut.write_reg   === wreg_esp)  &&
                       (uut.next_pc     === next_esp);

            $display("ciclo %2d  t=%t  PC=%0d  Instr=%h  ctl=%b_%b_%b_%b_%b  alu_control=%b  src1=%3d src2=%3d -> result=%3d zero=%b  write_reg=%2d  next_pc=%0d",
                     ciclo, $time, current_pc, instruction,
                     ctl[5], ctl[4], ctl[3], ctl[2], ctl[1:0], uut.alu_control,
                     $signed(uut.read_data1), $signed(uut.src2), $signed(alu_result), uut.zero,
                     uut.write_reg, uut.next_pc);
            if (!ok_ciclo)
                $display("          esperado:  PC=%0d  Instr=%h  ctl=%b_%b_%b_%b_%b  alu_control=%b  src1=%3d src2=%3d -> result=%3d zero=%b  write_reg=%2d  next_pc=%0d",
                         pc_esp, instr_esp,
                         ctl_esp[5], ctl_esp[4], ctl_esp[3], ctl_esp[2], ctl_esp[1:0], aluc_esp,
                         $signed(src1_esp), $signed(src2_esp), $signed(res_esp), (res_esp == 32'd0),
                         wreg_esp, next_esp);

            @(posedge clk); #1;
            if (ctl_esp[3]) begin
                ok_banco = (uut.rf.registers[wreg_esp] === res_esp);
                $display("                    t=%t  banco: $%0d = %0d    %s  %0s",
                         $time, wreg_esp, $signed(uut.rf.registers[wreg_esp]),
                         (ok_ciclo && ok_banco) ? "OK   " : "ERROR", caso);
                if (!ok_banco)
                    $display("                    esperado: $%0d = %0d", wreg_esp, $signed(res_esp));
            end
            else begin
                // RegWrite = 0: no hay registro que revisar en este ciclo. Que
                // el banco no cambió lo comprueba el estado final.
                ok_banco = 1'b1;
                $display("                    t=%t  banco: sin escritura (RegWrite = 0)    %s  %0s",
                         $time, ok_ciclo ? "OK   " : "ERROR", caso);
            end

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

    // Compara los 32 registros con el estado esperado. Imprime los que usa el
    // programa ($0 a $10), cuenta cuántos de $11 a $31 valen 0 y muestra una
    // línea de ERROR por cada registro distinto.
    task revisar_banco;
        integer distintos;
        integer en_cero;
        begin
            distintos = 0;
            en_cero   = 0;
            for (i = 0; i < 32; i = i + 1) begin
                if (uut.rf.registers[i] !== banco_esperado[i]) begin
                    distintos = distintos + 1;
                    $display("    ERROR  $%0d = %0d, esperado %0d",
                             i, $signed(uut.rf.registers[i]), $signed(banco_esperado[i]));
                end
                if (i >= 11 && uut.rf.registers[i] === 32'd0)
                    en_cero = en_cero + 1;
            end
            errores = errores + distintos;

            $display("=== Estado final del banco (t=%t) ===", $time);
            $display("$0=%0d  $1=%0d  $2=%0d  $3=%0d  $4=%0d  $5=%0d  $6=%0d  $7=%0d  $8=%0d  $9=%0d  $10=%0d  |  $11-$31: %0d de 21 en 0",
                     $signed(uut.rf.registers[0]), $signed(uut.rf.registers[1]),
                     $signed(uut.rf.registers[2]), $signed(uut.rf.registers[3]),
                     $signed(uut.rf.registers[4]), $signed(uut.rf.registers[5]),
                     $signed(uut.rf.registers[6]), $signed(uut.rf.registers[7]),
                     $signed(uut.rf.registers[8]), $signed(uut.rf.registers[9]),
                     $signed(uut.rf.registers[10]), en_cero);
            $display("%0d de 32 registros como se esperaba    %s",
                     32 - distintos, (distintos == 0) ? "OK" : "ERROR");
        end
    endtask

    initial begin
        $dumpfile("MIPS_tb.vcd");
        $dumpvars(0, MIPS_tb);

        // Estado final esperado: todos en 0 salvo los que escribe el programa.
        for (i = 0; i < 32; i = i + 1)
            banco_esperado[i] = 32'd0;
        banco_esperado[1]  =   7;   // movi $1, 7
        banco_esperado[2]  =  -3;   // movi $2, -3
        banco_esperado[4]  =  10;   // sub  $4, $1, $2
        banco_esperado[5]  = -21;   // mul  $5, $1, $2
        banco_esperado[6]  =  -3;   // div  $6, $5, $1
        banco_esperado[7]  =  -5;   // subi $7, $9, 15
        banco_esperado[9]  =  10;   // addi $9, $8, 10
        banco_esperado[10] =  -5;   // mov  $10, $7

        // Inicialización: reloj en 0 y reset activo.
        clk   = 0;
        reset = 1;

        // %t imprime el tiempo en ns, sin decimales
        $timeformat(-9, 0, " ns", 6);

        $display("=== Testbench MIPS: procesador completo ===");

        // Antes del primer flanco todo vale x: el PC aún no se reinicia, la
        // IMEM lee memory[x] y los always @(*) de ControlUnit, ALUControl y
        // ALU todavía no se ejecutan (solo lo hacen cuando cambia una entrada,
        // y opcode no cambia hasta el primer flanco), así que RegWrite = x.
        #1 $display("t=%t  antes del primer flanco: PC=%0d, Instr=%h, RegWrite=%b, Jump=%b (x: aun no hay reset)",
                    $time, current_pc, instruction, uut.RegWrite, uut.Jump);

        // El primer flanco de subida con reset = 1 pone el PC y los 32
        // registros en 0. El reset del banco tiene prioridad sobre RegWrite:
        // aunque valga x, no hay escrituras espurias. Se suelta reset 1 ns
        // después: la instrucción 0 se ejecuta un ciclo completo y el
        // siguiente flanco carga next_pc = 1.
        @(posedge clk);
        #1 reset = 0;
        revisar_reset;

        // Un ciclo por instrucción (direcciones 0 a 9) y dos más para ver que
        // j 9 deja el PC fijo. Lo esperado es la traza de la tabla del
        // README, calculada a mano.
        //        PC  instrucción     RegDst_ALUSrc_RegWrite_Jump_ALUOp
        //                                           alu_control
        //                                                    src1 src2 result dest next_pc
        ciclo_cpu(0, 32'h00221820, 6'b1_0_1_0_10, 4'b0010,   0,   0,    0,   3,   1, "add  $3, $1, $2");
        ciclo_cpu(1, 32'h2109000A, 6'b0_1_1_0_01, 4'b0010,   0,  10,   10,   9,   2, "addi $9, $8, 10");
        ciclo_cpu(2, 32'h28010007, 6'b0_1_1_0_00, 4'b0000,   0,   7,    7,   1,   3, "movi $1, 7");
        ciclo_cpu(3, 32'h2802FFFD, 6'b0_1_1_0_00, 4'b0000,   0,  -3,   -3,   2,   4, "movi $2, -3");
        ciclo_cpu(4, 32'h00222024, 6'b1_0_1_0_10, 4'b0110,   7,  -3,   10,   4,   5, "sub  $4, $1, $2");
        ciclo_cpu(5, 32'h00222821, 6'b1_0_1_0_10, 4'b1000,   7,  -3,  -21,   5,   6, "mul  $5, $1, $2");
        ciclo_cpu(6, 32'h00A13022, 6'b1_0_1_0_10, 4'b1001, -21,   7,   -3,   6,   7, "div  $6, $5, $1");
        ciclo_cpu(7, 32'h2527000F, 6'b0_1_1_0_11, 4'b0110,  10,  15,   -5,   7,   8, "subi $7, $9, 15");
        ciclo_cpu(8, 32'h00E05023, 6'b1_0_1_0_10, 4'b0001,  -5,   0,   -5,  10,   9, "mov  $10, $7");
        ciclo_cpu(9, 32'h08000009, 6'b0_0_0_1_00, 4'b0000,   0,   0,    0,   0,   9, "j    9");
        ciclo_cpu(9, 32'h08000009, 6'b0_0_0_1_00, 4'b0000,   0,   0,    0,   0,   9, "j    9 (repite)");
        ciclo_cpu(9, 32'h08000009, 6'b0_0_0_1_00, 4'b0000,   0,   0,    0,   0,   9, "j    9 (repite)");

        revisar_banco;

        if (errores == 0)
            $display("=== Reset, %0d ciclos y estado final: todas las pruebas OK ===", ciclo);
        else
            $display("=== Reset, %0d ciclos y estado final: %0d ERRORES ===", ciclo, errores);

        #4 $finish;
    end

endmodule
