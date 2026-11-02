# 03 — Integración PC + IMEM

**Entrega 1 · Ejercicio 3 → Entrega Final** · Estado: ✅ implementado y verificado (27/27 ciclos OK) ·
`gtkwave.png` lista, `consola.png` por repetir (programa de clase)

## Objetivo
Conectar el PC con la IMEM para que cada ciclo se lea la instrucción apuntada por el PC.

| Archivo | Contenido |
|---|---|
| `PC_IMEM_tb.v` | Testbench `PC_IMEM_tb`: instancia el PC y la IMEM y comprueba 27 ciclos |
| `PC_IMEM_tb.gtkw` | Vista guardada de GTKWave: reloj, reset, PC, instrucción y campos |
| `gtkwave.png` | Captura de GTKWave |

## Conexión
```
          next_pc = current_pc + 1  (calculado en el testbench)
             │
        ┌────▼────┐ current_pc  ┌────────┐
 clk ──►│   PC    ├────────────►│  IMEM  ├──► instruction
reset ─►│         │    (addr)   │        │
        └─────────┘             └────────┘
```

- No hay módulo nuevo: la conexión vive en el testbench (`PC_IMEM_tb.v`), que instancia `PC` (`uut_pc`) e
  `IMEM` (`uut_imem`).
- La salida `current_pc` del PC entra directamente como `addr` de la IMEM.
- `assign next_pc = current_pc + 1;` cierra el lazo: el PC avanza solo, una palabra por ciclo
  (direccionamiento por palabra, según la plantilla).
- Reutiliza `../01_PC/PC.v` y `../02_IMEM/IMEM.v` (no se copian).

## Temporización

| t | Evento |
|---|---|
| 0–5 ns | `PC = x` e `instruction = x`: el reset es síncrono y todavía no hay flanco |
| 5 ns | Primer flanco ↑ con `reset = 1`: `PC = 0` |
| 6 ns | Se suelta `reset`, antes del flanco ↓, para alcanzar a ver la instrucción 0 |
| 10 ns | Flanco ↓: se imprime el ciclo 0 (`PC = 0`, `MOVI $1, 15`) |
| 15 ns | Flanco ↑: `PC = 0 + 1 = 1` |
| 10·k + 10 ns | Flanco ↓: se imprime el ciclo k (`PC = k`) |
| 220 ns | Ciclo 21: `PC = 21`, `JUMP 1024` (se lee, no se ejecuta) |
| 260 ns | Ciclo 25: `PC = 25`, `MOVI $0, 255`, la última instrucción cargada |
| 270 ns | Ciclo 26: `PC = 26`, primera palabra sin programa: `0` |
| 274 ns | `$finish`, antes del flanco de 275 ns |

- **Por qué en el flanco de bajada:** el PC cambia con `<=` en el flanco de subida. Medio ciclo después el
  PC ya está estable y la IMEM, que es combinacional, ya entregó la instrucción.
- **El salto no se ejecuta:** aquí el PC siempre avanza `+1`, así que `JUMP 1024` solo se lee y se decodifica
  (`address = 1024`), y después se leen también las instrucciones 23 a 26. Elegir entre `PC + 1` y la
  dirección del salto con la señal `Jump` es parte del procesador completo (`08_MIPS`), donde esas cuatro
  instrucciones ya no se ejecutan.

## Testbench (`PC_IMEM_tb.v`)
- Los campos se declaran como `wire` (`opcode = instruction[31:26]`, etc.) para verlos en GTKWave.
- Tarea `ciclo_cpu(pc_esperado, instr_esperada, caso)`: espera el flanco de bajada, compara el PC y la
  instrucción con `===` e imprime dos líneas con el formato de la portada de la plantilla:
  1. `PC=k, Instr=` con los campos separados por `_` según el formato, más el número de ciclo, el tiempo,
     el formato (R, I o J), `OK`/`ERROR` y el mnemónico esperado.
  2. Los campos por nombre. El inmediato también se muestra en decimal con signo y la dirección del salto en
     decimal.
- Si algo no coincide, imprime una tercera línea con el PC y la instrucción esperados.
- Lo esperado se copia a mano de la tabla de instrucciones de clase, no se lee de la memoria. Comprobado: con
  `next_pc = current_pc + 4`, el testbench marca `ERROR` desde el ciclo 1 (`PC = 4` en vez de 1).
- Antes del primer flanco imprime el PC en `x`, como advierte la plantilla.
- `$dumpfile("PC_IMEM_tb.vcd")` y `$dumpvars(0, PC_IMEM_tb)`.

## Casos de prueba (resultados de la simulación)

| Ciclo | PC esperado | Instrucción esperada | PC obtenido | Instrucción obtenida (opcode / funct) | ¿OK? |
|:---:|:---:|---|:---:|---|:---:|
| 0 | 0 | `#1 MOVI $1, 15` (I) | 0 | `001010` / — | ✅ |
| 1–4 | 1–4 | `#2`–`#5 MOVI` (I) | 1–4 | `001010` / — | ✅ |
| 5 | 5 | `#6 ADD $6, $1, $2` (R) | 5 | `000000` / `100000` | ✅ |
| 6 | 6 | `#7 SUB $7, $3, $1` (R) | 6 | `000000` / `100010` | ✅ |
| 7 | 7 | `#8 MUL $8, $2, $3` (R) | 7 | `000000` / `011000` | ✅ |
| 8 | 8 | `#9 DIV $9, $3, $2` (R) | 8 | `000000` / `011010` | ✅ |
| 9 | 9 | `#10 ADDI $1, $1, 10` (I) | 9 | `001000` / — | ✅ |
| 10 | 10 | `#11 SUBI $2, $2, 4` (I) | 10 | `001001` / — | ✅ |
| 11–20 | 11–20 | `#12`–`#21` (R e I) | 11–20 | según la tabla de `02_IMEM` | ✅ |
| 21 | 21 | `#22 JUMP 1024` (J) | 21 | `000010` / — · `address = 1024` | ✅ |
| 22–25 | 22–25 | `#23`–`#26` (R, R, I, I) | 22–25 | según la tabla de `02_IMEM` | ✅ |
| 26 | 26 | palabra sin programa: `0` | 26 | `000000` / `000000` | ✅ |

`funct` solo existe en las instrucciones R; en las I y J esos bits son parte del inmediato o de la dirección.
Cada ciclo se compara por separado: **los 27 ciclos coinciden con el esperado.**

### Salida de la consola
```
=== Testbench PC + IMEM ===
t=  1 ns  antes del primer flanco: PC=x, Instr=xxxxxxxx (x: el PC aun no se ha reiniciado)
ciclo  0  t= 10 ns  I  PC= 0, Instr=001010_00000_00001_0000000000001111      OK     #1  MOVI $1, 15
                            opcode=001010 rs=00000 rt=00001 immediate=0000000000001111 (15)
ciclo  1  t= 20 ns  I  PC= 1, Instr=001010_00000_00010_0000000000010100      OK     #2  MOVI $2, 20
                            opcode=001010 rs=00000 rt=00010 immediate=0000000000010100 (20)
ciclo  2  t= 30 ns  I  PC= 2, Instr=001010_00000_00011_0000000000110010      OK     #3  MOVI $3, 50
                            opcode=001010 rs=00000 rt=00011 immediate=0000000000110010 (50)
ciclo  3  t= 40 ns  I  PC= 3, Instr=001010_00000_00100_0000000000000101      OK     #4  MOVI $4, 5
                            opcode=001010 rs=00000 rt=00100 immediate=0000000000000101 (5)
ciclo  4  t= 50 ns  I  PC= 4, Instr=001010_00000_00101_0000000000000010      OK     #5  MOVI $5, 2
                            opcode=001010 rs=00000 rt=00101 immediate=0000000000000010 (2)
ciclo  5  t= 60 ns  R  PC= 5, Instr=000000_00001_00010_00110_00000_100000    OK     #6  ADD $6, $1, $2
                            opcode=000000 rs=00001 rt=00010 rd=00110 shamt=00000 funct=100000
ciclo  6  t= 70 ns  R  PC= 6, Instr=000000_00011_00001_00111_00000_100010    OK     #7  SUB $7, $3, $1
                            opcode=000000 rs=00011 rt=00001 rd=00111 shamt=00000 funct=100010
ciclo  7  t= 80 ns  R  PC= 7, Instr=000000_00010_00011_01000_00000_011000    OK     #8  MUL $8, $2, $3
                            opcode=000000 rs=00010 rt=00011 rd=01000 shamt=00000 funct=011000
ciclo  8  t= 90 ns  R  PC= 8, Instr=000000_00011_00010_01001_00000_011010    OK     #9  DIV $9, $3, $2
                            opcode=000000 rs=00011 rt=00010 rd=01001 shamt=00000 funct=011010
ciclo  9  t=100 ns  I  PC= 9, Instr=001000_00001_00001_0000000000001010      OK     #10 ADDI $1, $1, 10
                            opcode=001000 rs=00001 rt=00001 immediate=0000000000001010 (10)
ciclo 10  t=110 ns  I  PC=10, Instr=001001_00010_00010_0000000000000100      OK     #11 SUBI $2, $2, 4
                            opcode=001001 rs=00010 rt=00010 immediate=0000000000000100 (4)
ciclo 11  t=120 ns  R  PC=11, Instr=000000_00110_00100_01010_00000_100000    OK     #12 ADD $10, $6, $4
                            opcode=000000 rs=00110 rt=00100 rd=01010 shamt=00000 funct=100000
ciclo 12  t=130 ns  R  PC=12, Instr=000000_00110_00101_01011_00000_011000    OK     #13 MUL $11, $6, $5
                            opcode=000000 rs=00110 rt=00101 rd=01011 shamt=00000 funct=011000
ciclo 13  t=140 ns  R  PC=13, Instr=000000_01010_00101_01100_00000_011010    OK     #14 DIV $12, $10, $5
                            opcode=000000 rs=01010 rt=00101 rd=01100 shamt=00000 funct=011010
ciclo 14  t=150 ns  I  PC=14, Instr=001000_00100_00100_0000000000010100      OK     #15 ADDI $4, $4, 20
                            opcode=001000 rs=00100 rt=00100 immediate=0000000000010100 (20)
ciclo 15  t=160 ns  R  PC=15, Instr=000000_00100_00011_01101_00000_100010    OK     #16 SUB $13, $4, $3
                            opcode=000000 rs=00100 rt=00011 rd=01101 shamt=00000 funct=100010
ciclo 16  t=170 ns  I  PC=16, Instr=001010_00000_01110_0000000001100100      OK     #17 MOVI $14, 100
                            opcode=001010 rs=00000 rt=01110 immediate=0000000001100100 (100)
ciclo 17  t=180 ns  R  PC=17, Instr=000000_01110_00001_01111_00000_100000    OK     #18 ADD $15, $14, $1
                            opcode=000000 rs=01110 rt=00001 rd=01111 shamt=00000 funct=100000
ciclo 18  t=190 ns  I  PC=18, Instr=001001_00011_00011_0000000000000101      OK     #19 SUBI $3, $3, 5
                            opcode=001001 rs=00011 rt=00011 immediate=0000000000000101 (5)
ciclo 19  t=200 ns  R  PC=19, Instr=000000_01111_00010_10000_00000_011000    OK     #20 MUL $16, $15, $2
                            opcode=000000 rs=01111 rt=00010 rd=10000 shamt=00000 funct=011000
ciclo 20  t=210 ns  I  PC=20, Instr=001000_00001_10001_0000000000000001      OK     #21 ADDI $17, $1, 1
                            opcode=001000 rs=00001 rt=10001 immediate=0000000000000001 (1)
ciclo 21  t=220 ns  J  PC=21, Instr=000010_00000000000000010000000000        OK     #22 JUMP 1024 (aqui no salta)
                            opcode=000010 address=00000000000000010000000000 (1024)
ciclo 22  t=230 ns  R  PC=22, Instr=000000_10001_00010_10010_00000_100000    OK     #23 ADD $18, $17, $2
                            opcode=000000 rs=10001 rt=00010 rd=10010 shamt=00000 funct=100000
ciclo 23  t=240 ns  R  PC=23, Instr=000000_10010_00101_10011_00000_100010    OK     #24 SUB $19, $18, $5
                            opcode=000000 rs=10010 rt=00101 rd=10011 shamt=00000 funct=100010
ciclo 24  t=250 ns  I  PC=24, Instr=001010_00000_10100_0000000011111111      OK     #25 MOVI $20, 255
                            opcode=001010 rs=00000 rt=10100 immediate=0000000011111111 (255)
ciclo 25  t=260 ns  I  PC=25, Instr=001010_00000_00000_0000000011111111      OK     #26 MOVI $0, 255
                            opcode=001010 rs=00000 rt=00000 immediate=0000000011111111 (255)
ciclo 26  t=270 ns  R  PC=26, Instr=000000_00000_00000_00000_00000_000000    OK     sin programa: lee 0
                            opcode=000000 rs=00000 rt=00000 rd=00000 shamt=00000 funct=000000
=== 27 ciclos, todas las pruebas OK ===
PC_IMEM_tb.v:157: $finish called at 274000 (1ps)
```

## Capturas
- `consola.png` (por repetir con el programa de clase): desde esta carpeta, con **los dos comandos visibles**
  (`iverilog` y `vvp`) y las dos líneas por ciclo. Si no caben, varias capturas consecutivas.
- `gtkwave.png` ✅: `clk`, `reset`, `current_pc` y `next_pc` en decimal, `instruction` en hex, `opcode`,
  `rs`, `rt`, `rd`, `shamt` y `funct` en binario, `immediate` en decimal con signo y `address` en decimal;
  los 27 ciclos a la vista (0–274 ns) con *Zoom Fit*. `PC_IMEM_tb.gtkw` abre esta misma vista.
- En GTKWave todos los campos muestran un valor en cada ciclo, aunque el formato no los use (en una
  instrucción I, `rd`, `shamt` y `funct` son bits del inmediato). Hay que interpretarlos según el `opcode`.

## Comandos
Ejecutar desde `03_PC_IMEM/`:
```powershell
iverilog -o PC_IMEM_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v PC_IMEM_tb.v
vvp PC_IMEM_tb.vvp
gtkwave PC_IMEM_tb.vcd PC_IMEM_tb.gtkw    # abre ya las señales con su formato; luego View → Zoom Fit
```
