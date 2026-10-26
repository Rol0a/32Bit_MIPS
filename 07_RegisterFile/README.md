# 07 — Banco de Registros (RegisterFile)

**Entrega 3 · Ejercicios 3–4** · Estado: pendiente

## Objetivo
32 registros de 32 bits con dos puertos de lectura asíncrona y un puerto de escritura síncrona. `$0` siempre vale 0.

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `clk` | input | 1 | Reloj del sistema |
| `reset` | input | 1 | Reinicio activo en alto |
| `RegWrite` | input | 1 | Habilita escritura |
| `read_reg1` | input | 5 | Registro a leer 1 |
| `read_reg2` | input | 5 | Registro a leer 2 |
| `write_reg` | input | 5 | Registro a escribir |
| `write_data` | input | 32 | Dato a escribir |
| `read_data1` | output | 32 | Valor del registro leído 1 |
| `read_data2` | output | 32 | Valor del registro leído 2 |

## Reglas
- Arreglo `reg [31:0] registers [0:31];`
- **Lectura asíncrona:** `assign read_data1 = registers[read_reg1];` (ídem `read_data2`).
- **Escritura síncrona** en `posedge clk` cuando `RegWrite = 1` **y** `write_reg != 0`.
- **`$0` = 0 siempre:** nunca se escribe (alternativa: forzar la lectura de `$0` a 0).
- **Reset:** pone todos los registros en 0 (en `posedge clk`, igual que el PC).

## Testbench (`RegisterFile_tb.v`)
- `reset = 1` al inicio y luego `reset = 0`.
- Escribir en registros distintos de `$0`; intentar escribir en `$0` y comprobar que sigue en 0.
- Comprobar que con `RegWrite = 0` no se escribe.
- Leer por ambos puertos y mostrar los registros después de cada escritura (acceso jerárquico `uut.registers[i]`):
  `$display("R1=%0d, R2=%0d, R3=%0d, R0=%0d", uut.registers[1], uut.registers[2], uut.registers[3], uut.registers[0]);`
- `$dumpfile("RegisterFile_tb.vcd")` y `$dumpvars(0, RegisterFile_tb)`.

## Casos de prueba (propuestos)

| # | Caso |
|---|---|
| 1 | Tras reset, todos los registros leen 0 |
| 2 | Escritura en R1, R2, R3 y lectura por ambos puertos |
| 3 | Intento de escritura en `$0` → sigue en 0 |
| 4 | `RegWrite = 0` → no hay escritura |
| 5 | Lectura asíncrona: cambia `read_reg` sin flanco de reloj y la salida cambia de inmediato |
| 6 | Escritura en R31 (límite superior) |

## Comandos
```powershell
iverilog -o RegisterFile_tb.vvp RegisterFile.v RegisterFile_tb.v
vvp RegisterFile_tb.vvp
gtkwave RegisterFile_tb.vcd
```
