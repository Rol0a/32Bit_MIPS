# 07 — Banco de Registros (RegisterFile)

**Entrega 3 · Ejercicios 3–4** · Estado: ✅ implementado y verificado (85/85 comprobaciones OK) · capturas pendientes

## Objetivo
Guardar los 32 registros de propósito general del procesador (`$0`–`$31`, de 32 bits cada uno). En cada ciclo
entrega los dos operandos que pide la instrucción y, al final del ciclo, guarda el resultado en el registro
destino. `$0` vale siempre 0.

| Archivo | Contenido |
|---|---|
| `RegisterFile.v` | Módulo `RegisterFile` |
| `RegisterFile_tb.v` | Testbench `RegisterFile_tb`, con 85 comprobaciones automáticas |

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
PC). En ese intervalo, leer `$0` ya devuelve 0; cualquier otro registro devuelve `x`.

## Interacción con los otros módulos

El banco de registros está en el centro del datapath monociclo: lee los operandos que indica la instrucción,
se los entrega a la ALU y, al final del ciclo, guarda el resultado. Esa conexión se hará en la integración
(Fase 4 del README principal, fuera del alcance de esta práctica); por ahora el testbench prueba el módulo
aislado. Los valores de las señales de control salen de la tabla de la Unidad de Control, que todavía es
una propuesta (decisión 3 del README principal).

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
el nuevo solo se guarda en el flanco, así que no hay carrera. El caso 6 del testbench lo comprueba.

## Testbench (`RegisterFile_tb.v`)
- Reloj de 10 ns (`always #5 clk = ~clk`): flancos de subida en t = 5, 15, 25, … ns.
- Las entradas cambian en el flanco de bajada, lejos del flanco activo, y se comprueba 1 ns después del
  flanco de subida, cuando los `<=` ya se asentaron.
- Tareas:
  - `verificar(obtenido, esperado)`: compara con `!==` (una `x` cuenta como error), lleva la cuenta de
    pruebas y errores e imprime solo los errores.
  - `escribir(dir, dato)`: escribe durante un ciclo con `RegWrite = 1` y muestra `R1`, `R2`, `R3` y `R0`
    mediante acceso jerárquico (`uut.registers[i]`).
  - `leer_y_verificar(dir1, dir2, esp1, esp2)`: pone las direcciones en los dos puertos, espera 1 ns sin
    flanco de reloj y verifica ambas salidas.
- Al final imprime el total de pruebas y de errores.
- `$dumpfile("RegisterFile_tb.vcd")` y `$dumpvars(0, RegisterFile_tb)`.

## Casos de prueba (resultados de la simulación)

| # | Caso | Entradas | Esperado | Obtenido | Comprob. | ¿OK? |
|---|---|---|---|---|:---:|:---:|
| 1 | Reset inicial: los 32 registros quedan en 0 | `reset = 1` durante un flanco | `$0`–`$31` = 0 | `$0`–`$31` = 0 | 32 | ✅ |
| 2 | Escritura y lectura por ambos puertos | `$1 ← 10`, `$2 ← 20`, `$3 ← 30` | `$1 = 10`, `$2 = 20`, `$3 = 30` | `$1 = 10`, `$2 = 20`, `$3 = 30` | 6 | ✅ |
| 3 | Escribir en `$0` no tiene efecto | `$0 ← 999` | `$0 = 0` (puerto y arreglo) | `$0 = 0` | 3 | ✅ |
| 4 | `RegWrite = 0` no escribe | `write_reg = 2`, `write_data = 777` | `$2 = 20` | `$2 = 20` | 2 | ✅ |
| 5 | Último registro con los 32 bits | `$31 ← 0xDEADBEEF` | `$31 = 3735928559` | `$31 = 3735928559` | 2 | ✅ |
| 6 | La escritura espera al flanco ↑ | `$1 ← 99`; leer `$1` antes y después del flanco | `10` → `99` | `10` → `99` | 2 | ✅ |
| 7 | Lectura asíncrona: cambiar direcciones sin flanco | `(2, 3)` y luego `(1, 31)` | `20, 30` · `99, 0xDEADBEEF` | `20, 30` · `99, 0xDEADBEEF` | 4 | ✅ |
| 8 | Reset con prioridad sobre `RegWrite` | `reset = 1`, `RegWrite = 1`, `$3 ← 555` | los 32 en 0; `$3 = 0` | los 32 en 0; `$3 = 0` | 34 | ✅ |
| | **Total** | | | | **85** | **0 errores** |

### Salida de la consola
```
=== Pruebas de RegisterFile ===
Reset inicial: 32 registros comprobados.
Escritura R1 <- 10 | R1=10 R2=0 R3=0 R0=0
Lectura: R1=10 | R0=0
Escritura R2 <- 20 | R1=10 R2=20 R3=0 R0=0
Lectura: R1=10 | R2=20
Escritura R3 <- 30 | R1=10 R2=20 R3=30 R0=0
Lectura: R3=30 | R0=0
Escritura R0 <- 999 | R1=10 R2=20 R3=30 R0=0
Lectura: R0=0 | R1=10
Lectura: R2=20 | R3=30
Escritura R31 <- 3735928559 | R1=10 R2=20 R3=30 R0=0
Lectura: R31=3735928559 | R0=0
Escritura sincronica: R1=99
Lectura: R2=20 | R3=30
Lectura: R1=99 | R31=3735928559
Lectura: R3=0 | R0=0
=== Fin: pruebas=85, errores=0 ===
RegisterFile_tb.v:181: $finish called at 87 (1ns)
```

## Capturas (`capturas/`, pendientes)
- `consola.png`: comandos de compilación y ejecución, y la salida completa.
- `gtkwave.png`: `clk`, `reset`, `RegWrite`, `write_reg`, `write_data`, `read_reg1`, `read_data1`,
  `read_reg2` y `read_data2` (direcciones en decimal; datos en decimal o hex), con *Zoom Fit*. La simulación
  dura 87 ns.

## Comandos
```powershell
iverilog -o RegisterFile_tb.vvp RegisterFile.v RegisterFile_tb.v
vvp RegisterFile_tb.vvp
gtkwave RegisterFile_tb.vcd
```

En la integración, compilar `../07_RegisterFile/RegisterFile.v` desde esta carpeta en lugar de copiarlo
(convención del README principal).
