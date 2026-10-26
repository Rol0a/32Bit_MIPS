# 06 — Control de la ALU (ALUControl)

**Entrega 3 · Ejercicios 1–2** · Estado: pendiente

## Objetivo
Traducir `ALUOp` (de la Unidad de Control) y el campo `funct` (de instrucciones R) en la operación exacta de la ALU.

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `ALUOp` | input | 2 | Señal de la Unidad de Control |
| `funct` | input | 6 | Campo `funct` de instrucciones tipo R |
| `alu_control` | output reg | 4 | Operación para la ALU |

## Tabla de verdad (enunciado)

| ALUOp | funct | Operación | `alu_control` |
|---|---|---|---|
| `00` | X | MOVI | `0000` |
| `10` | `100000` | ADD | `0010` |
| `10` | `100100` | SUB | `0110` |
| `10` | `100001` | MULT | `1000` |
| `10` | `100010` | DIV | `1001` |
| `10` | `100011` | MOV | `0001` |

Extensión propuesta (decisión 2 del README principal), necesaria para ADDI/SUBI:

| ALUOp | funct | Operación | `alu_control` |
|---|---|---|---|
| `01` | X | ADDI → suma | `0010` |
| `11` | X | SUBI → resta | `0110` |

> ⚠ Los códigos `funct` de esta tabla **no coinciden** con `docs/Tabla Opcode y Funct.xlsx`
> (decisión 1 del README principal). Usar los mismos códigos que el programa de la IMEM.

## Implementación
- `always @(*)` con `case (ALUOp)` y, dentro de `10`, `case (funct)`.
- Valor por defecto para `alu_control` (funct no definido).

## Testbench (`ALUControl_tb.v`)
- Variar `ALUOp` y `funct` para ADD, SUB, MULT, DIV, MOV, MOVI y ADDI (y SUBI si se adopta la extensión).
- Verificar `alu_control` contra lo esperado.
- Formato: `$display("ALUOp=%b, funct=%b -> alu_control=%b", ALUOp, funct, alu_control);`
- `$dumpfile("ALUControl_tb.vcd")` y `$dumpvars(0, ALUControl_tb)`.

## Casos de prueba
Una fila por instrucción de la tabla anterior + un `funct` no definido con `ALUOp = 10`.

## Comandos
```powershell
iverilog -o ALUControl_tb.vvp ALUControl.v ALUControl_tb.v
vvp ALUControl_tb.vvp
gtkwave ALUControl_tb.vcd
```
