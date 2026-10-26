# 04 — Unidad de Control (ControlUnit)

**Entrega 2 · Ejercicio 1** · Estado: pendiente

## Objetivo
Decodificar el `opcode` y generar las señales que controlan el resto del procesador. Lógica combinacional.

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `opcode` | input | 6 | Código de operación |
| `RegDst` | output reg | 1 | 1 = destino `rd` (R), 0 = destino `rt` (I) |
| `ALUSrc` | output reg | 1 | 1 = segundo operando es el inmediato |
| `RegWrite` | output reg | 1 | Habilita escritura en el banco de registros |
| `Jump` | output reg | 1 | Salto incondicional |
| `ALUOp` | output reg | 2 | Clase de operación para ALUControl |

## Tabla de verdad
Valores del enunciado + propuesta para los «—» (ver decisiones 2 y 3 del README principal):

| Tipo | Opcode | RegDst | ALUSrc | RegWrite | Jump | ALUOp |
|---|---|---|---|---|---|---|
| R (ADD, SUB, MUL, DIV, MOV) | `000000` | 1 | 0 | 1 | 0 | `10` |
| MOVI | `001010` | 0 | 1 | 1 | 0 | `00` |
| ADDI | `001000` | 0 | 1 | 1 | 0 | `01` * |
| SUBI | `001001` | 0 | 1 | 1 | 0 | `11` * |
| JUMP | `000010` | 0 * | 0 * | 0 * | 1 | `00` * |
| No definido | otro | 0 | 0 | 0 | 0 | `00` |

\* propuesta, por confirmar.

## Implementación
- `always @(*)`: asignar **valores por defecto** a todas las salidas, luego `case (opcode)`.
- Un `default` del `case` que deje el procesador «seguro» (sin escribir ni saltar).

## Testbench (`ControlUnit_tb.v`)
- Cambiar el `opcode` cada ciclo (R, I y J como mínimo) y mostrar las señales.
- **Verificar** contra lo esperado (comparar y reportar OK/ERROR), no solo imprimir.
- Formato sugerido: `opcode=000000 -> RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10`
- `$dumpfile("ControlUnit_tb.vcd")` y `$dumpvars(0, ControlUnit_tb)`.

## Casos de prueba (mínimos de la plantilla)

| # | Caso | Opcode |
|---|---|---|
| 1 | Tipo R | `000000` |
| 2 | Tipo I: MOVI | `001010` |
| 3 | Tipo I: otra (ADDI / SUBI) | `001000` / `001001` |
| 4 | Tipo J | `000010` |
| 5 | Opcode no definido | p. ej. `111111` |
| 6 | Secuencia R → J → I | las señales siguen al opcode actual, sin arrastrar valores |

## Capturas (`capturas/`)
- Consola: comandos y una línea por opcode.
- GTKWave: `opcode` en binario y las cinco señales; todos los opcodes a la vista.

## Comandos
```powershell
iverilog -o ControlUnit_tb.vvp ControlUnit.v ControlUnit_tb.v
vvp ControlUnit_tb.vvp
gtkwave ControlUnit_tb.vcd
```
