# 07 — Banco de Registros (RegisterFile)

**Entrega 3 · Ejercicios 3–4** · Estado: ✅ implementado y verificado (19/19 pruebas OK) · `gtkwave.png` lista,
`consola.png` pendiente

## Objetivo
Guardar los 32 registros de propósito general del procesador (`$0`–`$31`, de 32 bits cada uno). En cada ciclo
entrega los dos operandos que pide la instrucción y, al final del ciclo, guarda el resultado en el registro
destino. `$0` vale siempre 0.

| Archivo | Contenido |
|---|---|
| `RegisterFile.v` | Módulo `RegisterFile` |
| `RegisterFile_tb.v` | Testbench `RegisterFile_tb`, con 19 pruebas automáticas en el orden de la plantilla |
| `RegisterFile_tb.gtkw` | Vista guardada de GTKWave: reloj, control, direcciones y datos en decimal |

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `clk` | input | 1 | Reloj del sistema |
| `reset` | input | 1 | Reinicio síncrono, activo en alto |
| `RegWrite` | input | 1 | Habilita la escritura |
| `read_reg1` | input | 5 | Número del registro que se lee por el puerto 1 |
| `read_reg2` | input | 5 | Número del registro que se lee por el puerto 2 |
| `write_reg` | input | 5 | Número del registro destino |
| `write_data` | input | 32 | Dato que se escribe |
| `read_data1` | output | 32 | Contenido de `read_reg1` |
| `read_data2` | output | 32 | Contenido de `read_reg2` |

Las direcciones tienen 5 bits porque 2⁵ = 32 registros.

## Cómo funciona el código

### Almacenamiento
```verilog
reg [31:0] registers [0:31];
```
Arreglo de 32 palabras de 32 bits; el índice es el número de registro (`registers[5]` es `$5`).

### Lectura asíncrona
```verilog
assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 : registers[read_reg1];
assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 : registers[read_reg2];
```
- Son asignaciones continuas: no esperan al reloj. En cuanto cambia `read_reg1`/`read_reg2`, o el contenido
  del registro leído, la salida cambia en ese mismo instante.
- Los dos puertos son independientes, así que se leen dos registros a la vez (los dos operandos de una
  instrucción R).
- Leer `$0` devuelve 0 directamente, sin consultar el arreglo.

### Escritura y reset síncronos
```verilog
always @(posedge clk) begin
    if (reset)                                   // los 32 registros <= 0
    else begin
        registers[0] <= 32'd0;
        if (RegWrite && (write_reg != 5'd0))
            registers[write_reg] <= write_data;
    end
end
```
- El contenido solo cambia en el flanco de subida, con asignación no bloqueante (`<=`).
- **Reset:** pone los 32 registros en 0 y tiene prioridad sobre la escritura. Es síncrono, igual que el PC.
- **Escritura:** solo si `RegWrite = 1` **y** el destino no es `$0`. Con `RegWrite = 0` el banco conserva su
  contenido aunque `write_reg` y `write_data` cambien.

### `$0` protegido en tres niveles

| Mecanismo | Efecto |
|---|---|
| La lectura de `$0` se fuerza a 0 | Los puertos devuelven 0 aunque el arreglo tuviera otro valor (por ejemplo `x` antes del reset) |
| Se ignora la escritura con `write_reg = 0` | Una instrucción con `$0` como destino no tiene efecto |
| `registers[0] <= 0` en cada ciclo | El valor interno también queda en 0, visible en `uut.registers[0]` y en GTKWave |

Con cualquiera de los dos primeros bastaría; juntos son redundantes pero no estorban.

### Antes del primer reset
Como el reset es síncrono, hasta el primer `posedge clk` con `reset = 1` los registros valen `x` (igual que el
PC). En ese intervalo, leer `$0` ya devuelve 0; cualquier otro registro devuelve `x` (prueba 1 del
testbench).

## Interacción con los otros módulos

El banco de registros está en el centro del datapath monociclo: lee los operandos que indica la instrucción,
se los entrega a la ALU y, al final del ciclo, guarda el resultado. Esa conexión se hará en la integración
(Fase 4 del README principal, fuera del alcance de esta práctica); por ahora el testbench prueba el módulo
aislado. Los valores de las señales de control salen de la tabla aprobada de la Unidad de Control
(decisión 3 del README principal).

```
                            ┌──────── RegisterFile ────────┐
 IMEM  rs  instr[25:21] ───►│ read_reg1         read_data1 ├───────────────────► ALU src1
 IMEM  rt  instr[20:16] ───►│ read_reg2         read_data2 ├───► MUX ALUSrc ───► ALU src2
 MUX RegDst (rd o rt) ─────►│ write_reg                    │         ▲
 ALU result (write-back) ──►│ write_data                   │         └── inmediato (tipo I)
 ControlUnit RegWrite ─────►│ RegWrite                     │
 clk, reset (= PC) ────────►│ clk, reset                   │
                            └──────────────────────────────┘
```

### Qué se conecta a cada puerto

| Puerto | Viene de / va a | Detalle |
|---|---|---|
| `read_reg1` | IMEM: `instruction[25:21]` (`rs`) | Primer operando fuente |
| `read_reg2` | IMEM: `instruction[20:16]` (`rt`) | Segundo operando fuente en las instrucciones R |
| `write_reg` | Mux controlado por `RegDst` (ControlUnit) | `rd` = `instruction[15:11]` si `RegDst = 1` (tipo R); `rt` si `RegDst = 0` (tipo I) |
| `write_data` | `result` de la ALU | Write-back: el resultado vuelve al banco |
| `RegWrite` | ControlUnit | 1 en R, MOVI, ADDI y SUBI; 0 en JUMP y en opcodes no definidos |
| `read_data1` | ALU `src1` | Conexión directa |
| `read_data2` | Mux `ALUSrc` → ALU `src2` | Llega a la ALU si `ALUSrc = 0`; con `ALUSrc = 1` la ALU recibe el inmediato |
| `clk`, `reset` | Los mismos que el PC | Los dos se reinician en el mismo flanco |

ALUControl no se conecta directamente al banco: a partir de `ALUOp` y `funct` elige la operación de la ALU y,
con ello, el valor que llega a `write_data`.

### Uso por tipo de instrucción

| Instrucción | Lee | Escribe en | `write_data` | RegDst | ALUSrc | RegWrite |
|---|---|---|---|:---:|:---:|:---:|
| ADD, SUB, MUL, DIV | `$rs`, `$rt` | `$rd` | `$rs` op `$rt` | 1 | 0 | 1 |
| MOV | `$rs` | `$rd` | `$rs` (`alu_control = 0001`) | 1 | 0 | 1 |
| MOVI | — | `$rt` | `imm` (`alu_control = 0000`) | 0 | 1 | 1 |
| ADDI, SUBI | `$rs` | `$rt` | `$rs ± imm` | 0 | 1 | 1 |
| JUMP | — | nada | — | 0 | 0 | 0 |

Los puertos de lectura siempre leen los registros que indiquen los bits de `rs` y `rt`, aunque la
instrucción no los use (en una tipo I, `rt` es el destino y no un operando; en JUMP esos bits forman parte de
la dirección). Leer no modifica nada: el valor que sobra lo descarta el mux `ALUSrc` o la propia ALU. Lo único
que protege el contenido del banco es `RegWrite`.

### Recorrido de un ciclo: `add $3, $1, $2`
Es la instrucción de la dirección 0 de la IMEM.

1. **Flanco ↑ (inicio del ciclo):** el PC pasa a 0 y la IMEM entrega `000000_00001_00010_00011_00000_100000`.
2. **Lectura, sin esperar al reloj:** `rs = 1` → `read_data1 = $1`; `rt = 2` → `read_data2 = $2`.
3. **Control y ALU (combinacionales):** la ControlUnit ve el opcode `000000` y genera `RegDst = 1`,
   `ALUSrc = 0`, `RegWrite = 1` y `ALUOp = 10`; ALUControl, con `funct = 100000`, da `0010`; la ALU calcula
   `$1 + $2`.
4. **Flanco ↑ (fin del ciclo):** con `write_reg = rd = 3`, el banco guarda `result` en `$3`. En el mismo
   flanco el PC avanza a la instrucción siguiente.

Con `addi $9, $8, 10` (dirección 1), `rs = 8` se lee por `read_data1`, `RegDst = 0` elige `rt = 9` como
destino y `ALUSrc = 1` manda el inmediato `10` a la ALU en lugar de `read_data2`.

**Por qué lectura asíncrona y escritura síncrona:** así una instrucción completa cabe en un ciclo. Si una
instrucción lee y escribe el mismo registro (`add $1, $1, $2`), durante el ciclo se lee el valor anterior y
el nuevo solo se guarda en el flanco, así que no hay carrera. El caso 10 del testbench lo comprueba.

## Testbench (`RegisterFile_tb.v`)
- Reloj de 10 ns (`always #5 clk = ~clk`): flancos de subida en t = 5, 15, 25, … ns.
- Las entradas de escritura cambian en el flanco de bajada, lejos del flanco activo, y los registros se
  imprimen 1 ns después del flanco de subida, cuando los `<=` ya se asentaron.
- Tareas:
  - `ciclo(we, dir, dato)`: un ciclo con `RegWrite = we`. Después del flanco imprime `R1`, `R2`, `R3` y `R0`
    con el formato del enunciado (`R1=10, R2=20, R3=30, R0=0`) y, al final, el registro destino. Lee el
    arreglo con el nombre de la instancia: `uut.registers[i]`.
  - `leer(r1, r2, esp1, esp2, caso)`: pone las direcciones en los dos puertos, espera 1 ns **sin flanco de
    reloj** y compara las dos salidas con `!==` (una `x` cuenta como error).
  - `comprobar(valor, esperado, caso)`: compara un valor suelto, por ejemplo `uut.registers[0]`.
  - `revisar_reset(caso)`: revisa los 32 registros del arreglo después de un reset; cuenta como una prueba.
- Las pruebas siguen los casos 1–11 de la plantilla, en orden. Cada línea de prueba lleva el tiempo `t`, así
  se ve qué lecturas ocurren sin flanco de por medio.
- Al final imprime el total de pruebas y si hubo errores.
- `$dumpfile("RegisterFile_tb.vcd")` y `$dumpvars(0, RegisterFile_tb)`.
- **Comprobación del testbench:** con cuatro errores introducidos a propósito en `RegisterFile.v` (permitir
  escribir en `$0`, reset asíncrono, ignorar `RegWrite`, no forzar `$0` en la lectura) el testbench reporta
  errores en los cuatro.

## Casos de prueba (resultados de la simulación)

Las columnas siguen la tabla de la plantilla. Flancos de subida en t = 5, 15, 25, … ns.

| # | Caso de prueba | Qué se hace (dirección · dato · RegWrite) | Esperado | Obtenido (consola) | ¿OK? |
|---|---|---|---|---|:---:|
| 1 | Reset | `reset = 1` durante el flanco de 5 ns; se suelta en 6 ns | Los 32 registros en 0 | 0 de 32 distintos de 0; `R1=0, R2=0, R3=0, R0=0` | ✅ |
| 2 | Escribir y leer un registro | `$1` · 10 · 1; leer `$1` y `$0` | `10`, `0` | `10`, `0` | ✅ |
| 3 | Dos registros a la vez | `$2` · 20 · 1 y `$3` · 30 · 1; leer `($2, $3)` y `($3, $3)` | `20, 30` · `30, 30` | `20, 30` · `30, 30` | ✅ |
| 4 | Intento de escribir en `$0` | `$0` · 999 · 1; leer `$0` por los dos puertos y en el arreglo | `0, 0` y `uut.registers[0] = 0` | `0, 0` y `0` | ✅ |
| 5 | `RegWrite = 0` | `$2` · 777 · 0; leer `($2, $3)` | `20, 30` (no cambia) | `20, 30` | ✅ |
| 6 | Lectura asíncrona | Sin flanco (t = 57, 58 y 59 ns): `($2, $3)`, `($1, $2)`, `($3, $1)` | `20, 30` · `10, 20` · `30, 10` | `20, 30` · `10, 20` · `30, 10` | ✅ |
| 7 | Escritura síncrona | `$4` · 40 · 1 en t = 60 ns; el dato cambia a 44 en t = 62 ns; flanco en 65 ns | `$4 = 0` antes del flanco; `44` después | `0` · `44` | ✅ |
| 8 | Sobrescribir | `$2` · 200 · 1 (tenía 20) | `$2 = 200` | `200` | ✅ |
| 9 | Último registro | `$31` · `0xDEADBEEF` · 1 | `3735928559` (`0xDEADBEEF`) | `3735928559` | ✅ |
| 10 | Leer lo que se está escribiendo | `$1` · 99 · 1, leyendo `$1` | Antes del flanco `10` (viejo); después `99` | `10` · `99` | ✅ |
| 11 | Reset con datos | `reset = 1` en t = 100 ns, con `$3` · 555 · 1; flanco en 105 ns | En 101 ns los datos siguen (`99`, `3735928559`); en el flanco los 32 pasan a 0 y `$3` no toma 555 | `99`, `3735928559` · 0 de 32 · `$3 = 0` | ✅ |
| — | Adicional: antes del primer reset | t = 1 ns, sin flanco aún; leer `$0` y `$1` | `0` (protección de `$0`) y `x` | `0`, `x` | ✅ |

**Total: 19 pruebas, 0 errores.** En el caso 11, «cuándo» es la clave: el reset es síncrono, así que
activarlo no borra nada hasta el siguiente flanco de subida.

### Salida de la consola
```
=== Testbench RegisterFile ===
 1  t=  1 ns  read_reg1=0 -> 0  read_reg2=1 -> x | esperado=0, x  OK     Adicional: antes del reset, $0 lee 0
 2  t=  6 ns  registros distintos de 0: 0 de 32 | esperado=0  OK     Caso 1: reset = 1, los 32 en 0
    t=  6 ns  RegWrite=0 write_reg=0 write_data=0 -> R1=0, R2=0, R3=0, R0=0 | R0=0
    t= 16 ns  RegWrite=1 write_reg=1 write_data=10 -> R1=10, R2=0, R3=0, R0=0 | R1=10
 3  t= 17 ns  read_reg1=1 -> 10  read_reg2=0 -> 0 | esperado=10, 0  OK     Caso 2: escribir y leer $1
    t= 26 ns  RegWrite=1 write_reg=2 write_data=20 -> R1=10, R2=20, R3=0, R0=0 | R2=20
    t= 36 ns  RegWrite=1 write_reg=3 write_data=30 -> R1=10, R2=20, R3=30, R0=0 | R3=30
 4  t= 37 ns  read_reg1=2 -> 20  read_reg2=3 -> 30 | esperado=20, 30  OK     Caso 3: $2 y $3 a la vez
 5  t= 38 ns  read_reg1=3 -> 30  read_reg2=3 -> 30 | esperado=30, 30  OK     Caso 3: $3 por los dos puertos
    t= 46 ns  RegWrite=1 write_reg=0 write_data=999 -> R1=10, R2=20, R3=30, R0=0 | R0=0
 6  t= 47 ns  read_reg1=0 -> 0  read_reg2=0 -> 0 | esperado=0, 0  OK     Caso 4: $0 sigue en 0 (puertos)
 7  t= 47 ns  valor=0 | esperado=0  OK     Caso 4: $0 sigue en 0 (arreglo)
    t= 56 ns  RegWrite=0 write_reg=2 write_data=777 -> R1=10, R2=20, R3=30, R0=0 | R2=20
 8  t= 57 ns  read_reg1=2 -> 20  read_reg2=3 -> 30 | esperado=20, 30  OK     Caso 5: RegWrite=0, $2 sigue en 20
 9  t= 58 ns  read_reg1=1 -> 10  read_reg2=2 -> 20 | esperado=10, 20  OK     Caso 6: otra direccion, sin flanco
10  t= 59 ns  read_reg1=3 -> 30  read_reg2=1 -> 10 | esperado=30, 10  OK     Caso 6: otra direccion, sin flanco
11  t= 61 ns  read_reg1=4 -> 0  read_reg2=0 -> 0 | esperado=0, 0  OK     Caso 7: antes del flanco $4 = 0
    t= 66 ns  RegWrite=1 write_reg=4 write_data=44 -> R1=10, R2=20, R3=30, R0=0 | R4=44
12  t= 67 ns  read_reg1=4 -> 44  read_reg2=0 -> 0 | esperado=44, 0  OK     Caso 7: se guarda 44, el dato del flanco
    t= 76 ns  RegWrite=1 write_reg=2 write_data=200 -> R1=10, R2=200, R3=30, R0=0 | R2=200
13  t= 77 ns  read_reg1=2 -> 200  read_reg2=1 -> 10 | esperado=200, 10  OK     Caso 8: $2 sobrescrito, 20 -> 200
    t= 86 ns  RegWrite=1 write_reg=31 write_data=3735928559 -> R1=10, R2=200, R3=30, R0=0 | R31=3735928559
14  t= 87 ns  read_reg1=31 -> 3735928559  read_reg2=0 -> 0 | esperado=3735928559, 0  OK     Caso 9: $31 = 0xDEADBEEF
15  t= 91 ns  read_reg1=1 -> 10  read_reg2=2 -> 200 | esperado=10, 200  OK     Caso 10: antes del flanco, $1 viejo
    t= 96 ns  RegWrite=1 write_reg=1 write_data=99 -> R1=99, R2=200, R3=30, R0=0 | R1=99
16  t= 97 ns  read_reg1=1 -> 99  read_reg2=2 -> 200 | esperado=99, 200  OK     Caso 10: despues del flanco, $1 nuevo
17  t=101 ns  read_reg1=1 -> 99  read_reg2=31 -> 3735928559 | esperado=99, 3735928559  OK     Caso 11: reset=1, sin flanco aun
18  t=106 ns  registros distintos de 0: 0 de 32 | esperado=0  OK     Caso 11: en el flanco, los 32 en 0
    t=106 ns  RegWrite=1 write_reg=3 write_data=555 -> R1=0, R2=0, R3=0, R0=0 | R3=0
19  t=107 ns  read_reg1=3 -> 0  read_reg2=31 -> 0 | esperado=0, 0  OK     Caso 11: $3 no tomo 555
=== 19 pruebas, todas las pruebas OK ===
RegisterFile_tb.v:244: $finish called at 107000 (1ps)
```

## Capturas
- `gtkwave.png` (lista): `clk`, `reset`, `RegWrite`, `write_reg`, `write_data`, `read_reg1`, `read_data1`,
  `read_reg2` y `read_data2`, en decimal, con los 107 ns a la vista. Se ve que `write_data` cambia de 40 a 44
  entre flancos (caso 7), que las lecturas cambian a mitad de ciclo, sin flanco (57–59 ns), y que
  `read_data2` vale `x` antes del primer reset.
- `consola.png` (pendiente): desde esta carpeta, con **los dos comandos visibles** (`iverilog` y `vvp`) y la
  salida completa.

## Comandos
```powershell
iverilog -o RegisterFile_tb.vvp RegisterFile.v RegisterFile_tb.v
vvp RegisterFile_tb.vvp
gtkwave RegisterFile_tb.vcd RegisterFile_tb.gtkw    # abre ya las 9 señales; luego View → Zoom Fit
```

En la integración, compilar `../07_RegisterFile/RegisterFile.v` desde esta carpeta en lugar de copiarlo
(convención del README principal).
