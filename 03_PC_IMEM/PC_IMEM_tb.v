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
                $display("ciclo %2d  t=%t  R  PC=%2d, Instr=%b_%b_%b_%b_%b_%b    %s  %0s",
                         ciclo, $time, current_pc, opcode, rs, rt, rd, shamt, funct,
                         ok ? "OK   " : "ERROR", caso);
                $display("                            opcode=%b rs=%b rt=%b rd=%b shamt=%b funct=%b",
                         opcode, rs, rt, rd, shamt, funct);
            end
            else if (opcode == 6'b000010) begin
                $display("ciclo %2d  t=%t  J  PC=%2d, Instr=%b_%b        %s  %0s",
                         ciclo, $time, current_pc, opcode, address,
                         ok ? "OK   " : "ERROR", caso);
                $display("                            opcode=%b address=%b (%0d)",
                         opcode, address, address);
            end
            else begin
                $display("ciclo %2d  t=%t  I  PC=%2d, Instr=%b_%b_%b_%b      %s  %0s",
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

        // Un ciclo por palabra del programa de clase (direcciones 0 a 25) y uno
        // más en la 26, la primera sin programa. Aquí el PC siempre avanza + 1:
        // no hay Unidad de Control, así que JUMP 1024 (dirección 21) no salta
        // y se leen también las instrucciones 23 a 26. Lo esperado se copia a
        // mano de la tabla de instrucciones de clase.
        ciclo_cpu(32'd0,  32'b001010_00000_00001_0000000000001111,   "#1  MOVI $1, 15");
        ciclo_cpu(32'd1,  32'b001010_00000_00010_0000000000010100,   "#2  MOVI $2, 20");
        ciclo_cpu(32'd2,  32'b001010_00000_00011_0000000000110010,   "#3  MOVI $3, 50");
        ciclo_cpu(32'd3,  32'b001010_00000_00100_0000000000000101,   "#4  MOVI $4, 5");
        ciclo_cpu(32'd4,  32'b001010_00000_00101_0000000000000010,   "#5  MOVI $5, 2");
        ciclo_cpu(32'd5,  32'b000000_00001_00010_00110_00000_100000, "#6  ADD $6, $1, $2");
        ciclo_cpu(32'd6,  32'b000000_00011_00001_00111_00000_100010, "#7  SUB $7, $3, $1");
        ciclo_cpu(32'd7,  32'b000000_00010_00011_01000_00000_011000, "#8  MUL $8, $2, $3");
        ciclo_cpu(32'd8,  32'b000000_00011_00010_01001_00000_011010, "#9  DIV $9, $3, $2");
        ciclo_cpu(32'd9,  32'b001000_00001_00001_0000000000001010,   "#10 ADDI $1, $1, 10");
        ciclo_cpu(32'd10, 32'b001001_00010_00010_0000000000000100,   "#11 SUBI $2, $2, 4");
        ciclo_cpu(32'd11, 32'b000000_00110_00100_01010_00000_100000, "#12 ADD $10, $6, $4");
        ciclo_cpu(32'd12, 32'b000000_00110_00101_01011_00000_011000, "#13 MUL $11, $6, $5");
        ciclo_cpu(32'd13, 32'b000000_01010_00101_01100_00000_011010, "#14 DIV $12, $10, $5");
        ciclo_cpu(32'd14, 32'b001000_00100_00100_0000000000010100,   "#15 ADDI $4, $4, 20");
        ciclo_cpu(32'd15, 32'b000000_00100_00011_01101_00000_100010, "#16 SUB $13, $4, $3");
        ciclo_cpu(32'd16, 32'b001010_00000_01110_0000000001100100,   "#17 MOVI $14, 100");
        ciclo_cpu(32'd17, 32'b000000_01110_00001_01111_00000_100000, "#18 ADD $15, $14, $1");
        ciclo_cpu(32'd18, 32'b001001_00011_00011_0000000000000101,   "#19 SUBI $3, $3, 5");
        ciclo_cpu(32'd19, 32'b000000_01111_00010_10000_00000_011000, "#20 MUL $16, $15, $2");
        ciclo_cpu(32'd20, 32'b001000_00001_10001_0000000000000001,   "#21 ADDI $17, $1, 1");
        ciclo_cpu(32'd21, 32'b000010_00000000000000010000000000,     "#22 JUMP 1024 (aqui no salta)");
        ciclo_cpu(32'd22, 32'b000000_10001_00010_10010_00000_100000, "#23 ADD $18, $17, $2");
        ciclo_cpu(32'd23, 32'b000000_10010_00101_10011_00000_100010, "#24 SUB $19, $18, $5");
        ciclo_cpu(32'd24, 32'b001010_00000_10100_0000000011111111,   "#25 MOVI $20, 255");
        ciclo_cpu(32'd25, 32'b001010_00000_00000_0000000011111111,   "#26 MOVI $0, 255");
        ciclo_cpu(32'd26, 32'd0,                                     "sin programa: lee 0");

        if (errores == 0)
            $display("=== %0d ciclos, todas las pruebas OK ===", ciclo);
        else
            $display("=== %0d ciclos, %0d ERRORES ===", ciclo, errores);

        // Se detiene antes del siguiente flanco de subida (t = 275 ns).
        #4 $finish;
    end

endmodule
