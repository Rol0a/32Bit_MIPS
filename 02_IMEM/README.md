# 02 — Memoria de Instrucciones (IMEM)

**Entrega 1 · Ejercicio 2** · Estado: ✅ implementado y verificado (18/18 lecturas OK) · `gtkwave.png` lista,
`consola.png` por repetir (debe verse también el comando `iverilog`)

## Objetivo
Memoria de solo lectura de 16 palabras de 32 bits con un programa de 10 instrucciones precargado. Recibe una
dirección y entrega la instrucción guardada en ella.

| Archivo | Contenido |
|---|---|
| `IMEM.v` | Módulo `IMEM`, con el programa precargado |
| `IMEM_tb.v` | Testbench `IMEM_tb`, con 18 lecturas comprobadas |
| `IMEM_tb.gtkw` | Vista guardada de GTKWave: dirección, instrucción y campos, cada uno con su formato |

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `addr` | input | 32 | Dirección de la instrucción (por palabra) |
| `instruction` | output | 32 | Instrucción leída |

## Cómo funciona el código

### Almacenamiento
```verilog
reg [31:0] memory [0:15];
```
Arreglo de 16 palabras de 32 bits (índices 0 a 15). El direccionamiento es **por palabra**: la dirección 1 es
la segunda instrucción, por eso el PC avanza `+1` y no `+4`.

### Carga del programa
Un bloque `initial` escribe las 10 instrucciones en el tiempo 0 de la simulación. Cada línea lleva el binario
con los campos separados por `_` y, como comentario, el formato y el mnemónico:
```verilog
memory[0] = 32'b000000_00001_00010_00011_00000_100000; // R  add  $3, $1, $2  (enunciado)
memory[1] = 32'b001000_01000_01001_0000000000001010;   // I  addi $9, $8, 10  (enunciado)
...
memory[9] = 32'b000010_00000000000000000000001001;     // J  j    9  (salta a sí misma: fin)
```
Las palabras 10 a 15 no se escriben y se quedan en `x`.

### Lectura combinacional
```verilog
assign instruction = memory[addr[4:0]];
```
- Es una asignación continua: no espera al reloj. En cuanto cambia `addr`, cambia `instruction`. Así, dentro
  de un ciclo, la instrucción está lista mientras el PC se mantiene estable.
- Se indexa con los **5 bits bajos**, como pide el enunciado (decisión 5 del README principal). Con un
  arreglo de 16 palabras esto tiene consecuencias:

| `addr` | `addr[4:0]` | Lee |
|---|---|---|
| 0–9 | 0–9 | El programa |
| 10–15 | 10–15 | `x`: dentro del arreglo, nunca escritas |
| 16–31 | 16–31 | `x`: fuera de `memory[0:15]` |
| 32 | 0 | La instrucción 0 otra vez: los bits altos se ignoran |

Con `addr[3:0]` la dirección 16 leería la instrucción 0; el testbench lo detecta (la lectura 16 fallaría).

## Programa precargado
Codificación según las decisiones del README principal:
- Opcodes de 6 bits de `docs/Tabla Opcode y Funct.xlsx`.
- `funct` de la tabla de ALUControl (decisión 1).
- Inmediato extendido con signo a 32 bits.
- Campos que la instrucción no usa en `0`: `shamt` siempre, `rs` en MOVI y `rt` en MOV.
- La dirección de `j` es una dirección de palabra directa: `PC = address`.

| Dir | Instrucción (binario) | Hex | Mnemónico | Formato | Efecto al ejecutarse (Fase 4) |
|---|---|---|---|:---:|---|
| 0 | `000000_00001_00010_00011_00000_100000` | `00221820` | `add $3, $1, $2` | R | `$3 = 0 + 0 = 0` |
| 1 | `001000_01000_01001_0000000000001010` | `2109000a` | `addi $9, $8, 10` | I | `$9 = 0 + 10 = 10` |
| 2 | `001010_00000_00001_0000000000000111` | `28010007` | `movi $1, 7` | I | `$1 = 7` |
| 3 | `001010_00000_00010_1111111111111101` | `2802fffd` | `movi $2, -3` | I | `$2 = -3` |
| 4 | `000000_00001_00010_00100_00000_100100` | `00222024` | `sub $4, $1, $2` | R | `$4 = 7 - (-3) = 10` |
| 5 | `000000_00001_00010_00101_00000_100001` | `00222821` | `mul $5, $1, $2` | R | `$5 = 7 × (-3) = -21` |
| 6 | `000000_00101_00001_00110_00000_100010` | `00a13022` | `div $6, $5, $1` | R | `$6 = -21 / 7 = -3` |
| 7 | `001001_01001_00111_0000000000001111` | `2527000f` | `subi $7, $9, 15` | I | `$7 = 10 - 15 = -5` |
| 8 | `000000_00111_00000_01010_00000_100011` | `00e05023` | `mov $10, $7` | R | `$10 = -5` |
| 9 | `000010_00000000000000000000001001` | `08000009` | `j 9` | J | `PC = 9`: salta a sí misma |
| 10–15 | sin inicializar | `x` | — | — | — |

**Por qué este programa:**
- Usa las 9 instrucciones de la ISA (5 R, 4 I y 1 J), así que en la Fase 4 prueba todo el datapath.
- Los negativos (`movi $2, -3` y los resultados de `mul`, `div` y `subi`) ejercitan la extensión de signo y
  la aritmética con signo de la ALU.
- `j 9` salta a sí misma: cuando el datapath la ejecute, el PC se quedará en 9 y los registros dejarán de
  cambiar, de modo que el resultado final se puede revisar con calma. En esta práctica el salto no se
  ejecuta: el PC siempre avanza `+1`.
- Las dos primeras son las del enunciado. Como los registros valen 0 tras el reset, `add $3, $1, $2` da 0;
  `$1` y `$2` reciben valor después, con `movi`.

## Interacción con los otros módulos

| Puerto / campo | Viene de / va a | Detalle |
|---|---|---|
| `addr` | PC: `current_pc` | Integración en `03_PC_IMEM`, con `next_pc = current_pc + 1` |
| `opcode` = `instruction[31:26]` | ControlUnit | Decide el formato y las señales de control |
| `rs`, `rt` = `instruction[25:21]`, `[20:16]` | RegisterFile: `read_reg1`, `read_reg2` | Operandos fuente |
| `rd` / `rt` | Mux `RegDst` → RegisterFile: `write_reg` | `rd` en tipo R; `rt` en tipo I |
| `funct` = `instruction[5:0]` | ALUControl | Solo cuenta en tipo R |
| `immediate` = `instruction[15:0]` | Extensión de signo → mux `ALUSrc` → ALU `src2` | Fase 4 |
| `address` = `instruction[25:0]` | Siguiente PC cuando `Jump = 1` | Fase 4 |

## Testbench (`IMEM_tb.v`)
- Los campos se declaran como `wire` (`opcode = instruction[31:26]`, etc.) para verlos en GTKWave.
- Tarea `leer(dirección, esperado, caso)`: pone la dirección, espera 10 ns y compara con `!==`, así una `x`
  esperada solo coincide con una `x` leída. Imprime dos líneas:
  1. La instrucción con los campos separados por `_` según su formato, su valor en hex, el esperado,
     `OK`/`ERROR` y el mnemónico.
  2. Los campos por nombre. El inmediato también se muestra en decimal con signo y la dirección del salto en
     decimal.
- El formato se reconoce por el opcode: `000000` es R, `000010` es J y el resto es I. Una palabra con `x`
  ocupa una sola línea, porque no tiene campos.
- El esperado se escribe a mano en el testbench, no se lee de la memoria. Así, un error de codificación en
  `IMEM.v` aparece como `ERROR`.
- Recorre las direcciones 0 a 16 y la 32: 18 lecturas de 10 ns (180 ns en total).
- Al final imprime el total de lecturas y si hubo errores.
- `$dumpfile("IMEM_tb.vcd")` y `$dumpvars(0, IMEM_tb)`.

## Casos de prueba (resultados de la simulación)

| # | Caso | Dir. | Esperado | Obtenido (consola) | ¿OK? |
|---|---|:---:|---|---|:---:|
| 1 | Primera instrucción | 0 | `add $3, $1, $2` · `00221820` | `00221820` | ✅ |
| 2 | Una instrucción R-type | 4 | `sub $4, $1, $2` · `00222024` · `funct = 100100` | `00222024` · `funct = 100100` | ✅ |
| 3 | Una instrucción I-type | 3 | `movi $2, -3` · `2802fffd` · `immediate = -3` | `2802fffd` · `immediate = -3` | ✅ |
| 4 | Una instrucción J-type | 9 | `j 9` · `08000009` · `address = 9` | `08000009` · `address = 9` | ✅ |
| 5 | Última instrucción cargada | 9 | `j 9` · `08000009` | `08000009` | ✅ |
| 6 | Palabra sin instrucción | 10 | `x` | `xxxxxxxx` | ✅ |
| 7 | Última palabra del arreglo | 15 | `x` | `xxxxxxxx` | ✅ |
| 8 | Dirección fuera del arreglo | 16 | `x`: `addr[4:0] = 16` queda fuera de `memory[0:15]` | `xxxxxxxx` | ✅ |
| 9 | Adicional: dirección 32 | 32 | `addr[4:0] = 0` → `add $3, $1, $2` · `00221820` | `00221820` | ✅ |

Los casos 4 y 5 usan la misma dirección porque el salto es la última instrucción del programa. El testbench
también lee las demás direcciones (1, 2, 5–8 y 11–14): **las 18 lecturas coinciden con el esperado.**

### Salida de la consola
```
=== Testbench IMEM ===
addr= 0  R  Instr=000000_00001_00010_00011_00000_100000  hex=00221820  esperado=00221820  OK     add  $3, $1, $2
            opcode=000000 rs=00001 rt=00010 rd=00011 shamt=00000 funct=100000
addr= 1  I  Instr=001000_01000_01001_0000000000001010    hex=2109000a  esperado=2109000a  OK     addi $9, $8, 10
            opcode=001000 rs=01000 rt=01001 immediate=0000000000001010 (10)
addr= 2  I  Instr=001010_00000_00001_0000000000000111    hex=28010007  esperado=28010007  OK     movi $1, 7
            opcode=001010 rs=00000 rt=00001 immediate=0000000000000111 (7)
addr= 3  I  Instr=001010_00000_00010_1111111111111101    hex=2802fffd  esperado=2802fffd  OK     movi $2, -3
            opcode=001010 rs=00000 rt=00010 immediate=1111111111111101 (-3)
addr= 4  R  Instr=000000_00001_00010_00100_00000_100100  hex=00222024  esperado=00222024  OK     sub  $4, $1, $2
            opcode=000000 rs=00001 rt=00010 rd=00100 shamt=00000 funct=100100
addr= 5  R  Instr=000000_00001_00010_00101_00000_100001  hex=00222821  esperado=00222821  OK     mul  $5, $1, $2
            opcode=000000 rs=00001 rt=00010 rd=00101 shamt=00000 funct=100001
addr= 6  R  Instr=000000_00101_00001_00110_00000_100010  hex=00a13022  esperado=00a13022  OK     div  $6, $5, $1
            opcode=000000 rs=00101 rt=00001 rd=00110 shamt=00000 funct=100010
addr= 7  I  Instr=001001_01001_00111_0000000000001111    hex=2527000f  esperado=2527000f  OK     subi $7, $9, 15
            opcode=001001 rs=01001 rt=00111 immediate=0000000000001111 (15)
addr= 8  R  Instr=000000_00111_00000_01010_00000_100011  hex=00e05023  esperado=00e05023  OK     mov  $10, $7
            opcode=000000 rs=00111 rt=00000 rd=01010 shamt=00000 funct=100011
addr= 9  J  Instr=000010_00000000000000000000001001      hex=08000009  esperado=08000009  OK     j    9
            opcode=000010 address=00000000000000000000001001 (9)
addr=10  -  Instr=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       hex=xxxxxxxx  esperado=xxxxxxxx  OK     palabra sin instruccion
addr=11  -  Instr=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       hex=xxxxxxxx  esperado=xxxxxxxx  OK     palabra sin instruccion
addr=12  -  Instr=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       hex=xxxxxxxx  esperado=xxxxxxxx  OK     palabra sin instruccion
addr=13  -  Instr=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       hex=xxxxxxxx  esperado=xxxxxxxx  OK     palabra sin instruccion
addr=14  -  Instr=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       hex=xxxxxxxx  esperado=xxxxxxxx  OK     palabra sin instruccion
addr=15  -  Instr=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       hex=xxxxxxxx  esperado=xxxxxxxx  OK     ultima palabra del arreglo
addr=16  -  Instr=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       hex=xxxxxxxx  esperado=xxxxxxxx  OK     fuera del arreglo
addr=32  R  Instr=000000_00001_00010_00011_00000_100000  hex=00221820  esperado=00221820  OK     32: addr[4:0] = 0, lee la 0
            opcode=000000 rs=00001 rt=00010 rd=00011 shamt=00000 funct=100000
=== 18 lecturas, todas las pruebas OK ===
IMEM_tb.v:116: $finish called at 180000 (1ps)
```

## Capturas
- `consola.png` (por repetir): desde esta carpeta, con **los dos comandos visibles** (`iverilog` y `vvp`) y
  las 18 lecturas con sus campos. La captura actual solo muestra `vvp`.
- `gtkwave.png`: `IMEM_tb.gtkw` abre `addr` en decimal, `instruction` en hex, `opcode`, `rs`, `rt`, `rd`,
  `shamt` y `funct` en binario, `immediate` en decimal con signo y `address` en decimal. Luego View →
  *Zoom Fit* (180 ns); con la ventana maximizada se leen mejor los valores.
- En GTKWave todos los campos muestran un valor en cada lectura, aunque el formato no los use: en una
  instrucción I, `rd`, `shamt` y `funct` son bits del inmediato. Hay que interpretarlos según el `opcode`.

## Comandos
```powershell
iverilog -o IMEM_tb.vvp IMEM.v IMEM_tb.v
vvp IMEM_tb.vvp
gtkwave IMEM_tb.vcd IMEM_tb.gtkw    # abre ya la dirección, la instrucción y los campos; luego View → Zoom Fit
```
