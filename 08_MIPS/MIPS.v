// MIPS.v — Procesador MIPS monociclo: instancia los seis módulos y los conecta con assign.
// Especificación y decisiones: README.md de esta carpeta.
`timescale 1ns / 1ps

module MIPS (
    input         clk,
    input         reset,         // síncrono, activo en alto: PC = 0 y registros = 0
    output [31:0] current_pc,    // dirección de la instrucción en ejecución
    output [31:0] instruction,   // instrucción en ejecución
    output [31:0] alu_result     // resultado de la ALU
);

    // Siguiente PC
    wire [31:0] pc_plus1, next_pc;

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
    wire [31:0] read_data1, read_data2, imm_ext, src2, write_data;
    wire [4:0]  write_reg;
    wire        zero;            // ninguna instrucción la usa

    // ---- Módulos ----
    PC pc_reg (
        .clk       (clk),
        .reset     (reset),
        .next_pc   (next_pc),
        .current_pc(current_pc)
    );

    IMEM imem (
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
        .RegWrite  (RegWrite),
        .read_reg1 (rs),
        .read_reg2 (rt),
        .write_reg (write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
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

    // Write-back: sin memoria de datos, siempre el resultado de la ALU
    assign write_data = alu_result;

    // Siguiente PC, por palabra: PC + 1 o la dirección del salto
    assign pc_plus1 = current_pc + 32'd1;
    assign next_pc  = Jump ? {6'b000000, address} : pc_plus1;

endmodule
