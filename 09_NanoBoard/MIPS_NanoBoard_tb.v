// MIPS_NanoBoard_tb.v — Testbench de MIPS_NanoBoard: hace el papel de la placa y de los dos
// Memory Instrument. Solo simulación: NO se agrega al proyecto de Altium.
// Casos de prueba: README.md de esta carpeta.
`timescale 1ns / 1ps

module MIPS_NanoBoard_tb;

    localparam DEBOUNCE_BITS = 3;    // 8 ciclos, para que la simulación sea corta (en la placa, 18)
    localparam DIV_WAIT      = 16;   // el mismo valor que en la placa

    // ---- Módulo bajo prueba ----
    reg         clk        = 1'b0;
    reg         reset_sw   = 1'b1;
    reg         run_sw     = 1'b0;
    reg         step_btn   = 1'b0;
    reg  [9:0]  imem_addr  = 10'd0;
    reg  [31:0] imem_wdata = 32'd0;
    reg         imem_we    = 1'b0;
    reg  [4:0]  reg_addr   = 5'd0;
    wire [31:0] imem_rdata, reg_data, current_pc, instruction;

    MIPS_NanoBoard #(
        .DEBOUNCE_BITS(DEBOUNCE_BITS),
        .DIV_WAIT     (DIV_WAIT)
    ) uut (
        .clk        (clk),
        .reset_sw   (reset_sw),
        .run_sw     (run_sw),
        .step_btn   (step_btn),
        .imem_addr  (imem_addr),
        .imem_wdata (imem_wdata),
        .imem_we    (imem_we),
        .imem_rdata (imem_rdata),
        .reg_addr   (reg_addr),
        .reg_data   (reg_data),
        .current_pc (current_pc),
        .instruction(instruction)
    );

    always #25 clk = ~clk;   // 20 MHz, como el reloj fijo de la NanoBoard-3000

    // Instrucciones terminadas y ciclos de la fase 5
    integer advances = 0, run_cycles = 0, div_cycles = 0;
    reg     measuring = 1'b0;

    always @(posedge clk) begin
        if (uut.advance && !uut.reset)
            advances = advances + 1;
        if (measuring && !uut.reset && current_pc < 32'd1024) begin
            run_cycles = run_cycles + 1;
            if (current_pc == 32'd8)
                div_cycles = div_cycles + 1;
        end
    end

    // ---- Casos de prueba ----
    reg [31:0] program_words [0:25];   // programa de clase, igual que en 02_IMEM
    reg [31:0] final_regs    [0:31];   // estado final esperado
    reg [31:0] value;
    integer    n, fase;

    initial begin
        $dumpfile("MIPS_NanoBoard_tb.vcd");
        $dumpvars(0, MIPS_NanoBoard_tb);

        program_words[0]  = 32'b001010_00000_00001_0000000000001111;   //  1  MOVI $1, 15
        program_words[1]  = 32'b001010_00000_00010_0000000000010100;   //  2  MOVI $2, 20
        program_words[2]  = 32'b001010_00000_00011_0000000000110010;   //  3  MOVI $3, 50
        program_words[3]  = 32'b001010_00000_00100_0000000000000101;   //  4  MOVI $4, 5
        program_words[4]  = 32'b001010_00000_00101_0000000000000010;   //  5  MOVI $5, 2
        program_words[5]  = 32'b000000_00001_00010_00110_00000_100000; //  6  ADD  $6, $1, $2
        program_words[6]  = 32'b000000_00011_00001_00111_00000_100010; //  7  SUB  $7, $3, $1
        program_words[7]  = 32'b000000_00010_00011_01000_00000_011000; //  8  MUL  $8, $2, $3
        program_words[8]  = 32'b000000_00011_00010_01001_00000_011010; //  9  DIV  $9, $3, $2
        program_words[9]  = 32'b001000_00001_00001_0000000000001010;   // 10  ADDI $1, $1, 10
        program_words[10] = 32'b001001_00010_00010_0000000000000100;   // 11  SUBI $2, $2, 4
        program_words[11] = 32'b000000_00110_00100_01010_00000_100000; // 12  ADD  $10, $6, $4
        program_words[12] = 32'b000000_00110_00101_01011_00000_011000; // 13  MUL  $11, $6, $5
        program_words[13] = 32'b000000_01010_00101_01100_00000_011010; // 14  DIV  $12, $10, $5
        program_words[14] = 32'b001000_00100_00100_0000000000010100;   // 15  ADDI $4, $4, 20
        program_words[15] = 32'b000000_00100_00011_01101_00000_100010; // 16  SUB  $13, $4, $3
        program_words[16] = 32'b001010_00000_01110_0000000001100100;   // 17  MOVI $14, 100
        program_words[17] = 32'b000000_01110_00001_01111_00000_100000; // 18  ADD  $15, $14, $1
        program_words[18] = 32'b001001_00011_00011_0000000000000101;   // 19  SUBI $3, $3, 5
        program_words[19] = 32'b000000_01111_00010_10000_00000_011000; // 20  MUL  $16, $15, $2
        program_words[20] = 32'b001000_00001_10001_0000000000000001;   // 21  ADDI $17, $1, 1
        program_words[21] = 32'b000010_00000000000000010000000000;     // 22  JUMP 1024
        program_words[22] = 32'b000000_10001_00010_10010_00000_100000; // 23  ADD  $18, $17, $2 (no se ejecuta)
        program_words[23] = 32'b000000_10010_00101_10011_00000_100010; // 24  SUB  $19, $18, $5 (no se ejecuta)
        program_words[24] = 32'b001010_00000_10100_0000000011111111;   // 25  MOVI $20, 255    (no se ejecuta)
        program_words[25] = 32'b001010_00000_00000_0000000011111111;   // 26  MOVI $0, 255     (no se ejecuta)

        for (n = 0; n < 32; n = n + 1)
            final_regs[n] = 32'd0;
        final_regs[1]  = 25;   final_regs[2]  = 16;   final_regs[3]  = 45;   final_regs[4]  = 25;
        final_regs[5]  = 2;    final_regs[6]  = 35;   final_regs[7]  = 35;   final_regs[8]  = 1000;
        final_regs[9]  = 2;    final_regs[10] = 40;   final_regs[11] = 70;   final_regs[12] = 20;
        final_regs[13] = -25;  final_regs[14] = 100;  final_regs[15] = 125;  final_regs[16] = 2000;
        final_regs[17] = 26;

        fase = 1;   // Carga del programa por el instrumento 1 (Reset = 1, Run = 0)
        repeat (3) @(negedge clk);
        for (n = 0; n < 26; n = n + 1)
            write_word(n, program_words[n]);
        for (n = 0; n < 26; n = n + 1) begin
            imem_addr = n;
            #1 check(imem_rdata, program_words[n], "lectura de vuelta");
        end
        imem_addr = 10'd30;   #1 check(imem_rdata, 32'd0, "direccion 30 (sin escribir)");
        imem_addr = 10'd1023; #1 check(imem_rdata, 32'd0, "direccion 1023 (sin escribir)");

        fase = 2;   // Reset = 0 y Run = 0, sin pulsar Step durante 50 ciclos
        reset_sw = 1'b0;
        repeat (50) @(negedge clk);
        check(current_pc, 32'd0, "PC");
        check_regs(0, "registros distintos de 0");

        fase = 3;   // Paso a paso: 23 pulsaciones de Step, cada una con rebotes
        //   PC    reg valor instrucción (reg 0 = sin escritura)
        step(1,    1,  15,   "#1  MOVI $1, 15 (tabla de la plantilla)");
        step(2,    2,  20,   "#2  MOVI $2, 20");
        step(3,    3,  50,   "#3  MOVI $3, 50");
        step(4,    4,  5,    "#4  MOVI $4, 5");
        step(5,    5,  2,    "#5  MOVI $5, 2 (tabla de la plantilla)");
        step(6,    6,  35,   "#6  ADD $6, $1, $2 (tabla de la plantilla)");
        step(7,    7,  35,   "#7  SUB $7, $3, $1");
        step(8,    8,  1000, "#8  MUL $8, $2, $3");
        step(9,    9,  2,    "#9  DIV $9, $3, $2 (tabla de la plantilla)");
        step(10,   1,  25,   "#10 ADDI $1, $1, 10");
        step(11,   2,  16,   "#11 SUBI $2, $2, 4");
        step(12,   10, 40,   "#12 ADD $10, $6, $4");
        step(13,   11, 70,   "#13 MUL $11, $6, $5");
        step(14,   12, 20,   "#14 DIV $12, $10, $5");
        step(15,   4,  25,   "#15 ADDI $4, $4, 20");
        step(16,   13, -25,  "#16 SUB $13, $4, $3");
        step(17,   14, 100,  "#17 MOVI $14, 100");
        step(18,   15, 125,  "#18 ADD $15, $14, $1");
        step(19,   3,  45,   "#19 SUBI $3, $3, 5");
        step(20,   16, 2000, "#20 MUL $16, $15, $2");
        step(21,   17, 26,   "#21 ADDI $17, $1, 1 (tabla de la plantilla)");
        step(1024, 0,  0,    "#22 JUMP 1024");
        step(1024, 0,  0,    "PC fuera de la IMEM: no hace nada");

        fase = 4;   // Los 32 registros por el instrumento 2
        for (n = 0; n < 32; n = n + 1) begin
            read_reg(n, value);
            check(value, final_regs[n], "registro final");
        end

        fase = 5;   // Reset y Run = 1: programa completo a reloj completo
        reset_sw = 1'b1;
        repeat (4) @(negedge clk);
        check_regs(0, "registros distintos de 0 tras el reset");

        measuring = 1'b1;
        run_sw    = 1'b1;
        reset_sw  = 1'b0;
        repeat (200) @(negedge clk);
        measuring = 1'b0;

        check(current_pc, 32'd1024, "PC al final (se queda en 1024)");
        check(div_cycles, DIV_WAIT + 1, "ciclos de la DIV #9 (DIV_WAIT + 1)");
        check(run_cycles, 20 + 2 * (DIV_WAIT + 1), "ciclos del programa (20 + 2 DIV)");
        check_regs(1, "registros distintos de lo esperado");
        run_sw = 1'b0;

        fase = 6;   // El programa de clase solo divide positivos: este prueba todos los signos y entre 0
        reset_sw = 1'b1;
        write_word(0, 32'b001010_00000_00001_1111111111111001);     // MOVI $1, -7
        write_word(1, 32'b001010_00000_00010_0000000000000010);     // MOVI $2, 2
        write_word(2, 32'b000000_00001_00010_00011_00000_011010);   // DIV  $3, $1, $2
        write_word(3, 32'b001010_00000_00100_1111111111111110);     // MOVI $4, -2
        write_word(4, 32'b000000_00001_00100_00101_00000_011010);   // DIV  $5, $1, $4
        write_word(5, 32'b000000_00010_00100_00110_00000_011010);   // DIV  $6, $2, $4
        write_word(6, 32'b000000_00001_00000_00111_00000_011010);   // DIV  $7, $1, $0
        write_word(7, 32'b001010_00000_01000_0000000000000111);     // MOVI $8, 7
        write_word(8, 32'b000000_01000_00100_01001_00000_011010);   // DIV  $9, $8, $4
        write_word(9, 32'b000010_00000000000000010000000000);       // JUMP 1024
        run_sw   = 1'b1;
        reset_sw = 1'b0;
        repeat (150) @(negedge clk);
        run_sw   = 1'b0;

        read_reg(3, value); check(value, -3, "$3 = -7 / 2 ");
        read_reg(5, value); check(value,  3, "$5 = -7 / -2");
        read_reg(6, value); check(value, -1, "$6 =  2 / -2");
        read_reg(7, value); check(value,  0, "$7 = -7 / 0 ");
        read_reg(9, value); check(value, -3, "$9 =  7 / -2");

        $finish;
    end

    // ---- Instrumentos y botón Step ----

    // Instrumento 1: escribe una palabra (un flanco con imem_we = 1).
    task write_word(input [9:0] a, input [31:0] w);
        begin
            @(negedge clk);
            imem_addr  = a;
            imem_wdata = w;
            imem_we    = 1'b1;
            @(negedge clk);
            imem_we    = 1'b0;
        end
    endtask

    // Instrumento 2: lee un registro.
    task read_reg(input [4:0] n_reg, output [31:0] v);
        begin
            reg_addr = n_reg;
            #1 v = reg_data;
        end
    endtask

    // Pulsación con rebotes: 3 saltos al pulsar y 3 al soltar, con 20 ciclos estables en medio.
    task press_step;
        integer b;
        begin
            for (b = 0; b < 3; b = b + 1) begin
                @(negedge clk) step_btn = 1'b1;
                @(negedge clk) step_btn = 1'b0;
            end
            step_btn = 1'b1;
            repeat (20) @(negedge clk);
            for (b = 0; b < 3; b = b + 1) begin
                @(negedge clk) step_btn = 1'b0;
                @(negedge clk) step_btn = 1'b1;
            end
            step_btn = 1'b0;
            repeat (20) @(negedge clk);
        end
    endtask

    // ---- Impresión de resultados ----

    // Cuenta los registros distintos de 0 o, con use_final = 1, de final_regs.
    task check_regs(input use_final, input [8*44:1] what);
        integer r, wrong;
        begin
            wrong = 0;
            for (r = 0; r < 32; r = r + 1) begin
                read_reg(r, value);
                if (value !== (use_final ? final_regs[r] : 32'd0))
                    wrong = wrong + 1;
            end
            check(wrong, 32'd0, what);
        end
    endtask

    // Una pulsación debe ejecutar exactamente una instrucción y dejar want en el registro dest.
    task step(input [31:0] want_pc, input [4:0] dest, input [31:0] want, input [8*44:1] what);
        integer before;
        begin
            before = advances;
            press_step;
            read_reg(dest, value);
            imprimir(advances - before === 1 && current_pc === want_pc && value === want, value, want, what);
        end
    endtask

    task check(input [31:0] got, want, input [8*44:1] what);
        imprimir(got === want, got, want, what);
    endtask

    task imprimir(input ok, input [31:0] got, want, input [8*44:1] what);
        $display("fase %0d  PC=%-4d  imem_addr=%-4d  reg_addr=%-2d  valor=%-9d  esperado=%-9d  %s  %0s",
                 fase, current_pc, imem_addr, reg_addr, $signed(got), $signed(want), ok ? "OK   " : "ERROR", what);
    endtask

endmodule
