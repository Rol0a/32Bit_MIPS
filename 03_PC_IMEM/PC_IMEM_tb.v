// =============================================================================
// PC_IMEM_tb.v — Testbench de integración PC + IMEM (usa ../01_PC/PC.v y ../02_IMEM/IMEM.v)
// Conecta la dirección actual del PC con la dirección de la IMEM y calcula
// next_pc = PC + 1. En cada ciclo imprime la instrucción leída con sus campos y
// compara el PC y la instrucción contra los valores esperados.
// =============================================================================
`timescale 1ns / 1ps

module PC_IMEM_tb;

    // Entradas del PC (reg: las maneja el testbench) y conexiones (wire)
    reg         clk;
    reg         reset;
    wire [31:0] next_pc;       // dirección siguiente: PC + 1
    wire [31:0] current_pc;    // salida del PC = dirección de la IMEM
    wire [31:0] instruction;   // salida de la IMEM

    integer ciclo   = 0;   // ciclos impresos (el primero es el 0)
    integer errores = 0;   // comparaciones fallidas

    // El PC avanza solo: una palabra por ciclo (direccionamiento por palabra).
    assign next_pc = current_pc + 32'd1;

    // Campos de la instrucción. Se declaran como wire para verlos en GTKWave;
    // cada formato usa solo algunos de ellos.
    wire [5:0]  opcode    = instruction[31:26];
    wire [4:0]  rs        = instruction[25:21];
    wire [4:0]  rt        = instruction[20:16];
    wire [4:0]  rd        = instruction[15:11];
    wire [4:0]  shamt     = instruction[10:6];
    wire [5:0]  funct     = instruction[5:0];
    wire [15:0] immediate = instruction[15:0];
    wire [25:0] address   = instruction[25:0];

    // PC: guarda la dirección actual y carga next_pc en cada flanco de subida.
    PC uut_pc (
        .clk       (clk),
        .reset     (reset),
        .next_pc   (next_pc),
        .current_pc(current_pc)
    );

    // IMEM: lee de forma combinacional la instrucción apuntada por el PC.
    IMEM uut_imem (
        .addr       (current_pc),
        .instruction(instruction)
    );

    // Reloj de 10 ns: flancos de subida en t = 5, 15, 25, ...
    always #5 clk = ~clk;

    // Espera el flanco de bajada (el PC cambió en el flanco de subida anterior
    // y la IMEM ya leyó la instrucción), compara contra lo esperado e imprime
    // dos líneas: la instrucción con sus campos separados por _ según el
    // formato, y los campos por nombre. El formato se reconoce por el opcode:
    // 000000 es R, 000010 es J y el resto es I.
    task ciclo_cpu;
        input [31:0]   pc_esperado;
        input [31:0]   instr_esperada;
        input [8*40:1] caso;
        reg            ok;
        begin
            @(negedge clk);
            ok = (current_pc === pc_esperado) && (instruction === instr_esperada);
            if (!ok) errores = errores + 1;

            if (opcode == 6'b000000) begin
                $display("ciclo %0d  t=%t  R  PC=%0d, Instr=%b_%b_%b_%b_%b_%b    %s  %0s",
                         ciclo, $time, current_pc, opcode, rs, rt, rd, shamt, funct,
                         ok ? "OK   " : "ERROR", caso);
                $display("                            opcode=%b rs=%b rt=%b rd=%b shamt=%b funct=%b",
                         opcode, rs, rt, rd, shamt, funct);
            end
            else if (opcode == 6'b000010) begin
                $display("ciclo %0d  t=%t  J  PC=%0d, Instr=%b_%b        %s  %0s",
                         ciclo, $time, current_pc, opcode, address,
                         ok ? "OK   " : "ERROR", caso);
                $display("                            opcode=%b address=%b (%0d)",
                         opcode, address, address);
            end
            else begin
                $display("ciclo %0d  t=%t  I  PC=%0d, Instr=%b_%b_%b_%b      %s  %0s",
                         ciclo, $time, current_pc, opcode, rs, rt, immediate,
                         ok ? "OK   " : "ERROR", caso);
                $display("                            opcode=%b rs=%b rt=%b immediate=%b (%0d)",
                         opcode, rs, rt, immediate, $signed(immediate));
            end

            // Si algo no coincide, se muestra también lo esperado.
            if (!ok)
                $display("                            esperado: PC=%0d, Instr=%h", pc_esperado, instr_esperada);

            ciclo = ciclo + 1;
        end
    endtask

    initial begin
        $dumpfile("PC_IMEM_tb.vcd");
        $dumpvars(0, PC_IMEM_tb);

        // Inicialización: reloj en 0 y reset activo.
        clk   = 0;
        reset = 1;

        // %t imprime el tiempo en ns, sin decimales
        $timeformat(-9, 0, " ns", 6);

        $display("=== Testbench PC + IMEM ===");
        #1 $display("t=%t  antes del primer flanco: PC=%0d, Instr=%h (x: el PC aun no se ha reiniciado)",
                    $time, current_pc, instruction);

        // El primer flanco de subida con reset = 1 pone el PC en 0. Se suelta
        // reset 1 ns después, antes del flanco de bajada: así el PC se queda en
        // 0 durante este ciclo y el siguiente flanco carga 0 + 1 = 1.
        @(posedge clk);
        #1 reset = 0;

        // Un ciclo por instrucción del programa (direcciones 0 a 9). Lo
        // esperado se escribe a mano, igual que en la tabla del README.
        ciclo_cpu(32'd0, 32'b000000_00001_00010_00011_00000_100000, "add  $3, $1, $2");
        ciclo_cpu(32'd1, 32'b001000_01000_01001_0000000000001010,   "addi $9, $8, 10");
        ciclo_cpu(32'd2, 32'b001010_00000_00001_0000000000000111,   "movi $1, 7");
        ciclo_cpu(32'd3, 32'b001010_00000_00010_1111111111111101,   "movi $2, -3");
        ciclo_cpu(32'd4, 32'b000000_00001_00010_00100_00000_100100, "sub  $4, $1, $2");
        ciclo_cpu(32'd5, 32'b000000_00001_00010_00101_00000_100001, "mul  $5, $1, $2");
        ciclo_cpu(32'd6, 32'b000000_00101_00001_00110_00000_100010, "div  $6, $5, $1");
        ciclo_cpu(32'd7, 32'b001001_01001_00111_0000000000001111,   "subi $7, $9, 15");
        ciclo_cpu(32'd8, 32'b000000_00111_00000_01010_00000_100011, "mov  $10, $7");
        ciclo_cpu(32'd9, 32'b000010_00000000000000000000001001,     "j    9");

        if (errores == 0)
            $display("=== %0d ciclos, todas las pruebas OK ===", ciclo);
        else
            $display("=== %0d ciclos, %0d ERRORES ===", ciclo, errores);

        // Se detiene antes del siguiente flanco de subida (t = 105 ns): ahí el
        // PC pasaría a 10, una palabra sin instrucción que lee x. El salto de
        // la dirección 9 no se ejecuta: aquí el PC siempre avanza + 1.
        #4 $finish;
    end

endmodule
