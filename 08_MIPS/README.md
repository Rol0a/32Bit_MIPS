# 08 — Procesador MIPS completo (datapath monociclo)

**Fase 4 · Integración → Entrega Final 1** · Estado: ✅ implementado y verificado con el programa de clase
(26/26 ciclos y 32/32 registros OK) · faltan `consola.png` y la foto del CMD

## Objetivo
Conectar los seis módulos en un procesador que ejecute el programa de la IMEM de principio a fin: una
instrucción por ciclo, con el resultado guardado en el banco de registros y el siguiente PC elegido entre
`PC + 1` y la dirección del salto. Para la Entrega Final el programa son las **26 instrucciones binarias de
clase** (ver [`02_IMEM`](../02_IMEM/README.md)).

| Archivo | Contenido |
|---|---|
| `MIPS.v` | Módulo superior `MIPS`: seis instancias y la interconexión, toda con `assign` |
| `MIPS_tb.v` | Testbench `MIPS_tb`: 26 ciclos comprobados señal por señal y estado final de los 32 registros |
| `MIPS_tb.gtkw` | Vista guardada de GTKWave: búsqueda, control, ejecución y registros `$1`–`$20` |
| `gtkwave.png` | Captura de GTKWave |

Reutiliza, sin copiarlos ni modificarlos, `../01_PC/PC.v`, `../02_IMEM/IMEM.v`,
`../04_ControlUnit/ControlUnit.v`, `../05_ALU/ALU.v`, `../06_ALUControl/ALUControl.v` y
`../07_RegisterFile/RegisterFile.v`.

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `clk` | input | 1 | Reloj del PC y del banco de registros |
| `reset` | input | 1 | Reinicio síncrono, activo en alto: `PC = 0` y los 32 registros en `0` |
| `current_pc` | output | 32 | Dirección de la instrucción en ejecución |
| `instruction` | output | 32 | Instrucción en ejecución |
| `alu_result` | output | 32 | Resultado de la ALU: se escribe en el banco si `RegWrite = 1` |

Las salidas permiten observar el procesador desde fuera. Las señales internas (control, operandos, destino,
siguiente PC) se leen en el testbench con una referencia jerárquica: `uut.RegDst`, `uut.src2`, etc.

## Conexión

```
BÚSQUEDA        pc_reg ── current_pc ──► imem ──► instruction
                                                   ├─ opcode    [31:26] ──► cu
                                                   ├─ rs        [25:21] ──► rf.read_reg1
                                                   ├─ rt        [20:16] ──► rf.read_reg2 y mux RegDst
                                                   ├─ rd        [15:11] ──► mux RegDst
                                                   ├─ funct     [5:0]   ──► aluc
                                                   ├─ immediate [15:0]  ──► extensión de signo
                                                   └─ address   [25:0]  ──► mux Jump

DECODIFICACIÓN  cu   : opcode ──► RegDst, ALUSrc, RegWrite, Jump, ALUOp
                aluc : ALUOp + funct ──► alu_control
                rf   : rs, rt ──► read_data1 ($rs), read_data2 ($rt)
                imm_ext = {{16{immediate[15]}}, immediate}

EJECUCIÓN       src2 = ALUSrc ? imm_ext : read_data2
                alu  : read_data1, src2, alu_control ──► alu_result, zero

ESCRITURA       write_reg  = RegDst ? rd : rt
                write_data = alu_result          → rf lo guarda en el flanco ↑ si RegWrite = 1

SIGUIENTE PC    pc_plus1 = current_pc + 1
                next_pc  = Jump ? {6'b000000, address} : pc_plus1   → pc_reg lo carga en el flanco ↑
```

### Instancias

| Instancia | Módulo | Entradas | Salidas |
|---|---|---|---|
| `pc_reg` | `PC` | `clk`, `reset`, `next_pc` | `current_pc` |
| `imem` | `IMEM` | `current_pc` | `instruction` |
| `cu` | `ControlUnit` | `opcode` | `RegDst`, `ALUSrc`, `RegWrite`, `Jump`, `ALUOp` |
| `aluc` | `ALUControl` | `ALUOp`, `funct` | `alu_control` |
| `rf` | `RegisterFile` | `clk`, `reset`, `RegWrite`, `rs`, `rt`, `write_reg`, `write_data` | `read_data1`, `read_data2` |
| `alu` | `ALU` | `read_data1`, `src2`, `alu_control` | `alu_result`, `zero` |

### Interconexión: solo `assign`

| Pieza | `assign` | Ancho | Por qué así |
|---|---|:---:|---|
| Campos | `opcode = instruction[31:26]`, `rs = [25:21]`, `rt = [20:16]`, `rd = [15:11]`, `funct = [5:0]`, `immediate = [15:0]`, `address = [25:0]` | — | Se cortan todos; cada módulo o mux toma el que le corresponde. `shamt` no se usa |
| Extensión de signo | `imm_ext = {{16{immediate[15]}}, immediate}` | 16 → 32 | D7: la ALU es con signo; un inmediato negativo (`-3`) debe llegar como `0xFFFFFFFD` |
| Mux `RegDst` | `write_reg = RegDst ? rd : rt` | 5 | Las R escriben en `rd`; las I, en `rt` |
| Mux `ALUSrc` | `src2 = ALUSrc ? imm_ext : read_data2` | 32 | El segundo operando es un registro (R) o el inmediato (I) |
| Write-back | `write_data = alu_result` | 32 | Sin memoria de datos no hace falta el mux `MemtoReg` |
| Sumador | `pc_plus1 = current_pc + 32'd1` | 32 | D6: direccionamiento por palabra |
| Mux `Jump` | `next_pc = Jump ? {6'b000000, address} : pc_plus1` | 32 | D8: dirección de palabra directa, completada con ceros |

## Decisiones de diseño

1. **La interconexión es solo `assign`.** Son piezas combinacionales sin estado: un `assign` por pieza se lee
   igual que la ecuación del datapath ([Arquitectura §5.8](../docs/Arquitectura.md#s5-8)) y no hace falta un
   módulo con su propio testbench para un mux de dos entradas. `MIPS.v` no tiene ningún `always`: todo el
   comportamiento secuencial está dentro del PC y del banco.
2. **Los módulos no se tocan.** Se compilan desde su carpeta; el datapath usa exactamente el código verificado
   de cada módulo.
3. **Mismo `clk` y `reset` para el PC y el banco.** Los dos son síncronos y se actualizan en el mismo flanco.
   Con `<=` el banco guarda el resultado de la instrucción que termina, no el de la siguiente
   ([Arquitectura §6.2](../docs/Arquitectura.md#s6)).
4. **Nombres de instancia cortos.** `rf` permite leer el arreglo del banco desde el testbench con
   `uut.rf.registers[i]` (la «referencia jerárquica» de la plantilla: `instancia.banco.registros[i]`).
5. **`zero` queda sin usar.** Ninguna instrucción de esta ISA la consulta; está conectada a un `wire` para un
   futuro `beq`.
6. **Sin etapa Memory.** El datapath de referencia trae DMEM, `MemRead`, `MemWrite` y `MemtoReg`, pero la ISA
   no tiene `lw` ni `sw`. No se implementan: equivale a `MemRead = MemWrite = 0` y `MemtoReg = 0` fijos, así
   que al banco siempre llega el resultado de la ALU (`write_data = alu_result`).

### Hallazgo: antes del primer flanco `RegWrite` vale `x`, no `0`
Un `always @(*)` solo se ejecuta cuando cambia una de sus entradas. Antes del primer flanco el `opcode` vale
`x` desde el instante 0 y no cambia hasta que el reset pone el PC en 0 (5 ns), así que los `always` de
ControlUnit, ALUControl y ALU todavía no se han ejecutado y sus salidas conservan el valor inicial `x`. En
GTKWave se ven en rojo de 0 a 5 ns. No hay riesgo: en ese primer flanco `reset = 1` y **el reset del banco
tiene prioridad sobre `RegWrite`**, así que no hay escrituras espurias. El testbench lo comprueba en la primera
línea (PC en 0) y en los 32 registros finales.

## Entrega Final 1: cómo responde el diseño

### El ciclo de una instrucción (tabla de la portada de la plantilla)

| Etapa | Módulos de nuestro diseño | Dónde se ve en la salida |
|---|---|---|
| Fetch | `pc_reg` (`PC.v`), `imem` (`IMEM.v`), `pc_plus1` y mux `Jump` (`MIPS.v`) | Consola: `PC=… Instr=…`. GTKWave: `current_pc`, `instruction`, `next_pc` |
| Decode | Campos (`assign` en `MIPS.v`), `cu` (`ControlUnit.v`), `aluc` (`ALUControl.v`), `rf` lee `rs` y `rt`, extensión de signo | Consola: `RegDst=… ALUOp=…` y el mnemónico de la fila. GTKWave: grupo Control |
| Execute | Mux `ALUSrc`, `alu` (`ALU.v`) | Consola: `rd1=… rd2=… ALU=…`. GTKWave: `read_data1`, `read_data2`, `src2`, `alu_result` |
| Memory | No hay DMEM (decisión 6) | — |
| Write Back | Mux `RegDst`, `rf` (`RegisterFile.v`) escribe en el flanco ↑ | Consola: `$rd<=valor`, el dato que llega al banco; las 32 líneas finales (`$n = valor`) lo leen del banco. GTKWave: `write_reg` y `R1`–`R20` |

### Cuántos ciclos y por qué
**26 ciclos** después del reset, uno por instrucción (monociclo):
- **22** para las instrucciones 1 a 22 (PC 0 a 21). La 22 es `JUMP 1024`: el PC pasa a 1024.
- **4** más, en PC 1024 a 1027: son los turnos que ocuparían las instrucciones 23 a 26, que nunca se
  ejecutan. Fuera de la IMEM se lee `0`, una NOP, así que se ve que después del salto el PC sigue avanzando y
  ningún registro cambia.

### Decisiones de diseño (sección 9 de la plantilla)

| Situación | Qué decidió el grupo y por qué |
|---|---|
| `JUMP 1024` (instrucción 22) | La IMEM tiene 1024 palabras (0–1023) y **fuera de ese rango devuelve `0`**. `0` es una NOP (tipo R, `funct = 000000` → ALUControl `1111` → ALU `0`, destino `$0`). Tras el salto el PC sigue contando 1025, 1026, … y lee NOPs: **los registros quedan congelados** y las instrucciones 23 a 26 no se ejecutan. Sin la comprobación de rango, `addr[9:0]` de 1024 sería 0 y el programa volvería a empezar (mutación 6). |
| `MOVI $0, 255` (instrucción 26) | `$0` vale **0** al final. La instrucción ni siquiera se ejecuta (queda después del salto), pero aunque se ejecutara el banco la ignora: no escribe si `write_reg = 0`, fuerza `registers[0] <= 0` en cada flanco y la lectura de `$0` devuelve 0 sin consultar el arreglo. Con la mutación 4 (sin salto) sí se ejecuta, y `$0` sigue en 0. |
| SUBI | La Unidad de Control manda `ALUOp = 11` para el opcode `001001`; ALUControl lo traduce a `0110` (el código de SUB) y el mux `ALUSrc = 1` pone el inmediato extendido como `src2`: `ALU = $rs − imm`. Se ve en las instrucciones 11 y 19: `ALUOp=11` en la consola y `alu_control = 0110` en GTKWave. |
| Etapa Memory | No hay DMEM: la ISA no tiene cargas ni almacenamientos. Equivale a `MemRead = 0`, `MemWrite = 0` y `MemtoReg = 0`, así que al registro llega siempre el resultado de la ALU. |
| Palabra sin programa | **Cero:** es la NOP de arriba; las palabras 26–1023 de la IMEM se inicializan en 0. **`x`:** si llegara una palabra sin inicializar, el `opcode` sería `x`, la ControlUnit cae en su `default` (`RegWrite = 0`, `Jump = 0`) y no escribe nada; el PC avanza `+1`. |

## Temporización

| t | Evento |
|---|---|
| 0–5 ns | Todo en `x`: el PC no se ha reiniciado, la IMEM lee `memory[x]` y el control aún no se evalúa |
| 5 ns | Primer flanco ↑ con `reset = 1`: `PC = 0` y los 32 registros en `0` |
| 6 ns | Se suelta `reset` |
| 10 + 10·k ns | Flanco ↓: se compara el ciclo k y se imprime su línea |
| 15 + 10·k ns | Flanco ↑: el banco guarda el resultado del ciclo k y el PC carga `next_pc` |
| 220 ns | Ciclo 21: `JUMP 1024`, `next_pc = 1024` |
| 230–266 ns | Ciclos 22–25: PC 1024–1027, NOPs; ningún registro cambia |
| 266 ns | Se imprimen y comparan los 32 registros |
| 270 ns | `$finish` |

## Testbench (`MIPS_tb.v`)
- **Carga del programa:** la IMEM carga las 26 instrucciones de clase en su `initial` al empezar la
  simulación; el testbench comprueba en cada ciclo que la instrucción leída es la esperada.
- **Mismo formato que los demás testbenches:** aquí no hay entradas que poner, el procesador avanza solo, así
  que cada ciclo pone en `esperado` sus valores calculados a mano y luego imprime con
  `@(negedge clk) $display(...)`. `esperado` junta en un vector, como en `ControlUnit_tb`, las columnas de la
  tabla: el PC, la instrucción, las cinco señales de control `RegDst_ALUSrc_RegWrite_Jump_ALUOp`,
  `alu_control`, `read_data1`, `read_data2`, el resultado de la ALU, `write_reg` y `next_pc`; un comentario
  arriba de la primera fila nombra cada columna.
- `wire ok` compara ese vector con las señales del ciclo usando `===`, y además que `zero` valga 1 solo si el
  resultado es 0. Las señales internas se leen con `uut.` y se les da en el testbench el nombre de su columna
  en la consola (`rd1 = uut.read_data1`, `wreg = uut.write_reg`, …), así el `$display` queda corto.
- Cada línea muestra lo que evalúa la plantilla: decodificación (`RegDst=… ALUOp=…`), acceso a registros
  (`rd1=… rd2=… ALU=…`) y resultado (`$rd<=valor`, el dato que llega al banco), más `OK`/`ERROR` y el
  mnemónico, escrito al final del texto del `$display` de esa fila.
- **Lo esperado se calcula a mano**, con la traza de abajo y la tabla de [`02_IMEM`](../02_IMEM/README.md);
  nada se lee del propio procesador. Se contrastó además con un modelo independiente del programa (fuera del
  repositorio).
- **Registros finales:** tras el último flanco (266 ns), una línea por registro con el valor esperado escrito
  en la misma línea: `$display("$13 = %-5d %0s", R13, R13 === -25 ? "OK" : "ERROR")`. `$18` a `$31` deben valer
  0 y van en un `for`. **Esa es la salida que se fotografía.** No hay línea de resumen: un fallo se ve como
  `ERROR` en su fila. El reset y cada escritura no tienen línea propia: un PC sin reiniciar falla en la primera
  fila, y un registro mal escrito, en la fila que lo lee o en su línea final.
- `R1` a `R20` son `wire signed` conectados a `uut.rf.registers[i]`: `$dumpvars` no vuelca arreglos, y así los
  registros se ven en GTKWave; `signed` hace que `%d` imprima `$13 = -25`.
- `$dumpfile("MIPS_tb.vcd")` y `$dumpvars(0, MIPS_tb)` (incluye las señales internas de `uut`).

## Casos de prueba (resultados de la simulación)

Señales en el orden `RegDst ALUSrc RegWrite Jump ALUOp`. Todos los valores esperados se calcularon a mano antes
de simular; los obtenidos son los de la consola. `rd2` es siempre `$rt`, aunque en las I no se use.

| # | PC | Instrucción | Señales | `alu_control` | `rd1` | `rd2` | ALU | `write_reg` | `next_pc` | Escritura esperada | Obtenida | ¿OK? |
|:---:|:---:|---|:---:|:---:|---:|---:|---:|:---:|:---:|---|---|:---:|
| 1 | 0 | `MOVI $1, 15` | `0 1 1 0 00` | `0000` | 0 | 0 | 15 | 1 | 1 | `$1 = 15` | `$1 = 15` | ✅ |
| 2 | 1 | `MOVI $2, 20` | `0 1 1 0 00` | `0000` | 0 | 0 | 20 | 2 | 2 | `$2 = 20` | `$2 = 20` | ✅ |
| 3 | 2 | `MOVI $3, 50` | `0 1 1 0 00` | `0000` | 0 | 0 | 50 | 3 | 3 | `$3 = 50` | `$3 = 50` | ✅ |
| 4 | 3 | `MOVI $4, 5` | `0 1 1 0 00` | `0000` | 0 | 0 | 5 | 4 | 4 | `$4 = 5` | `$4 = 5` | ✅ |
| 5 | 4 | `MOVI $5, 2` | `0 1 1 0 00` | `0000` | 0 | 0 | 2 | 5 | 5 | `$5 = 2` | `$5 = 2` | ✅ |
| 6 | 5 | `ADD $6, $1, $2` | `1 0 1 0 10` | `0010` | 15 | 20 | 35 | 6 | 6 | `$6 = 35` | `$6 = 35` | ✅ |
| 7 | 6 | `SUB $7, $3, $1` | `1 0 1 0 10` | `0110` | 50 | 15 | 35 | 7 | 7 | `$7 = 35` | `$7 = 35` | ✅ |
| 8 | 7 | `MUL $8, $2, $3` | `1 0 1 0 10` | `1000` | 20 | 50 | 1000 | 8 | 8 | `$8 = 1000` | `$8 = 1000` | ✅ |
| 9 | 8 | `DIV $9, $3, $2` | `1 0 1 0 10` | `1001` | 50 | 20 | 2 | 9 | 9 | `$9 = 2` | `$9 = 2` | ✅ |
| 10 | 9 | `ADDI $1, $1, 10` | `0 1 1 0 01` | `0010` | 15 | 15 | 25 | 1 | 10 | `$1 = 25` | `$1 = 25` | ✅ |
| 11 | 10 | `SUBI $2, $2, 4` | `0 1 1 0 11` | `0110` | 20 | 20 | 16 | 2 | 11 | `$2 = 16` | `$2 = 16` | ✅ |
| 12 | 11 | `ADD $10, $6, $4` | `1 0 1 0 10` | `0010` | 35 | 5 | 40 | 10 | 12 | `$10 = 40` | `$10 = 40` | ✅ |
| 13 | 12 | `MUL $11, $6, $5` | `1 0 1 0 10` | `1000` | 35 | 2 | 70 | 11 | 13 | `$11 = 70` | `$11 = 70` | ✅ |
| 14 | 13 | `DIV $12, $10, $5` | `1 0 1 0 10` | `1001` | 40 | 2 | 20 | 12 | 14 | `$12 = 20` | `$12 = 20` | ✅ |
| 15 | 14 | `ADDI $4, $4, 20` | `0 1 1 0 01` | `0010` | 5 | 5 | 25 | 4 | 15 | `$4 = 25` | `$4 = 25` | ✅ |
| 16 | 15 | `SUB $13, $4, $3` | `1 0 1 0 10` | `0110` | 25 | 50 | −25 | 13 | 16 | `$13 = −25` | `$13 = −25` | ✅ |
| 17 | 16 | `MOVI $14, 100` | `0 1 1 0 00` | `0000` | 0 | 0 | 100 | 14 | 17 | `$14 = 100` | `$14 = 100` | ✅ |
| 18 | 17 | `ADD $15, $14, $1` | `1 0 1 0 10` | `0010` | 100 | 25 | 125 | 15 | 18 | `$15 = 125` | `$15 = 125` | ✅ |
| 19 | 18 | `SUBI $3, $3, 5` | `0 1 1 0 11` | `0110` | 50 | 50 | 45 | 3 | 19 | `$3 = 45` | `$3 = 45` | ✅ |
| 20 | 19 | `MUL $16, $15, $2` | `1 0 1 0 10` | `1000` | 125 | 16 | 2000 | 16 | 20 | `$16 = 2000` | `$16 = 2000` | ✅ |
| 21 | 20 | `ADDI $17, $1, 1` | `0 1 1 0 01` | `0010` | 25 | 0 | 26 | 17 | 21 | `$17 = 26` | `$17 = 26` | ✅ |
| 22 | 21 | `JUMP 1024` | `0 0 0 1 00` | `0000` | 0 | 0 | 0 | 0 | **1024** | ninguna | ninguna | ✅ |
| — | 1024 | NOP (fuera de la IMEM) | `1 0 1 0 10` | `1111` | 0 | 0 | 0 | 0 | 1025 | `$0` no cambia | `$0 = 0` | ✅ |
| — | 1025 | NOP | `1 0 1 0 10` | `1111` | 0 | 0 | 0 | 0 | 1026 | `$0` no cambia | `$0 = 0` | ✅ |
| — | 1026 | NOP | `1 0 1 0 10` | `1111` | 0 | 0 | 0 | 0 | 1027 | `$0` no cambia | `$0 = 0` | ✅ |
| — | 1027 | NOP | `1 0 1 0 10` | `1111` | 0 | 0 | 0 | 0 | 1028 | `$0` no cambia | `$0 = 0` | ✅ |
| 23 | — | `ADD $18, $17, $2` | no se ejecuta | | | | | | | — | — | ✅ |
| 24 | — | `SUB $19, $18, $5` | no se ejecuta | | | | | | | — | — | ✅ |
| 25 | — | `MOVI $20, 255` | no se ejecuta | | | | | | | — | — | ✅ |
| 26 | — | `MOVI $0, 255` | no se ejecuta | | | | | | | — | — | ✅ |

- **Registros reutilizados:** `ADDI $1, $1, 10` lee el `$1 = 15` de la instrucción 1 y lo deja en 25; desde
  ahí toda lectura de `$1` da 25 (instrucciones 18 y 21). Igual con `$2` (20 → 16), `$3` (50 → 45) y `$4`
  (5 → 25). Por eso `SUB $13, $4, $3` da `25 − 50 = −25` y `MUL $16, $15, $2` da `125 × 16 = 2000`.
- **Divisiones enteras:** `50 / 20 = 2` (se descarta el resto 10).
- En las I, `rd2` es el valor anterior del destino `$rt` (por ejemplo `ADDI $1, $1, 10` lee `rd2 = 15`): el mux
  `ALUSrc` lo descarta y usa el inmediato.

### Valores finales de los registros (266 ns) — sección 8 de la plantilla

| Registro | Esperado (a mano) | Obtenido | | Registro | Esperado (a mano) | Obtenido |
|---|---:|---:|---|---|---:|---:|
| `$0` | 0 | 0 | | `$11` | 70 | 70 |
| `$1` | 25 | 25 | | `$12` | 20 | 20 |
| `$2` | 16 | 16 | | `$13` | −25 | −25 |
| `$3` | 45 | 45 | | `$14` | 100 | 100 |
| `$4` | 25 | 25 | | `$15` | 125 | 125 |
| `$5` | 2 | 2 | | `$16` | 2000 | 2000 |
| `$6` | 35 | 35 | | `$17` | 26 | 26 |
| `$7` | 35 | 35 | | `$18` | 0 | 0 |
| `$8` | 1000 | 1000 | | `$19` | 0 | 0 |
| `$9` | 2 | 2 | | `$20` | 0 | 0 |
| `$10` | 40 | 40 | | `$21`–`$31` | 0 | 0 |

`$18`, `$19` y `$20` quedan en 0 porque sus instrucciones (23–25) están después de `JUMP 1024`. Los valores de
`$1`, `$5`, `$6`, `$9` y `$17` coinciden con los puntos de control de la Entrega Final 2 (pasos 1, 5, 6, 9 y
21: 15, 2, 35, 2 y 26).

**Total: 26 ciclos y 32 registros, 0 errores.** Compila sin advertencias con `iverilog -Wall`.

### Salida de la consola
```
PC=0     Instr=2801000f  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=00 | rd1=0   rd2=0   ALU=15   | $1 <=15    OK  #1  MOVI $1, 15
PC=1     Instr=28020014  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=00 | rd1=0   rd2=0   ALU=20   | $2 <=20    OK  #2  MOVI $2, 20
PC=2     Instr=28030032  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=00 | rd1=0   rd2=0   ALU=50   | $3 <=50    OK  #3  MOVI $3, 50
PC=3     Instr=28040005  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=00 | rd1=0   rd2=0   ALU=5    | $4 <=5     OK  #4  MOVI $4, 5
PC=4     Instr=28050002  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=00 | rd1=0   rd2=0   ALU=2    | $5 <=2     OK  #5  MOVI $5, 2
PC=5     Instr=00223020  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=15  rd2=20  ALU=35   | $6 <=35    OK  #6  ADD $6, $1, $2
PC=6     Instr=00613822  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=50  rd2=15  ALU=35   | $7 <=35    OK  #7  SUB $7, $3, $1
PC=7     Instr=00434018  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=20  rd2=50  ALU=1000 | $8 <=1000  OK  #8  MUL $8, $2, $3
PC=8     Instr=0062481a  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=50  rd2=20  ALU=2    | $9 <=2     OK  #9  DIV $9, $3, $2
PC=9     Instr=2021000a  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=01 | rd1=15  rd2=15  ALU=25   | $1 <=25    OK  #10 ADDI $1, $1, 10
PC=10    Instr=24420004  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=11 | rd1=20  rd2=20  ALU=16   | $2 <=16    OK  #11 SUBI $2, $2, 4
PC=11    Instr=00c45020  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=35  rd2=5   ALU=40   | $10<=40    OK  #12 ADD $10, $6, $4
PC=12    Instr=00c55818  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=35  rd2=2   ALU=70   | $11<=70    OK  #13 MUL $11, $6, $5
PC=13    Instr=0145601a  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=40  rd2=2   ALU=20   | $12<=20    OK  #14 DIV $12, $10, $5
PC=14    Instr=20840014  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=01 | rd1=5   rd2=5   ALU=25   | $4 <=25    OK  #15 ADDI $4, $4, 20
PC=15    Instr=00836822  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=25  rd2=50  ALU=-25  | $13<=-25   OK  #16 SUB $13, $4, $3
PC=16    Instr=280e0064  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=00 | rd1=0   rd2=0   ALU=100  | $14<=100   OK  #17 MOVI $14, 100
PC=17    Instr=01c17820  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=100 rd2=25  ALU=125  | $15<=125   OK  #18 ADD $15, $14, $1
PC=18    Instr=24630005  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=11 | rd1=50  rd2=50  ALU=45   | $3 <=45    OK  #19 SUBI $3, $3, 5
PC=19    Instr=01e28018  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=125 rd2=16  ALU=2000 | $16<=2000  OK  #20 MUL $16, $15, $2
PC=20    Instr=20310001  RegDst=0 ALUSrc=1 RegWrite=1 Jump=0 ALUOp=01 | rd1=25  rd2=0   ALU=26   | $17<=26    OK  #21 ADDI $17, $1, 1
PC=21    Instr=08000400  RegDst=0 ALUSrc=0 RegWrite=0 Jump=1 ALUOp=00 | rd1=0   rd2=0   ALU=0    | $0 <=0     OK  #22 JUMP 1024
PC=1024  Instr=00000000  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=0   rd2=0   ALU=0    | $0 <=0     OK  NOP (fuera de la IMEM)
PC=1025  Instr=00000000  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=0   rd2=0   ALU=0    | $0 <=0     OK  NOP (fuera de la IMEM)
PC=1026  Instr=00000000  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=0   rd2=0   ALU=0    | $0 <=0     OK  NOP (fuera de la IMEM)
PC=1027  Instr=00000000  RegDst=1 ALUSrc=0 RegWrite=1 Jump=0 ALUOp=10 | rd1=0   rd2=0   ALU=0    | $0 <=0     OK  NOP (fuera de la IMEM)
$0  = 0     OK
$1  = 25    OK
$2  = 16    OK
$3  = 45    OK
$4  = 25    OK
$5  = 2     OK
$6  = 35    OK
$7  = 35    OK
$8  = 1000  OK
$9  = 2     OK
$10 = 40    OK
$11 = 70    OK
$12 = 20    OK
$13 = -25   OK
$14 = 100   OK
$15 = 125   OK
$16 = 2000  OK
$17 = 26    OK
$18 = 0     OK
$19 = 0     OK
$20 = 0     OK
$21 = 0     OK
$22 = 0     OK
$23 = 0     OK
$24 = 0     OK
$25 = 0     OK
$26 = 0     OK
$27 = 0     OK
$28 = 0     OK
$29 = 0     OK
$30 = 0     OK
$31 = 0     OK
MIPS_tb.v:190: $finish called at 270000 (1ps)
```

## El testbench detecta los errores de conexión
Se simularon siete copias del diseño, cada una con un solo cambio. Seis terminan en `ERROR`:

| # | Cambio | Qué se ve | Errores |
|:---:|---|---|:---:|
| 1 | Extensión con ceros: `imm_ext = {16'b0, immediate}` | **Nada.** Todos los inmediatos del programa de clase son positivos, así que extender con ceros o con signo da lo mismo. La extensión con signo se verificó con el programa anterior (`movi $2, -3` → `0xFFFFFFFD`) | 0 |
| 2 | Mux `RegDst` invertido: `RegDst ? rt : rd` | Las I escriben en los bits 15:11 del inmediato: `MOVI $1, 15` va a `$0` y se pierde. Las R escriben en `rt` | 38 (21 ciclos + 17 registros) |
| 3 | Mux `ALUSrc` invertido: `ALUSrc ? read_data2 : imm_ext` | `MOVI $1, 15` carga `$rt = 0`; `ADD $6, $1, $2` suma los bits bajos de la instrucción (`0x3020 = 12320`) | 39 (22 ciclos + 17 registros) |
| 4 | Sin mux `Jump`: `next_pc = pc_plus1` | `JUMP 1024` da `next_pc = 22` y se ejecutan las instrucciones 23–26: `$18 = 42`, `$19 = 40`, `$20 = 255`. `MOVI $0, 255` también se ejecuta y `$0` **sigue en 0** | 8 (5 ciclos + 3 registros) |
| 5 | Banco sin reset: `.reset(1'b0)` | Tras el reset solo `$0` vale 0. Las MOVI leen `rd2 = x` (su `$rt` aún no tiene valor) y `$18`–`$31` terminan en `x` | 21 (7 ciclos + 14 registros) |
| 6 | IMEM sin comprobación de rango: `memory[addr[9:0]]` | En PC 1024 se lee la palabra 0 (`MOVI $1, 15`) y el programa vuelve a empezar: `$1 = 15`, `$2 = 20`, `$3 = 50`, `$4 = 5` | 8 (4 ciclos + 4 registros) |
| 7 | ALUControl con los `funct` del enunciado (SUB `100100`, MUL `100001`, DIV `100010`) | `SUB $7, $3, $1` se ejecuta como DIV (`$7 = 3`); MUL y DIV de clase dan `1111` (`$8 = 0`) | 14 (7 ciclos + 7 registros) |

Las mutaciones 2, 3 y 5 son los riesgos de [Arquitectura §11.3](../docs/Arquitectura.md#s11). La 6 y la 7 son
las dos decisiones nuevas de la Entrega Final (D5 y D1).

## Capturas
- `consola.png` ⏳: desde esta carpeta, con **los dos comandos visibles** (`iverilog` y `vvp`), la línea
  de cada instrucción y las 32 líneas de registros finales. Las líneas miden hasta 136 caracteres: ensanchar la
  ventana para que no se partan. Si no cabe, varias capturas consecutivas.
- Foto del CMD ⏳: las 32 líneas `$n = valor` que imprime el testbench al terminar.
- [`gtkwave.png`](gtkwave.png) ✅: `MIPS_tb.gtkw` abre cuatro grupos. **Búsqueda:** `clk`, `reset`,
  `current_pc` y `next_pc` en decimal, `instruction` en hex. **Control:** las cinco señales y `alu_control` en
  binario. **Ejecución:** `read_data1`, `read_data2`, `src2` y `alu_result` en decimal con signo, `zero` y
  `write_reg`. **Banco:** `R1`–`R20` en decimal con signo. Ventana de 1900 px y *Zoom Fit* (0–270 ns). Cada
  registro cambia en el flanco ↑ que termina su instrucción, a la vez que el PC avanza; después de
  `JUMP 1024` el PC salta a 1024 y ya nada cambia en el banco. De 0 a 5 ns las señales están en `x` (en rojo),
  como explica el hallazgo de arriba.

![GTKWave: búsqueda, control, ejecución y registros durante el programa de clase](gtkwave.png)

## Comandos
Ejecutar desde `08_MIPS/`:
```powershell
iverilog -Wall -o MIPS_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v ../04_ControlUnit/ControlUnit.v ../05_ALU/ALU.v ../06_ALUControl/ALUControl.v ../07_RegisterFile/RegisterFile.v MIPS.v MIPS_tb.v
vvp MIPS_tb.vvp
gtkwave MIPS_tb.vcd MIPS_tb.gtkw    # abre ya los cuatro grupos con su formato; luego View → Zoom Fit
```
`-Wall` activa todas las advertencias: la compilación no imprime ninguna.

Para la entrega, con los ocho archivos `.v` en una sola carpeta (como en la plantilla):
```powershell
iverilog -o salida.vvp *.v
vvp salida.vvp
```
