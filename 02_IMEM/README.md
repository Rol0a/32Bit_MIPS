# 02 — Memoria de Instrucciones (IMEM)

**Entrega 1 · Ejercicio 2 → Entrega Final** · Estado: ✅ implementado y verificado (31/31 lecturas OK) ·
`gtkwave.png` lista, `consola.png` por repetir (programa de clase)

## Objetivo
Memoria de solo lectura de **1024 palabras** de 32 bits con el **programa de clase** (26 instrucciones)
precargado. Recibe una dirección y entrega la instrucción guardada en ella.

| Archivo | Contenido |
|---|---|
| `IMEM.v` | Módulo `IMEM`, con el programa precargado |
| `IMEM_tb.v` | Testbench `IMEM_tb`, con 31 lecturas comprobadas |
| `IMEM_tb.gtkw` | Vista guardada de GTKWave: dirección, instrucción y campos, cada uno con su formato |

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `addr` | input | 32 | Dirección de la instrucción (por palabra) |
| `instruction` | output | 32 | Instrucción leída |

## Cómo funciona el código

### Almacenamiento
```verilog
reg [31:0] memory [0:1023];
```
Arreglo de 1024 palabras de 32 bits (índices 0 a 1023, 10 bits de dirección), como el `instr_mem[1024]` del
datapath de referencia. El direccionamiento es **por palabra**: la dirección 1 es la segunda instrucción, por
eso el PC avanza `+1` y no `+4`.

### Carga del programa
Un bloque `initial` pone primero las 1024 palabras en `0` y después escribe las 26 instrucciones de clase en
las direcciones 0 a 25 (la instrucción `#n` queda en la dirección `n − 1`). Cada línea lleva el binario con
los campos separados por `_` y, como comentario, el número, el formato y el mnemónico:
```verilog
for (i = 0; i < 1024; i = i + 1)
    memory[i] = 32'd0;

memory[0]  = 32'b001010_00000_00001_0000000000001111;   //  1  I  MOVI $1, 15
memory[5]  = 32'b000000_00001_00010_00110_00000_100000; //  6  R  ADD  $6, $1, $2
...
memory[21] = 32'b000010_00000000000000010000000000;     // 22  J  JUMP 1024 (sale de la IMEM)
...
memory[25] = 32'b001010_00000_00000_0000000011111111;   // 26  I  MOVI $0, 255     (no se ejecuta)
```

### Lectura combinacional
```verilog
assign instruction = (addr < 32'd1024) ? memory[addr[9:0]] : 32'd0;
```
- Es una asignación continua: no espera al reloj. En cuanto cambia `addr`, cambia `instruction`. Así, dentro
  de un ciclo, la instrucción está lista mientras el PC se mantiene estable.
- Solo existen las direcciones 0 a 1023. **Fuera de ese rango devuelve `0`** (decisión D5 del README
  principal). Sin la comparación, `addr[9:0]` de 1024 sería 0: después de `JUMP 1024` el procesador leería
  otra vez `MOVI $1, 15` y el programa volvería a empezar.
- La palabra `0` es una **NOP** en este procesador: tipo R con `funct = 000000` (ALUControl → `1111`, la ALU
  da 0) y destino `$0`, que el banco nunca escribe.

| `addr` | Lee |
|---|---|
| 0–25 | El programa de clase |
| 26–1023 | `0` (NOP): dentro del arreglo, sin programa; el `initial` las pone en 0 |
| ≥ 1024 | `0` (NOP): fuera de la memoria, aunque `addr[9:0]` caiga dentro |

## Programa precargado (instrucciones binarias de clase)
Los binarios son los que se compartieron en clase, copiados sin cambios. Los `funct` de SUB, MUL y DIV son los
de esas instrucciones (decisión D1). Las direcciones son de palabra: `JUMP 1024` hace `PC = 1024`.

| Dir | # | Instrucción (binario) | Hex | Mnemónico | Formato | Efecto al ejecutarse |
|---:|---:|---|---|---|:---:|---|
| 0 | 1 | `001010_00000_00001_0000000000001111` | `2801000f` | `MOVI $1, 15` | I | `$1 = 15` |
| 1 | 2 | `001010_00000_00010_0000000000010100` | `28020014` | `MOVI $2, 20` | I | `$2 = 20` |
| 2 | 3 | `001010_00000_00011_0000000000110010` | `28030032` | `MOVI $3, 50` | I | `$3 = 50` |
| 3 | 4 | `001010_00000_00100_0000000000000101` | `28040005` | `MOVI $4, 5` | I | `$4 = 5` |
| 4 | 5 | `001010_00000_00101_0000000000000010` | `28050002` | `MOVI $5, 2` | I | `$5 = 2` |
| 5 | 6 | `000000_00001_00010_00110_00000_100000` | `00223020` | `ADD $6, $1, $2` | R | `$6 = 15 + 20 = 35` |
| 6 | 7 | `000000_00011_00001_00111_00000_100010` | `00613822` | `SUB $7, $3, $1` | R | `$7 = 50 − 15 = 35` |
| 7 | 8 | `000000_00010_00011_01000_00000_011000` | `00434018` | `MUL $8, $2, $3` | R | `$8 = 20 × 50 = 1000` |
| 8 | 9 | `000000_00011_00010_01001_00000_011010` | `0062481a` | `DIV $9, $3, $2` | R | `$9 = 50 / 20 = 2` |
| 9 | 10 | `001000_00001_00001_0000000000001010` | `2021000a` | `ADDI $1, $1, 10` | I | `$1 = 15 + 10 = 25` |
| 10 | 11 | `001001_00010_00010_0000000000000100` | `24420004` | `SUBI $2, $2, 4` | I | `$2 = 20 − 4 = 16` |
| 11 | 12 | `000000_00110_00100_01010_00000_100000` | `00c45020` | `ADD $10, $6, $4` | R | `$10 = 35 + 5 = 40` |
| 12 | 13 | `000000_00110_00101_01011_00000_011000` | `00c55818` | `MUL $11, $6, $5` | R | `$11 = 35 × 2 = 70` |
| 13 | 14 | `000000_01010_00101_01100_00000_011010` | `0145601a` | `DIV $12, $10, $5` | R | `$12 = 40 / 2 = 20` |
| 14 | 15 | `001000_00100_00100_0000000000010100` | `20840014` | `ADDI $4, $4, 20` | I | `$4 = 5 + 20 = 25` |
| 15 | 16 | `000000_00100_00011_01101_00000_100010` | `00836822` | `SUB $13, $4, $3` | R | `$13 = 25 − 50 = −25` |
| 16 | 17 | `001010_00000_01110_0000000001100100` | `280e0064` | `MOVI $14, 100` | I | `$14 = 100` |
| 17 | 18 | `000000_01110_00001_01111_00000_100000` | `01c17820` | `ADD $15, $14, $1` | R | `$15 = 100 + 25 = 125` |
| 18 | 19 | `001001_00011_00011_0000000000000101` | `24630005` | `SUBI $3, $3, 5` | I | `$3 = 50 − 5 = 45` |
| 19 | 20 | `000000_01111_00010_10000_00000_011000` | `01e28018` | `MUL $16, $15, $2` | R | `$16 = 125 × 16 = 2000` |
| 20 | 21 | `001000_00001_10001_0000000000000001` | `20310001` | `ADDI $17, $1, 1` | I | `$17 = 25 + 1 = 26` |
| 21 | 22 | `000010_00000000000000010000000000` | `08000400` | `JUMP 1024` | J | `PC = 1024`: sale de la IMEM |
| 22 | 23 | `000000_10001_00010_10010_00000_100000` | `02229020` | `ADD $18, $17, $2` | R | no se ejecuta |
| 23 | 24 | `000000_10010_00101_10011_00000_100010` | `02459822` | `SUB $19, $18, $5` | R | no se ejecuta |
| 24 | 25 | `001010_00000_10100_0000000011111111` | `281400ff` | `MOVI $20, 255` | I | no se ejecuta |
| 25 | 26 | `001010_00000_00000_0000000011111111` | `280000ff` | `MOVI $0, 255` | I | no se ejecuta |
| 26–1023 | — | `0` | `00000000` | NOP | R | ninguno |

La columna «Efecto» es la ejecución en el procesador completo (`08_MIPS`). Aquí la memoria solo se lee: las
instrucciones 23 a 26 están cargadas, pero el procesador nunca llega a ellas porque `JUMP 1024` lo saca de la
memoria y allí solo lee NOPs.

## Interacción con los otros módulos

| Puerto / campo | Viene de / va a | Detalle |
|---|---|---|
| `addr` | PC: `current_pc` | Integración en `03_PC_IMEM`, con `next_pc = current_pc + 1` |
| `opcode` = `instruction[31:26]` | ControlUnit | Decide el formato y las señales de control |
| `rs`, `rt` = `instruction[25:21]`, `[20:16]` | RegisterFile: `read_reg1`, `read_reg2` | Operandos fuente |
| `rd` / `rt` | Mux `RegDst` → RegisterFile: `write_reg` | `rd` en tipo R; `rt` en tipo I |
| `funct` = `instruction[5:0]` | ALUControl | Solo cuenta en tipo R |
| `immediate` = `instruction[15:0]` | Extensión de signo → mux `ALUSrc` → ALU `src2` | `08_MIPS` |
| `address` = `instruction[25:0]` | Siguiente PC cuando `Jump = 1` | `08_MIPS` |

## Testbench (`IMEM_tb.v`)
- Los campos se declaran como `wire` (`opcode = instruction[31:26]`, etc.) para verlos en GTKWave.
- Tarea `leer(dirección, esperado, caso)`: pone la dirección, espera 10 ns y compara con `!==`, así una `x`
  también cuenta como error. Imprime dos líneas:
  1. La instrucción con los campos separados por `_` según su formato, su valor en hex, el esperado,
     `OK`/`ERROR` y el mnemónico.
  2. Los campos por nombre. El inmediato también se muestra en decimal con signo y la dirección del salto en
     decimal.
- El formato se reconoce por el opcode: `000000` es R, `000010` es J y el resto es I.
- El esperado se copia a mano de la tabla de instrucciones de clase, no se lee de la memoria. Así, un error de
  copia en `IMEM.v` aparece como `ERROR`.
- 31 lecturas de 10 ns (310 ns en total): las direcciones 0 a 25, dos palabras sin programa (26 y 1023) y tres
  fuera de la memoria (1024, 1025 y 2048).
- Al final imprime el total de lecturas y si hubo errores.
- `$dumpfile("IMEM_tb.vcd")` y `$dumpvars(0, IMEM_tb)`.

## Casos de prueba (resultados de la simulación)

| # | Caso | Dir. | Esperado | Obtenido (consola) | ¿OK? |
|---|---|:---:|---|---|:---:|
| 1 | Primera instrucción | 0 | `MOVI $1, 15` · `2801000f` | `2801000f` | ✅ |
| 2 | Una instrucción R-type | 6 | `SUB $7, $3, $1` · `00613822` · `funct = 100010` | `00613822` · `funct = 100010` | ✅ |
| 3 | Una instrucción I-type | 10 | `SUBI $2, $2, 4` · `24420004` · `immediate = 4` | `24420004` · `immediate = 4` | ✅ |
| 4 | Una instrucción J-type | 21 | `JUMP 1024` · `08000400` · `address = 1024` | `08000400` · `address = 1024` | ✅ |
| 5 | Última instrucción cargada | 25 | `MOVI $0, 255` · `280000ff` | `280000ff` | ✅ |
| 6 | Palabra sin programa | 26 | `0` | `00000000` | ✅ |
| 7 | Última palabra del arreglo | 1023 | `0` | `00000000` | ✅ |
| 8 | Destino de `JUMP 1024` | 1024 | `0`, no `MOVI $1, 15` | `00000000` | ✅ |
| 9 | Adicional: fuera de la memoria | 1025, 2048 | `0` (2048 tiene `addr[9:0] = 0`) | `00000000` | ✅ |

El testbench lee las 26 direcciones del programa: **las 31 lecturas coinciden con el esperado.**

### Salida de la consola
```
=== Testbench IMEM ===
addr=   0  I  Instr=001010_00000_00001_0000000000001111    hex=2801000f  esperado=2801000f  OK     #1  MOVI $1, 15
              opcode=001010 rs=00000 rt=00001 immediate=0000000000001111 (15)
addr=   1  I  Instr=001010_00000_00010_0000000000010100    hex=28020014  esperado=28020014  OK     #2  MOVI $2, 20
              opcode=001010 rs=00000 rt=00010 immediate=0000000000010100 (20)
addr=   2  I  Instr=001010_00000_00011_0000000000110010    hex=28030032  esperado=28030032  OK     #3  MOVI $3, 50
              opcode=001010 rs=00000 rt=00011 immediate=0000000000110010 (50)
addr=   3  I  Instr=001010_00000_00100_0000000000000101    hex=28040005  esperado=28040005  OK     #4  MOVI $4, 5
              opcode=001010 rs=00000 rt=00100 immediate=0000000000000101 (5)
addr=   4  I  Instr=001010_00000_00101_0000000000000010    hex=28050002  esperado=28050002  OK     #5  MOVI $5, 2
              opcode=001010 rs=00000 rt=00101 immediate=0000000000000010 (2)
addr=   5  R  Instr=000000_00001_00010_00110_00000_100000  hex=00223020  esperado=00223020  OK     #6  ADD $6, $1, $2
              opcode=000000 rs=00001 rt=00010 rd=00110 shamt=00000 funct=100000
addr=   6  R  Instr=000000_00011_00001_00111_00000_100010  hex=00613822  esperado=00613822  OK     #7  SUB $7, $3, $1
              opcode=000000 rs=00011 rt=00001 rd=00111 shamt=00000 funct=100010
addr=   7  R  Instr=000000_00010_00011_01000_00000_011000  hex=00434018  esperado=00434018  OK     #8  MUL $8, $2, $3
              opcode=000000 rs=00010 rt=00011 rd=01000 shamt=00000 funct=011000
addr=   8  R  Instr=000000_00011_00010_01001_00000_011010  hex=0062481a  esperado=0062481a  OK     #9  DIV $9, $3, $2
              opcode=000000 rs=00011 rt=00010 rd=01001 shamt=00000 funct=011010
addr=   9  I  Instr=001000_00001_00001_0000000000001010    hex=2021000a  esperado=2021000a  OK     #10 ADDI $1, $1, 10
              opcode=001000 rs=00001 rt=00001 immediate=0000000000001010 (10)
addr=  10  I  Instr=001001_00010_00010_0000000000000100    hex=24420004  esperado=24420004  OK     #11 SUBI $2, $2, 4
              opcode=001001 rs=00010 rt=00010 immediate=0000000000000100 (4)
addr=  11  R  Instr=000000_00110_00100_01010_00000_100000  hex=00c45020  esperado=00c45020  OK     #12 ADD $10, $6, $4
              opcode=000000 rs=00110 rt=00100 rd=01010 shamt=00000 funct=100000
addr=  12  R  Instr=000000_00110_00101_01011_00000_011000  hex=00c55818  esperado=00c55818  OK     #13 MUL $11, $6, $5
              opcode=000000 rs=00110 rt=00101 rd=01011 shamt=00000 funct=011000
addr=  13  R  Instr=000000_01010_00101_01100_00000_011010  hex=0145601a  esperado=0145601a  OK     #14 DIV $12, $10, $5
              opcode=000000 rs=01010 rt=00101 rd=01100 shamt=00000 funct=011010
addr=  14  I  Instr=001000_00100_00100_0000000000010100    hex=20840014  esperado=20840014  OK     #15 ADDI $4, $4, 20
              opcode=001000 rs=00100 rt=00100 immediate=0000000000010100 (20)
addr=  15  R  Instr=000000_00100_00011_01101_00000_100010  hex=00836822  esperado=00836822  OK     #16 SUB $13, $4, $3
              opcode=000000 rs=00100 rt=00011 rd=01101 shamt=00000 funct=100010
addr=  16  I  Instr=001010_00000_01110_0000000001100100    hex=280e0064  esperado=280e0064  OK     #17 MOVI $14, 100
              opcode=001010 rs=00000 rt=01110 immediate=0000000001100100 (100)
addr=  17  R  Instr=000000_01110_00001_01111_00000_100000  hex=01c17820  esperado=01c17820  OK     #18 ADD $15, $14, $1
              opcode=000000 rs=01110 rt=00001 rd=01111 shamt=00000 funct=100000
addr=  18  I  Instr=001001_00011_00011_0000000000000101    hex=24630005  esperado=24630005  OK     #19 SUBI $3, $3, 5
              opcode=001001 rs=00011 rt=00011 immediate=0000000000000101 (5)
addr=  19  R  Instr=000000_01111_00010_10000_00000_011000  hex=01e28018  esperado=01e28018  OK     #20 MUL $16, $15, $2
              opcode=000000 rs=01111 rt=00010 rd=10000 shamt=00000 funct=011000
addr=  20  I  Instr=001000_00001_10001_0000000000000001    hex=20310001  esperado=20310001  OK     #21 ADDI $17, $1, 1
              opcode=001000 rs=00001 rt=10001 immediate=0000000000000001 (1)
addr=  21  J  Instr=000010_00000000000000010000000000      hex=08000400  esperado=08000400  OK     #22 JUMP 1024
              opcode=000010 address=00000000000000010000000000 (1024)
addr=  22  R  Instr=000000_10001_00010_10010_00000_100000  hex=02229020  esperado=02229020  OK     #23 ADD $18, $17, $2
              opcode=000000 rs=10001 rt=00010 rd=10010 shamt=00000 funct=100000
addr=  23  R  Instr=000000_10010_00101_10011_00000_100010  hex=02459822  esperado=02459822  OK     #24 SUB $19, $18, $5
              opcode=000000 rs=10010 rt=00101 rd=10011 shamt=00000 funct=100010
addr=  24  I  Instr=001010_00000_10100_0000000011111111    hex=281400ff  esperado=281400ff  OK     #25 MOVI $20, 255
              opcode=001010 rs=00000 rt=10100 immediate=0000000011111111 (255)
addr=  25  I  Instr=001010_00000_00000_0000000011111111    hex=280000ff  esperado=280000ff  OK     #26 MOVI $0, 255
              opcode=001010 rs=00000 rt=00000 immediate=0000000011111111 (255)
addr=  26  R  Instr=000000_00000_00000_00000_00000_000000  hex=00000000  esperado=00000000  OK     primera palabra sin programa: 0
              opcode=000000 rs=00000 rt=00000 rd=00000 shamt=00000 funct=000000
addr=1023  R  Instr=000000_00000_00000_00000_00000_000000  hex=00000000  esperado=00000000  OK     ultima palabra del arreglo: 0
              opcode=000000 rs=00000 rt=00000 rd=00000 shamt=00000 funct=000000
addr=1024  R  Instr=000000_00000_00000_00000_00000_000000  hex=00000000  esperado=00000000  OK     1024 (JUMP 1024): fuera, lee 0
              opcode=000000 rs=00000 rt=00000 rd=00000 shamt=00000 funct=000000
addr=1025  R  Instr=000000_00000_00000_00000_00000_000000  hex=00000000  esperado=00000000  OK     1025: fuera, lee 0
              opcode=000000 rs=00000 rt=00000 rd=00000 shamt=00000 funct=000000
addr=2048  R  Instr=000000_00000_00000_00000_00000_000000  hex=00000000  esperado=00000000  OK     2048: addr[9:0] = 0, pero lee 0
              opcode=000000 rs=00000 rt=00000 rd=00000 shamt=00000 funct=000000
=== 31 lecturas, todas las pruebas OK ===
IMEM_tb.v:131: $finish called at 310000 (1ps)
```

## Capturas
- `consola.png` (por repetir con el programa de clase): desde esta carpeta, con **los dos comandos visibles**
  (`iverilog` y `vvp`) y las 31 lecturas. Si no caben, varias capturas consecutivas.
- `gtkwave.png`: `IMEM_tb.gtkw` abre `addr` en decimal, `instruction` en hex, `opcode`, `rs`, `rt`, `rd`,
  `shamt` y `funct` en binario, `immediate` en decimal con signo y `address` en decimal. Luego View →
  *Zoom Fit* (310 ns).
- En GTKWave todos los campos muestran un valor en cada lectura, aunque el formato no los use: en una
  instrucción I, `rd`, `shamt` y `funct` son bits del inmediato. Hay que interpretarlos según el `opcode`.

## Comandos
```powershell
iverilog -o IMEM_tb.vvp IMEM.v IMEM_tb.v
vvp IMEM_tb.vvp
gtkwave IMEM_tb.vcd IMEM_tb.gtkw    # abre ya la dirección, la instrucción y los campos; luego View → Zoom Fit
```
