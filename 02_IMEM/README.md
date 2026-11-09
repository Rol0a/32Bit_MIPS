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
- El esperado es el arreglo `programa[0..25]`, copiado a mano de la tabla de instrucciones de clase con el
  mnemónico al lado, no leído de la memoria. Así, un error de copia en `IMEM.v` aparece como `ERROR`.
- Un `for` recorre las 26 direcciones del programa: pone `addr = i` y `#10 $display(...)` imprime dos líneas,
  comparando con `instruction === programa[i]` (así una `x` también cuenta como error):
  1. La instrucción en binario, su valor en hex y `OK`/`ERROR`.
  2. Los ocho campos por nombre, sin distinguir el formato: como en GTKWave, hay que leerlos según el `opcode`.
     El inmediato va en decimal con signo y la dirección en decimal.
- Después, cinco líneas sueltas del mismo estilo (`addr = 1024;  #10 $display(...)`) para dos palabras sin
  programa (26 y 1023) y tres direcciones fuera de la memoria (1024, 1025 y 2048); todas deben leer 0.
- 31 lecturas de 10 ns (310 ns en total). No hay línea de resumen: un fallo se ve como `ERROR` en su fila.
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
addr=   0  Instr=00101000000000010000000000001111  hex=2801000f  OK
           opcode=001010 rs=00000 rt=00001 rd=00000 shamt=00000 funct=001111 immediate=15 address=65551
addr=   1  Instr=00101000000000100000000000010100  hex=28020014  OK
           opcode=001010 rs=00000 rt=00010 rd=00000 shamt=00000 funct=010100 immediate=20 address=131092
addr=   2  Instr=00101000000000110000000000110010  hex=28030032  OK
           opcode=001010 rs=00000 rt=00011 rd=00000 shamt=00000 funct=110010 immediate=50 address=196658
addr=   3  Instr=00101000000001000000000000000101  hex=28040005  OK
           opcode=001010 rs=00000 rt=00100 rd=00000 shamt=00000 funct=000101 immediate=5 address=262149
addr=   4  Instr=00101000000001010000000000000010  hex=28050002  OK
           opcode=001010 rs=00000 rt=00101 rd=00000 shamt=00000 funct=000010 immediate=2 address=327682
addr=   5  Instr=00000000001000100011000000100000  hex=00223020  OK
           opcode=000000 rs=00001 rt=00010 rd=00110 shamt=00000 funct=100000 immediate=12320 address=2240544
addr=   6  Instr=00000000011000010011100000100010  hex=00613822  OK
           opcode=000000 rs=00011 rt=00001 rd=00111 shamt=00000 funct=100010 immediate=14370 address=6371362
addr=   7  Instr=00000000010000110100000000011000  hex=00434018  OK
           opcode=000000 rs=00010 rt=00011 rd=01000 shamt=00000 funct=011000 immediate=16408 address=4407320
addr=   8  Instr=00000000011000100100100000011010  hex=0062481a  OK
           opcode=000000 rs=00011 rt=00010 rd=01001 shamt=00000 funct=011010 immediate=18458 address=6440986
addr=   9  Instr=00100000001000010000000000001010  hex=2021000a  OK
           opcode=001000 rs=00001 rt=00001 rd=00000 shamt=00000 funct=001010 immediate=10 address=2162698
addr=  10  Instr=00100100010000100000000000000100  hex=24420004  OK
           opcode=001001 rs=00010 rt=00010 rd=00000 shamt=00000 funct=000100 immediate=4 address=4325380
addr=  11  Instr=00000000110001000101000000100000  hex=00c45020  OK
           opcode=000000 rs=00110 rt=00100 rd=01010 shamt=00000 funct=100000 immediate=20512 address=12865568
addr=  12  Instr=00000000110001010101100000011000  hex=00c55818  OK
           opcode=000000 rs=00110 rt=00101 rd=01011 shamt=00000 funct=011000 immediate=22552 address=12933144
addr=  13  Instr=00000001010001010110000000011010  hex=0145601a  OK
           opcode=000000 rs=01010 rt=00101 rd=01100 shamt=00000 funct=011010 immediate=24602 address=21323802
addr=  14  Instr=00100000100001000000000000010100  hex=20840014  OK
           opcode=001000 rs=00100 rt=00100 rd=00000 shamt=00000 funct=010100 immediate=20 address=8650772
addr=  15  Instr=00000000100000110110100000100010  hex=00836822  OK
           opcode=000000 rs=00100 rt=00011 rd=01101 shamt=00000 funct=100010 immediate=26658 address=8611874
addr=  16  Instr=00101000000011100000000001100100  hex=280e0064  OK
           opcode=001010 rs=00000 rt=01110 rd=00000 shamt=00001 funct=100100 immediate=100 address=917604
addr=  17  Instr=00000001110000010111100000100000  hex=01c17820  OK
           opcode=000000 rs=01110 rt=00001 rd=01111 shamt=00000 funct=100000 immediate=30752 address=29456416
addr=  18  Instr=00100100011000110000000000000101  hex=24630005  OK
           opcode=001001 rs=00011 rt=00011 rd=00000 shamt=00000 funct=000101 immediate=5 address=6488069
addr=  19  Instr=00000001111000101000000000011000  hex=01e28018  OK
           opcode=000000 rs=01111 rt=00010 rd=10000 shamt=00000 funct=011000 immediate=-32744 address=31621144
addr=  20  Instr=00100000001100010000000000000001  hex=20310001  OK
           opcode=001000 rs=00001 rt=10001 rd=00000 shamt=00000 funct=000001 immediate=1 address=3211265
addr=  21  Instr=00001000000000000000010000000000  hex=08000400  OK
           opcode=000010 rs=00000 rt=00000 rd=00000 shamt=10000 funct=000000 immediate=1024 address=1024
addr=  22  Instr=00000010001000101001000000100000  hex=02229020  OK
           opcode=000000 rs=10001 rt=00010 rd=10010 shamt=00000 funct=100000 immediate=-28640 address=35819552
addr=  23  Instr=00000010010001011001100000100010  hex=02459822  OK
           opcode=000000 rs=10010 rt=00101 rd=10011 shamt=00000 funct=100010 immediate=-26590 address=38115362
addr=  24  Instr=00101000000101000000000011111111  hex=281400ff  OK
           opcode=001010 rs=00000 rt=10100 rd=00000 shamt=00011 funct=111111 immediate=255 address=1310975
addr=  25  Instr=00101000000000000000000011111111  hex=280000ff  OK
           opcode=001010 rs=00000 rt=00000 rd=00000 shamt=00011 funct=111111 immediate=255 address=255
addr=  26  Instr=00000000000000000000000000000000  hex=00000000  OK
addr=1023  Instr=00000000000000000000000000000000  hex=00000000  OK
addr=1024  Instr=00000000000000000000000000000000  hex=00000000  OK
addr=1025  Instr=00000000000000000000000000000000  hex=00000000  OK
addr=2048  Instr=00000000000000000000000000000000  hex=00000000  OK
IMEM_tb.v:76: $finish called at 310000 (1ps)
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
