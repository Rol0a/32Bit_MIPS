# 02 — Memoria de Instrucciones (IMEM)

**Entrega 1 · Ejercicio 2** · Estado: pendiente

## Objetivo
Memoria de solo lectura de 16 palabras de 32 bits con un programa de 10 instrucciones precargado.

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `addr` | input | 32 | Dirección de la instrucción |
| `instruction` | output | 32 | Instrucción leída |

## Comportamiento
- Arreglo `reg [31:0] memory [0:15];`
- Bloque `initial` con 10 instrucciones (mnemónico como comentario en cada línea).
- Lectura combinacional: `assign instruction = memory[addr[4:0]];`
  (ver decisión 5 del README principal sobre `addr[4:0]` vs `addr[3:0]`).

## Programa precargado (por definir)
Requisitos: al menos una instrucción **R**, una **I** y una **J**, usando solo instrucciones y códigos
de la tabla ISA del README principal. Las dos primeras están dadas por el enunciado.

| Dir | Instrucción (binario) | Mnemónico | Formato |
|---|---|---|---|
| 0 | `000000_00001_00010_00011_00000_100000` | `add $3, $1, $2` | R |
| 1 | `001000_01000_01001_0000000000001010` | `addi $9, $8, 10` | I |
| 2–9 | *por definir* | | |
| 10–15 | sin inicializar (`x`) | — | — |

> Antes de armar 2–9, cerrar la decisión 1 (códigos `funct`) del README principal.

## Testbench (`IMEM_tb.v`)
- Recorrer varias direcciones y mostrar la instrucción con `$display`.
- Separar los campos según el formato:
  - R: `opcode rs rt rd shamt funct`
  - I: `opcode rs rt immediate`
  - J: `opcode address`
- `$dumpfile("IMEM_tb.vcd")` y `$dumpvars(0, IMEM_tb)`.

## Casos de prueba (mínimos de la plantilla)

| # | Caso | Dir. |
|---|---|---|
| 1 | Primera instrucción | 0 |
| 2 | Una instrucción R-type | a elegir |
| 3 | Una instrucción I-type | a elegir |
| 4 | Una instrucción J-type | a elegir |
| 5 | Última instrucción cargada | 9 |
| 6 | Palabra sin instrucción | 10 |
| 7 | Última palabra del arreglo | 15 |
| 8 | Dirección fuera del arreglo | 16 |

## Capturas (`capturas/`)
- Consola: comandos y la instrucción con sus campos por cada dirección.
- GTKWave: `addr` en decimal, `instruction` en binario o hex, y los campos extraídos.

## Comandos
```powershell
iverilog -o IMEM_tb.vvp IMEM.v IMEM_tb.v
vvp IMEM_tb.vvp
gtkwave IMEM_tb.vcd
```
