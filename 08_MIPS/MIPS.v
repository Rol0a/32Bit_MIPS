// =============================================================================
// MIPS.v — Procesador MIPS monociclo (datapath completo)
// Módulo superior: instancia los seis módulos del procesador y los conecta. La
// lógica que no tiene módulo propio (campos de la instrucción, extensión de
// signo, muxes RegDst, ALUSrc y Jump, PC + 1 y write-back) son solo assign.
// Especificación, decisiones y casos de prueba: README.md de esta carpeta.
// =============================================================================
`timescale 1ns / 1ps

module MIPS (
    input         clk,           // reloj del sistema: PC y banco de registros
    input         reset,         // reinicio síncrono, activo en alto: PC = 0 y registros = 0
    output [31:0] current_pc,    // dirección de la instrucción en ejecución
    output [31:0] instruction,   // instrucción en ejecución
    output [31:0] alu_result     // resultado de la ALU: lo que se escribe en el banco
);

    // ---- Siguiente PC ------------------------------------------------------
    wire [31:0] pc_plus1;      // dirección secuencial: PC + 1
    wire [31:0] next_pc;       // dirección que el PC carga en el siguiente flanco

    // ---- Campos de la instrucción ------------------------------------------
    // Se cortan todos aunque cada formato use solo algunos: los módulos y los
    // muxes eligen cuál importa. shamt (instruction[10:6]) no se usa: no hay
    // desplazamientos.
    wire [5:0]  opcode;        // [31:26] -> ControlUnit
    wire [4:0]  rs;            // [25:21] -> read_reg1
    wire [4:0]  rt;            // [20:16] -> read_reg2 y mux RegDst
    wire [4:0]  rd;            // [15:11] -> mux RegDst
    wire [5:0]  funct;         // [5:0]   -> ALUControl
    wire [15:0] immediate;     // [15:0]  -> extensión de signo
    wire [25:0] address;       // [25:0]  -> mux Jump

    // ---- Señales de control ------------------------------------------------
    wire        RegDst;        // 1 = escribe en rd; 0 = en rt
    wire        ALUSrc;        // 1 = src2 es el inmediato; 0 = read_data2
    wire        RegWrite;      // 1 = el banco guarda write_data en el flanco
    wire        Jump;          // 1 = next_pc = address
    wire [1:0]  ALUOp;         // clase de operación para ALUControl
    wire [3:0]  alu_control;   // operación de la ALU

    // ---- Datos -------------------------------------------------------------
    wire [31:0] read_data1;    // $rs: siempre es src1
    wire [31:0] read_data2;    // $rt: src2 de las tipo R
    wire [31:0] imm_ext;       // inmediato extendido con signo a 32 bits
    wire [31:0] src2;          // segundo operando de la ALU
    wire [4:0]  write_reg;     // registro destino
    wire [31:0] write_data;    // dato que se escribe en el banco
    wire        zero;          // 1 cuando alu_result == 0; ninguna instrucción la usa

    // ======================================================================
    // Módulos. PC y banco de registros comparten clk y reset: los dos son
    // síncronos y se actualizan en el mismo flanco de subida.
    // ======================================================================

    // PC: guarda la dirección actual y carga next_pc en cada flanco.
    PC pc_reg (
        .clk       (clk),
        .reset     (reset),
        .next_pc   (next_pc),
        .current_pc(current_pc)
    );

    // IMEM: lee de forma combinacional la instrucción apuntada por el PC.
    IMEM imem (
        .addr       (current_pc),
        .instruction(instruction)
    );

    // ControlUnit: opcode -> señales de control.
    ControlUnit cu (
        .opcode  (opcode),
        .RegDst  (RegDst),
        .ALUSrc  (ALUSrc),
        .RegWrite(RegWrite),
        .Jump    (Jump),
        .ALUOp   (ALUOp)
    );

    // ALUControl: ALUOp + funct -> operación de la ALU.
    ALUControl aluc (
        .ALUOp      (ALUOp),
        .funct      (funct),
        .alu_control(alu_control)
    );

    // Banco de registros: lee rs y rt en el mismo ciclo y escribe el
    // resultado en el flanco que termina la instrucción. El nombre corto de
    // la instancia permite leer el arreglo desde el testbench con
    // uut.rf.registers[i].
    RegisterFile rf (
        .clk       (clk),
        .reset     (reset),
        .RegWrite  (RegWrite),
        .read_reg1 (rs),
        .read_reg2 (rt),
        .write_reg (write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // ALU: src1 es siempre $rs; src2 sale del mux ALUSrc.
    ALU alu (
        .src1       (read_data1),
        .src2       (src2),
        .alu_control(alu_control),
        .result     (alu_result),
        .zero       (zero)
    );

    // ======================================================================
    // Interconexión: solo assign, todo combinacional.
    // ======================================================================

    // Campos de la instrucción.
    assign opcode    = instruction[31:26];
    assign rs        = instruction[25:21];
    assign rt        = instruction[20:16];
    assign rd        = instruction[15:11];
    assign funct     = instruction[5:0];
    assign immediate = instruction[15:0];
    assign address   = instruction[25:0];

    // Extensión de signo: se copia el bit 15 en los 16 bits altos, así
    // movi $2, -3 carga 0xFFFFFFFD. Con ceros cargaría 65533.
    assign imm_ext = {{16{immediate[15]}}, immediate};

    // Mux RegDst: las tipo R escriben en rd; las tipo I, en rt.
    assign write_reg = RegDst ? rd : rt;

    // Mux ALUSrc: el segundo operando es un registro (R) o el inmediato (I).
    assign src2 = ALUSrc ? imm_ext : read_data2;

    // Write-back: sin memoria de datos, siempre se escribe el resultado de la
    // ALU. El banco solo lo guarda si RegWrite = 1.
    assign write_data = alu_result;

    // Siguiente PC. Direccionamiento por palabra: la siguiente instrucción
    // está en PC + 1. El salto usa la dirección de palabra del campo address,
    // completada con ceros hasta 32 bits.
    assign pc_plus1 = current_pc + 32'd1;
    assign next_pc  = Jump ? {6'b000000, address} : pc_plus1;

endmodule
