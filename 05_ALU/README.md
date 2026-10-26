# 05 — Unidad Aritmético-Lógica (ALU)

**Entrega 2 · Ejercicio 2** · Estado: pendiente

## Objetivo
Realizar suma, resta, multiplicación y división sobre dos operandos de 32 bits e indicar si el resultado es cero.

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `src1` | input | 32 | Primer operando (registro) |
| `src2` | input | 32 | Segundo operando (registro o inmediato) |
| `alu_control` | input | 4 | Operación a realizar |
| `result` | output reg | 32 | Resultado |
| `zero` | output | 1 | 1 cuando `result == 0` |

## Codificación de `alu_control`
Se adopta desde ya la codificación que genera ALUControl (entrega 3), para no rehacer la ALU después:

| `alu_control` | Operación |
|---|---|
| `0000` | `result = src2` (MOVI) |
| `0001` | `result = src1` (MOV) |
| `0010` | `result = src1 + src2` |
| `0110` | `result = src1 - src2` |
| `1000` | `result = src1 * src2` |
| `1001` | `result = src1 / src2` |
| otro | por definir (propuesta: `0`) |

## Decisiones a documentar (decisión 4 del README principal)
- **Signo:** ¿división con signo? (propuesta: `$signed(src1) / $signed(src2)`).
- **División entre cero:** qué devuelve (propuesta: `0`, para no propagar `x`).
- **Control no definido:** qué devuelve.

## Implementación
- `always @(*)` con `case (alu_control)` y valor por defecto para `result`.
- `assign zero = (result == 32'b0);`

## Testbench (`ALU_tb.v`)
- Varias combinaciones por operación: positivos, negativos, cero y desbordes.
- Mostrar con `$signed()` cuando aplique. Formato sugerido:
  `ctl=0010 src1=50 src2=15 -> result=65 (0x00000041) zero=0`
- `$dumpfile("ALU_tb.vcd")` y `$dumpvars(0, ALU_tb)`.

## Casos de prueba (mínimos de la plantilla)

| # | Caso | Ejemplo |
|---|---|---|
| 1 | Suma de dos positivos pequeños | |
| 2 | Resta positiva | `src1 > src2` |
| 3 | Resta con resultado 0 | `src1 = src2` → `zero = 1` |
| 4 | Resta negativa | `src1 < src2` (complemento a 2) |
| 5 | Multiplicación de positivos pequeños | |
| 6 | Multiplicación con overflow | `65536 × 65536 = 0` |
| 7 | División exacta | |
| 8 | División con residuo | `7 / 2 = 3` |
| 9 | División entre cero | según decisión |
| 10 | Suma con overflow | `0xFFFFFFFF + 1 = 0` |
| 11 | Operandos en cero | `0 + 0` → `zero = 1` |
| 12 | División con negativo | `-20 / 4` |

## Capturas (`capturas/`)
- Consola: comandos y una línea por prueba.
- GTKWave: `alu_control`, operandos y resultado en **Signed Decimal** o hex, `zero`.

## Comandos
```powershell
iverilog -o ALU_tb.vvp ALU.v ALU_tb.v
vvp ALU_tb.vvp
gtkwave ALU_tb.vcd
```
