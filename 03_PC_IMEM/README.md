# 03 — Integración PC + IMEM

**Entrega 1 · Ejercicio 3** · Estado: ✅ implementado y verificado (10/10 ciclos OK) · capturas listas

## Objetivo
Conectar el PC con la IMEM para que cada ciclo se lea la instrucción apuntada por el PC.

| Archivo | Contenido |
|---|---|
| `PC_IMEM_tb.v` | Testbench `PC_IMEM_tb`: instancia el PC y la IMEM y comprueba los 10 ciclos |
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
| 10 ns | Flanco ↓: se imprime el ciclo 0 (`PC = 0`) |
| 15 ns | Flanco ↑: `PC = 0 + 1 = 1` |
| 10·k + 10 ns | Flanco ↓: se imprime el ciclo k (`PC = k`) |
| 100 ns | Ciclo 9: `PC = 9`, `j 9` |
| 104 ns | `$finish`, antes del flanco de 105 ns que llevaría el PC a 10 (palabra sin instrucción, `x`) |

- **Por qué en el flanco de bajada:** el PC cambia con `<=` en el flanco de subida. Medio ciclo después el
  PC ya está estable y la IMEM, que es combinacional, ya entregó la instrucción.
- **El salto no se ejecuta:** aquí el PC siempre avanza `+1`, así que `j 9` solo se lee y se decodifica
  (`address = 9`). Elegir entre `PC + 1` y la dirección del salto con la señal `Jump` es parte del datapath
  (Fase 4).

## Testbench (`PC_IMEM_tb.v`)
- Los campos se declaran como `wire` (`opcode = instruction[31:26]`, etc.) para verlos en GTKWave.
- Tarea `ciclo_cpu(pc_esperado, instr_esperada, caso)`: espera el flanco de bajada, compara el PC y la
  instrucción con `===` e imprime dos líneas con el formato de la portada de la plantilla:
  1. `PC=k, Instr=` con los campos separados por `_` según el formato, más el número de ciclo, el tiempo,
     el formato (R, I o J), `OK`/`ERROR` y el mnemónico esperado.
  2. Los campos por nombre. El inmediato también se muestra en decimal con signo y la dirección del salto en
     decimal.
- Si algo no coincide, imprime una tercera línea con el PC y la instrucción esperados.
- Lo esperado se escribe a mano, no se lee de la memoria. Comprobado: con `next_pc = current_pc + 4`, el
  testbench marca `ERROR` desde el ciclo 1 (`PC = 4` en vez de 1).
- Antes del primer flanco imprime el PC en `x`, como advierte la plantilla.
- `$dumpfile("PC_IMEM_tb.vcd")` y `$dumpvars(0, PC_IMEM_tb)`.

## Casos de prueba (resultados de la simulación)

| Ciclo | PC esperado | Instrucción esperada | PC obtenido | Instrucción obtenida (opcode / funct) | ¿OK? |
|:---:|:---:|---|:---:|---|:---:|
| 0 | 0 | `add $3, $1, $2` (R) | 0 | `000000` / `100000` | ✅ |
| 1 | 1 | `addi $9, $8, 10` (I) | 1 | `001000` / — | ✅ |
| 2 | 2 | `movi $1, 7` (I) | 2 | `001010` / — | ✅ |
| 3 | 3 | `movi $2, -3` (I) | 3 | `001010` / — | ✅ |
| 4 | 4 | `sub $4, $1, $2` (R) | 4 | `000000` / `100100` | ✅ |
| 5 | 5 | `mul $5, $1, $2` (R) | 5 | `000000` / `100001` | ✅ |
| 6 | 6 | `div $6, $5, $1` (R) | 6 | `000000` / `100010` | ✅ |
| 7 | 7 | `subi $7, $9, 15` (I) | 7 | `001001` / — | ✅ |
| 8 | 8 | `mov $10, $7` (R) | 8 | `000000` / `100011` | ✅ |
| 9 | 9 | `j 9` (J) | 9 | `000010` / — | ✅ |

`funct` solo existe en las instrucciones R; en las I y J esos bits son parte del inmediato o de la dirección.

### Salida de la consola
```
=== Testbench PC + IMEM ===
t=  1 ns  antes del primer flanco: PC=x, Instr=xxxxxxxx (x: el PC aun no se ha reiniciado)
ciclo 0  t= 10 ns  R  PC=0, Instr=000000_00001_00010_00011_00000_100000    OK     add  $3, $1, $2
                            opcode=000000 rs=00001 rt=00010 rd=00011 shamt=00000 funct=100000
ciclo 1  t= 20 ns  I  PC=1, Instr=001000_01000_01001_0000000000001010      OK     addi $9, $8, 10
                            opcode=001000 rs=01000 rt=01001 immediate=0000000000001010 (10)
ciclo 2  t= 30 ns  I  PC=2, Instr=001010_00000_00001_0000000000000111      OK     movi $1, 7
                            opcode=001010 rs=00000 rt=00001 immediate=0000000000000111 (7)
ciclo 3  t= 40 ns  I  PC=3, Instr=001010_00000_00010_1111111111111101      OK     movi $2, -3
                            opcode=001010 rs=00000 rt=00010 immediate=1111111111111101 (-3)
ciclo 4  t= 50 ns  R  PC=4, Instr=000000_00001_00010_00100_00000_100100    OK     sub  $4, $1, $2
                            opcode=000000 rs=00001 rt=00010 rd=00100 shamt=00000 funct=100100
ciclo 5  t= 60 ns  R  PC=5, Instr=000000_00001_00010_00101_00000_100001    OK     mul  $5, $1, $2
                            opcode=000000 rs=00001 rt=00010 rd=00101 shamt=00000 funct=100001
ciclo 6  t= 70 ns  R  PC=6, Instr=000000_00101_00001_00110_00000_100010    OK     div  $6, $5, $1
                            opcode=000000 rs=00101 rt=00001 rd=00110 shamt=00000 funct=100010
ciclo 7  t= 80 ns  I  PC=7, Instr=001001_01001_00111_0000000000001111      OK     subi $7, $9, 15
                            opcode=001001 rs=01001 rt=00111 immediate=0000000000001111 (15)
ciclo 8  t= 90 ns  R  PC=8, Instr=000000_00111_00000_01010_00000_100011    OK     mov  $10, $7
                            opcode=000000 rs=00111 rt=00000 rd=01010 shamt=00000 funct=100011
ciclo 9  t=100 ns  J  PC=9, Instr=000010_00000000000000000000001001        OK     j    9
                            opcode=000010 address=00000000000000000000001001 (9)
=== 10 ciclos, todas las pruebas OK ===
PC_IMEM_tb.v:139: $finish called at 104000 (1ps)
```

## Capturas
- `consola.png` ✅: desde esta carpeta, con **los dos comandos visibles** (`iverilog` y `vvp`) y
  las dos líneas por ciclo.
- `gtkwave.png` ✅: `clk`, `reset`, `current_pc` y `next_pc` en decimal, `instruction` en hex, `opcode`,
  `rs`, `rt`, `rd`, `shamt` y `funct` en binario, `immediate` en decimal con signo y `address` en decimal;
  los 10 ciclos a la vista (0–104 ns) con *Zoom Fit*. `PC_IMEM_tb.gtkw` abre esta misma vista.
- En GTKWave todos los campos muestran un valor en cada ciclo, aunque el formato no los use (en una
  instrucción I, `rd`, `shamt` y `funct` son bits del inmediato). Hay que interpretarlos según el `opcode`.

## Comandos
Ejecutar desde `03_PC_IMEM/`:
```powershell
iverilog -o PC_IMEM_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v PC_IMEM_tb.v
vvp PC_IMEM_tb.vvp
gtkwave PC_IMEM_tb.vcd PC_IMEM_tb.gtkw    # abre ya las señales con su formato; luego View → Zoom Fit
```
