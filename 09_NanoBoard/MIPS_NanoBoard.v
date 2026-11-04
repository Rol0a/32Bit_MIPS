// MIPS_NanoBoard.v — Procesador MIPS monociclo para la NanoBoard-3000XN (Altium Designer 14.3).
// Archivo único: es 08_MIPS más escritura de la IMEM (instrumento 1), lectura de registros
// (instrumento 2) y ejecución con Run/Step. Uso, decisiones y pruebas: README.md de esta carpeta.
//
//   1. Tabla de la ISA    4. PC            7. ALUControl
//   2. MIPS_NanoBoard     5. IMEM          8. ALU
//   3. RunControl         6. ControlUnit   9. RegisterFile
`timescale 1ns / 1ps


// ==== 1. Tabla de la ISA: cada código se define solo aquí ====================

// opcode: instruction[31:26] -> ControlUnit
`define OP_RTYPE    6'b000000    // ADD, SUB, MUL, DIV, MOV: la operación va en funct
`define OP_JUMP     6'b000010    // J    address
`define OP_ADDI     6'b001000    // ADDI rt, rs, imm
`define OP_SUBI     6'b001001    // SUBI rt, rs, imm
`define OP_MOVI     6'b001010    // MOVI rt, imm

// funct: instruction[5:0] de las tipo R -> ALUControl
`define FUNCT_ADD   6'b100000    // ADD rd, rs, rt
`define FUNCT_SUB   6'b100010    // SUB rd, rs, rt
`define FUNCT_MUL   6'b011000    // MUL rd, rs, rt
`define FUNCT_DIV   6'b011010    // DIV rd, rs, rt
`define FUNCT_MOV   6'b100011    // MOV rd, rs

// ALUOp: ControlUnit -> ALUControl. Los cuatro valores están usados: otra operación tipo I
// necesita ensanchar ALUOp a 3 bits.
`define ALUOP_MOVI  2'b00        // pasar el inmediato
`define ALUOP_ADDI  2'b01        // sumar el inmediato
`define ALUOP_R     2'b10        // tipo R: la operación sale de funct
`define ALUOP_SUBI  2'b11        // restar el inmediato

// alu_control: ALUControl -> ALU
`define ALU_PASS_B  4'b0000      // result = src2           (MOVI)
`define ALU_PASS_A  4'b0001      // result = src1           (MOV)
`define ALU_ADD     4'b0010      // result = src1 + src2    (ADD, ADDI)
`define ALU_SUB     4'b0110      // result = src1 - src2    (SUB, SUBI)
`define ALU_MUL     4'b1000      // result = src1 * src2    (MUL, 32 bits bajos)
`define ALU_DIV     4'b1001      // result = src1 / src2    (DIV, con signo; entre 0 da 0)
`define ALU_NONE    4'b1111      // no definido: result = 0


// ==== 2. MIPS_NanoBoard: módulo superior, los pines que ve Altium =============
module MIPS_NanoBoard #(
    parameter IMEM_WORDS    = 1024,  // bajarlo (p. ej. 256) si el diseño no cabe en la FPGA
    parameter DIV_WAIT      = 16,    // ciclos extra de una DIV (máximo 255); subirlo si sube el reloj
    parameter DEBOUNCE_BITS = 18     // Step estable 2^18 ciclos = 13 ms a 20 MHz
) (
    input         clk,           // reloj de la placa

    // Controles
    input         reset_sw,      // 1 = PC y registros a 0; en 1 mientras se escribe el programa
    input         run_sw,        // 1 = corre libre; 0 = solo avanza con Step
    input         step_btn,      // cada pulsación ejecuta una instrucción (con Run = 0)

    // Memory Instrument 1: instrucciones
    input  [9:0]  imem_addr,     // dirección de la palabra (0 a 1023)
    input  [31:0] imem_wdata,    // instrucción que se escribe
    input         imem_we,       // 1 = escribe imem_wdata en imem_addr en el flanco
    output [31:0] imem_rdata,    // palabra guardada en imem_addr

    // Memory Instrument 2: resultados
    input  [4:0]  reg_addr,      // número de registro (0 a 31)
    output [31:0] reg_data,      // valor del registro elegido

    // Observación (opcionales)
    output [31:0] current_pc,
    output [31:0] instruction
);

    // Control de ejecución
    wire        reset;           // reset_sw sincronizado con el reloj
    wire        slow_op;         // 1 = la instrucción actual es una DIV
    wire        advance;         // 1 = en este flanco termina la instrucción

    // Siguiente PC
    wire [31:0] pc_plus1, jump_target, next_pc;
    wire        pc_outside;      // 1 = el PC salió de la IMEM: fin del programa

    // Campos de la instrucción
    wire [5:0]  opcode, funct;
    wire [4:0]  rs, rt, rd;
    wire [15:0] immediate;
    wire [25:0] address;

    // Señales de control
    wire        RegDst, ALUSrc, RegWrite, Jump;
    wire [1:0]  ALUOp;
    wire [3:0]  alu_control;

    // Datos
    wire [31:0] read_data1, read_data2, imm_ext, src2, alu_result, write_data;
    wire [4:0]  write_reg;
    wire        zero;            // ninguna instrucción la usa todavía
    wire        write_now;       // RegWrite y advance: el banco escribe en este flanco

    // ---- Módulos ----
    RunControl #(
        .DEBOUNCE_BITS(DEBOUNCE_BITS),
        .SLOW_WAIT    (DIV_WAIT)
    ) run_ctl (
        .clk     (clk),
        .reset_sw(reset_sw),
        .run_sw  (run_sw),
        .step_btn(step_btn),
        .slow_op (slow_op),
        .reset   (reset),
        .advance (advance)
    );

    PC pc_reg (
        .clk       (clk),
        .reset     (reset),
        .enable    (advance),
        .next_pc   (next_pc),
        .current_pc(current_pc)
    );

    IMEM #(
        .WORDS(IMEM_WORDS)
    ) imem (
        .clk        (clk),
        .we         (imem_we),
        .waddr      (imem_addr),
        .wdata      (imem_wdata),
        .wport_data (imem_rdata),
        .addr       (current_pc),
        .instruction(instruction)
    );

    ControlUnit cu (
        .opcode  (opcode),
        .RegDst  (RegDst),
        .ALUSrc  (ALUSrc),
        .RegWrite(RegWrite),
        .Jump    (Jump),
        .ALUOp   (ALUOp)
    );

    ALUControl aluc (
        .ALUOp      (ALUOp),
        .funct      (funct),
        .alu_control(alu_control)
    );

    RegisterFile rf (
        .clk       (clk),
        .reset     (reset),
        .RegWrite  (write_now),
        .read_reg1 (rs),
        .read_reg2 (rt),
        .write_reg (write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .dbg_reg   (reg_addr),
        .dbg_data  (reg_data)
    );

    ALU alu (
        .src1       (read_data1),
        .src2       (src2),
        .alu_control(alu_control),
        .result     (alu_result),
        .zero       (zero)
    );

    // ---- Interconexión: solo assign ----

    // Campos de la instrucción (shamt no se usa: no hay desplazamientos)
    assign opcode    = instruction[31:26];
    assign rs        = instruction[25:21];
    assign rt        = instruction[20:16];
    assign rd        = instruction[15:11];
    assign funct     = instruction[5:0];
    assign immediate = instruction[15:0];
    assign address   = instruction[25:0];

    // Extensión de signo
    assign imm_ext = {{16{immediate[15]}}, immediate};

    // Muxes RegDst y ALUSrc
    assign write_reg = RegDst ? rd : rt;
    assign src2      = ALUSrc ? imm_ext : read_data2;

    // Write-back con el mismo enable que el PC (plantilla 3.3)
    assign write_data = alu_result;
    assign write_now  = RegWrite & advance;

    // Operaciones lentas: esperan DIV_WAIT ciclos más. Otra se agrega con || (alu_control == ...).
    assign slow_op = (alu_control == `ALU_DIV);

    // Siguiente PC, por palabra. Si ya salió de la IMEM se queda ahí: fin del programa.
    assign pc_plus1    = current_pc + 32'd1;
    assign jump_target = {6'b000000, address};
    assign pc_outside  = (current_pc >= IMEM_WORDS);
    assign next_pc     = pc_outside ? current_pc  :
                         Jump       ? jump_target :
                                      pc_plus1;

endmodule


// ==== 3. RunControl: en qué flancos avanza el procesador ======================
// Run = 1: avanza cada ciclo, salvo mientras una DIV espera. Run = 0: un ciclo por pulsación de Step.
module RunControl #(
    parameter DEBOUNCE_BITS = 18,  // el botón debe quedarse estable 2^DEBOUNCE_BITS ciclos
    parameter SLOW_WAIT     = 16   // ciclos extra de una instrucción lenta (máximo 255)
) (
    input  clk,
    input  reset_sw,               // interruptor Reset (activo en alto)
    input  run_sw,                 // interruptor Run
    input  step_btn,               // botón Step
    input  slow_op,                // 1 = la instrucción actual necesita SLOW_WAIT ciclos más
    output reset,                  // reset sincronizado: va al PC y al banco
    output advance                 // 1 = en este flanco termina la instrucción
);

    // Paso 1: sincronizar las entradas externas con dos flip-flops en serie.
    reg [1:0] reset_sync, run_sync, step_sync;

    always @(posedge clk) begin
        reset_sync <= {reset_sync[0], reset_sw};
        run_sync   <= {run_sync[0],   run_sw};
        step_sync  <= {step_sync[0],  step_btn};
    end

    assign reset = reset_sync[1];
    wire   run   = run_sync[1];
    wire   step  = step_sync[1];

    // Paso 2: filtrar rebotes. step_clean cambia tras 2^DEBOUNCE_BITS ciclos con el valor nuevo.
    reg [DEBOUNCE_BITS-1:0] bounce_count;
    reg                     step_clean;

    always @(posedge clk) begin
        if (reset || step == step_clean) begin
            bounce_count <= 0;                     // sin cambio pendiente
            if (reset)
                step_clean <= 1'b0;
        end
        else if (&bounce_count) begin              // la cuenta llegó al máximo
            step_clean   <= step;                  // el valor nuevo es estable
            bounce_count <= 0;
        end
        else
            bounce_count <= bounce_count + 1'b1;
    end

    // Paso 3: un solo ciclo por pulsación, aunque el botón se mantenga pulsado.
    reg  step_prev;
    wire step_pulse;

    always @(posedge clk) begin
        if (reset)
            step_prev <= 1'b0;
        else
            step_prev <= step_clean;
    end

    assign step_pulse = step_clean & ~step_prev;

    // Paso 4: una instrucción lenta solo termina cuando settle llega a SLOW_WAIT.
    reg  [7:0] settle;
    wire       slow_waiting;

    always @(posedge clk) begin
        if (reset || advance)
            settle <= 8'd0;
        else if (settle != SLOW_WAIT)
            settle <= settle + 8'd1;
    end

    assign slow_waiting = slow_op && (settle != SLOW_WAIT);

    // Mismo enable para todo el procesador.
    assign advance = (run | step_pulse) & ~slow_waiting;

endmodule


// ==== 4. PC: reset síncrono a 0; sin enable conserva su valor =================
module PC (
    input             clk,
    input             reset,         // 1 = vuelve a la dirección 0 (tiene prioridad)
    input             enable,        // 1 = carga next_pc en este flanco
    input      [31:0] next_pc,       // dirección siguiente
    output reg [31:0] current_pc     // dirección actual
);

    always @(posedge clk) begin
        if (reset)
            current_pc <= 32'd0;
        else if (enable)
            current_pc <= next_pc;
    end

endmodule


// ==== 5. IMEM: RAM distribuida de doble puerto ================================
// Puerto del instrumento: escribe en el flanco y lee de vuelta. Puerto del procesador: lee sin
// esperar al reloj. Fuera de la memoria lee 0, una NOP.
module IMEM #(
    parameter WORDS = 1024               // máximo 1024: la dirección del instrumento tiene 10 bits
) (
    input         clk,
    input         we,                    // 1 = escribe wdata en waddr en el flanco
    input  [9:0]  waddr,                 // dirección del instrumento
    input  [31:0] wdata,                 // instrucción que escribe el instrumento
    output [31:0] wport_data,            // palabra guardada en waddr
    input  [31:0] addr,                  // dirección que pide el procesador (el PC)
    output [31:0] instruction            // instrucción leída
);

    reg [31:0] memory [0:WORDS-1];
    integer i;

    // La RAM de la FPGA arranca en 0: este initial hace que la simulación se comporte igual.
    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            memory[i] = 32'd0;
    end

    always @(posedge clk) begin
        if (we && waddr < WORDS)
            memory[waddr] <= wdata;
    end

    assign wport_data  = (waddr < WORDS) ? memory[waddr]      : 32'd0;
    assign instruction = (addr  < WORDS) ? memory[addr[9:0]]  : 32'd0;

endmodule


// ==== 6. ControlUnit: opcode -> señales de control. Combinacional =============
module ControlUnit (
    input      [5:0] opcode,     // instruction[31:26]
    output reg       RegDst,     // 1 = escribe en rd (tipo R); 0 = en rt (tipo I)
    output reg       ALUSrc,     // 1 = src2 es el inmediato
    output reg       RegWrite,   // 1 = escribe el resultado en el banco
    output reg       Jump,       // 1 = salto: PC = address
    output reg [1:0] ALUOp       // clase de operación para ALUControl
);

    always @(*) begin
        // Por defecto no escribe ni salta; cada rama cambia solo lo que necesita.
        RegDst   = 1'b0;
        ALUSrc   = 1'b0;
        RegWrite = 1'b0;
        Jump     = 1'b0;
        ALUOp    = `ALUOP_MOVI;

        case (opcode)
            `OP_RTYPE: begin            // rd = rs (funct) rt
                RegDst   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = `ALUOP_R;
            end

            `OP_MOVI: begin             // rt = imm
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = `ALUOP_MOVI;
            end

            `OP_ADDI: begin             // rt = rs + imm
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = `ALUOP_ADDI;
            end

            `OP_SUBI: begin             // rt = rs - imm
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = `ALUOP_SUBI;
            end

            `OP_JUMP: begin             // PC = address; no escribe registros
                Jump     = 1'b1;
            end

            default: ;                  // opcode no definido: NOP
        endcase
    end

endmodule


// ==== 7. ALUControl: ALUOp + funct -> operación de la ALU. Combinacional ======
module ALUControl (
    input      [1:0] ALUOp,          // clase de operación, de ControlUnit
    input      [5:0] funct,          // instruction[5:0]: solo cuenta en tipo R
    output reg [3:0] alu_control     // operación para la ALU
);

    always @(*) begin
        // Por defecto, «no definido»: una tipo R con funct desconocido escribe 0 en rd.
        alu_control = `ALU_NONE;

        case (ALUOp)
            `ALUOP_MOVI: alu_control = `ALU_PASS_B;
            `ALUOP_ADDI: alu_control = `ALU_ADD;
            `ALUOP_SUBI: alu_control = `ALU_SUB;

            `ALUOP_R: begin
                case (funct)
                    `FUNCT_ADD: alu_control = `ALU_ADD;
                    `FUNCT_SUB: alu_control = `ALU_SUB;
                    `FUNCT_MUL: alu_control = `ALU_MUL;
                    `FUNCT_DIV: alu_control = `ALU_DIV;
                    `FUNCT_MOV: alu_control = `ALU_PASS_A;
                    default:    ;           // funct no definido: ALU_NONE
                endcase
            end

            default: ;                      // ALUOp con x/z (solo en simulación)
        endcase
    end

endmodule


// ==== 8. ALU: 32 bits con signo (complemento a 2). Combinacional ==============
module ALU (
    input      [31:0] src1,          // $rs
    input      [31:0] src2,          // $rt o el inmediato
    input      [3:0]  alu_control,   // operación, de ALUControl
    output reg [31:0] result,        // va al banco
    output            zero           // 1 cuando result == 0
);

    // División binaria de |a| entre |b|, un bit del cociente por vuelta. Igual que
    // $signed(a) / $signed(b), pero cualquier sintetizador la acepta. Entre 0 da 0.
    function [31:0] signed_div;
        input [31:0] a, b;
        reg   [31:0] abs_a, abs_b, quotient;
        reg   [32:0] remainder;          // 33 bits: la resta de prueba puede dar negativa
        reg   [32:0] trial;              // remainder - |b|
        integer      k;
        begin
            abs_a     = a[31] ? -a : a;
            abs_b     = b[31] ? -b : b;
            remainder = 33'd0;
            quotient  = 32'd0;

            for (k = 31; k >= 0; k = k - 1) begin
                remainder = {remainder[31:0], abs_a[k]};    // baja el siguiente bit de |a|
                trial     = remainder - {1'b0, abs_b};      // resta de prueba
                if (trial[32] == 1'b0) begin                // no dio negativa: |b| cabe
                    remainder   = trial;
                    quotient[k] = 1'b1;
                end
            end

            if (b == 32'd0)
                signed_div = 32'd0;                         // entre cero: 0
            else if (a[31] != b[31])
                signed_div = -quotient;                     // signos distintos
            else
                signed_div = quotient;
        end
    endfunction

    always @(*) begin
        result = 32'd0;                  // por defecto (ALU_NONE): 0

        case (alu_control)
            `ALU_PASS_B: result = src2;
            `ALU_PASS_A: result = src1;
            `ALU_ADD:    result = src1 + src2;       // desborde: da la vuelta (módulo 2^32)
            `ALU_SUB:    result = src1 - src2;
            `ALU_MUL:    result = src1 * src2;       // 32 bits bajos del producto
            `ALU_DIV:    result = signed_div(src1, src2);
            default:     ;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule


// ==== 9. RegisterFile: 32 registros, 3 puertos de lectura y 1 de escritura ====
module RegisterFile (
    input         clk,
    input         reset,         // 1 = los 32 registros a 0 en el flanco (prioridad)
    input         RegWrite,      // 1 = escribe write_data en write_reg en el flanco
    input  [4:0]  read_reg1,     // rs
    input  [4:0]  read_reg2,     // rt
    input  [4:0]  write_reg,     // destino: rd o rt
    input  [31:0] write_data,    // resultado de la ALU
    output [31:0] read_data1,    // contenido de rs
    output [31:0] read_data2,    // contenido de rt
    input  [4:0]  dbg_reg,       // registro que pide el instrumento 2
    output [31:0] dbg_data       // contenido de dbg_reg
);

    reg [31:0] registers [0:31];
    integer i;

    // Leer $0 da 0 sin consultar el arreglo.
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 : registers[read_reg2];
    assign dbg_data   = (dbg_reg   == 5'd0) ? 32'd0 : registers[dbg_reg];

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end
        else if (RegWrite && write_reg != 5'd0) begin
            registers[write_reg] <= write_data;       // $0 nunca se escribe
        end
    end

endmodule
