# Procesador MIPS en Verilog — Práctica 1

Arquitectura de Computadores. Construcción, módulo por módulo, de las piezas de un procesador MIPS
simplificado: **PC, IMEM, Unidad de Control, ALU, ALUControl y Banco de Registros**. Cada módulo se
verifica por separado con su propio testbench antes de integrarlo en el datapath (siguientes prácticas).

> **Estado actual:** `01_PC` implementado y verificado. El resto de los archivos `.v` siguen siendo
> marcadores vacíos.

---

## 1. Entregas y alcance

| Entrega | Módulos | Carpetas | Plantilla |
|---|---|---|---|
| **1 — PC e IMEM** | Program Counter, Memoria de Instrucciones, integración PC + IMEM | `01_PC`, `02_IMEM`, `03_PC_IMEM` | `docs/Entrega_PC_IMEM.docx` |
| **2 — Unidad de Control y ALU** | ControlUnit, ALU | `04_ControlUnit`, `05_ALU` | `docs/Entrega_ControlUnit_ALU.docx` |
| **3 — ALUControl y Banco de Registros** | ALUControl, RegisterFile | `06_ALUControl`, `07_RegisterFile` | *(aún no hay plantilla)* |

Cada ejercicio de las plantillas pide lo mismo:

1. Código Verilog **comentado** (pegado como texto).
2. Testbench **comentado** con `$dumpfile("nombre.vcd")` y `$dumpvars(0, nombre_del_tb)`.
3. Captura de la **consola** (con los comandos de compilación y ejecución visibles).
4. Captura de **GTKWave** (señales legibles, todos los ciclos a la vista con *Zoom Fit*).
5. **Tabla de casos de prueba**: valor esperado calculado *a mano antes de simular* y valor obtenido copiado de la consola.

---

## 2. Estructura del repositorio

```
P1/
├── README.md                  ← este archivo (planificación general)
├── docs/
│   ├── Entrega_PC_IMEM.docx           plantilla de la entrega 1
│   ├── Entrega_ControlUnit_ALU.docx   plantilla de la entrega 2
│   └── Tabla Opcode y Funct.xlsx      tabla de opcodes/funct del procesador
│
├── 01_PC/                     Entrega 1 · Ejercicio 1
│   ├── README.md              especificación, decisiones y casos de prueba
│   ├── PC.v                   módulo
│   └── PC_tb.v                testbench
├── 02_IMEM/                   Entrega 1 · Ejercicio 2
│   ├── README.md
│   ├── IMEM.v
│   └── IMEM_tb.v
├── 03_PC_IMEM/                Entrega 1 · Ejercicio 3 (usa ../01_PC y ../02_IMEM)
│   ├── README.md
│   └── PC_IMEM_tb.v
├── 04_ControlUnit/            Entrega 2 · Ejercicio 1
│   ├── README.md
│   ├── ControlUnit.v
│   └── ControlUnit_tb.v
├── 05_ALU/                    Entrega 2 · Ejercicio 2
│   ├── README.md
│   ├── ALU.v
│   └── ALU_tb.v
├── 06_ALUControl/             Entrega 3 · Ejercicios 1–2
│   ├── README.md
│   ├── ALUControl.v
│   └── ALUControl_tb.v
└── 07_RegisterFile/           Entrega 3 · Ejercicios 3–4
    ├── README.md
    ├── RegisterFile.v
    └── RegisterFile_tb.v
```

**Convenciones**

- Un módulo por archivo; el archivo se llama igual que el módulo (`PC.v` → `module PC`).
- Testbench: `<Modulo>_tb.v`, módulo `<Modulo>_tb`, archivo de ondas `<Modulo>_tb.vcd`.
- Las capturas de cada ejercicio se guardan en una subcarpeta `capturas/` dentro de su carpeta
  (`consola.png`, `gtkwave.png`).
- Los archivos generados (`*.vvp`, `*.vcd`) no se versionan; se regeneran al simular.
- Los módulos reutilizados (p. ej. `PC.v` en la integración) **no se copian**: se compilan desde su carpeta original.

---

## 3. Herramientas y comandos

Instalado: **Icarus Verilog 14** (`iverilog`, `vvp`) y **GTKWave** en `C:\iverilog\bin`.

Desde la carpeta del módulo:

```powershell
iverilog -o PC_tb.vvp PC.v PC_tb.v      # compilar
vvp PC_tb.vvp                           # simular (imprime $display y genera el .vcd)
gtkwave PC_tb.vcd                       # ver ondas
```

Integración (ejemplo, desde `03_PC_IMEM/`):

```powershell
iverilog -o PC_IMEM_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v PC_IMEM_tb.v
vvp PC_IMEM_tb.vvp
```

---

## 4. Conjunto de instrucciones (ISA)

Fuente: `docs/Tabla Opcode y Funct.xlsx` (opcodes ampliados a 6 bits) + tabla del enunciado de ALUControl.

| Instrucción | Tipo | Opcode | Funct (xlsx) | Operación | `alu_control` |
|---|---|---|---|---|---|
| ADD  | R | `000000` | `100000` | `$rd = $rs + $rt` | `0010` |
| SUB  | R | `000000` | `100010` ⚠ | `$rd = $rs - $rt` | `0110` |
| MUL  | R | `000000` | `011000` ⚠ | `$rd = $rs * $rt` | `1000` |
| DIV  | R | `000000` | `011010` ⚠ | `$rd = $rs / $rt` | `1001` |
| MOV  | R | `000000` | — ⚠ | `$rd = $rs` | `0001` |
| MOVI | I | `001010` | — | `$rt = imm` | `0000` |
| ADDI | I | `001000` | — | `$rt = $rs + imm` | `0010` ⚠ |
| SUBI | I | `001001` | — | `$rt = $rs - imm` | `0110` ⚠ |
| JUMP | J | `000010` | — | `PC = address` | — |

⚠ = ver **Decisiones pendientes** (sección 6).

**Formatos de instrucción (32 bits)**

```
R:  opcode[31:26] | rs[25:21] | rt[20:16] | rd[15:11] | shamt[10:6] | funct[5:0]
I:  opcode[31:26] | rs[25:21] | rt[20:16] | immediate[15:0]
J:  opcode[31:26] | address[25:0]
```

**Codificación de `alu_control`** (la fija la tabla de ALUControl; la ALU de la entrega 2 la adopta
desde ya para no tener que cambiarla en la entrega 3):

| `alu_control` | Operación ALU | Usada por |
|---|---|---|
| `0000` | `result = src2` (pasa el inmediato) | MOVI |
| `0001` | `result = src1` (pasa el registro) | MOV |
| `0010` | `result = src1 + src2` | ADD, ADDI |
| `0110` | `result = src1 - src2` | SUB, SUBI |
| `1000` | `result = src1 * src2` (truncado a 32 bits) | MUL |
| `1001` | `result = src1 / src2` | DIV |
| otro | valor seguro (p. ej. `0`) — por definir | — |

---

## 5. Hoja de ruta

Orden recomendado: cada fase depende de las decisiones de la anterior.

### Fase 0 — Cerrar decisiones de diseño
- [ ] Resolver las inconsistencias de la sección 6 (idealmente confirmarlas con el profesor).
- [ ] Congelar la tabla ISA de la sección 4: es la referencia única para IMEM, ControlUnit, ALUControl y ALU.

### Fase 1 — Entrega 1: PC e IMEM
- [x] `01_PC` — PC con reset síncrono a 0 y carga de `next_pc` en `posedge clk`. Testbench con 5 casos mínimos + 1 adicional (10/10 OK). Capturas listas.
- [ ] `02_IMEM` — memoria de 16 × 32 bits, programa de 10 instrucciones (≥ 1 R, ≥ 1 I, ≥ 1 J), lectura combinacional.
      Testbench que recorra direcciones y separe los campos.
- [ ] `03_PC_IMEM` — testbench que instancia PC + IMEM, `next_pc = current_pc + 1`, imprime instrucción y campos por ciclo.
- [ ] Capturas (3 consola + 3 GTKWave) y tablas de casos → llenar `docs/Entrega_PC_IMEM.docx`.

### Fase 2 — Entrega 2: Unidad de Control y ALU
- [ ] `04_ControlUnit` — decodificador combinacional de opcode, con valores por defecto antes del `case`.
- [ ] `05_ALU` — suma, resta, multiplicación, división + bandera `zero`, usando la codificación de la sección 4.
- [ ] Testbenches que **verifiquen** (comparar contra el esperado, no solo imprimir).
- [ ] Capturas y tablas → llenar `docs/Entrega_ControlUnit_ALU.docx`.

### Fase 3 — Entrega 3: ALUControl y Banco de Registros
- [ ] `06_ALUControl` — `always @(*)` + `case` sobre `ALUOp` y `funct`.
- [ ] `07_RegisterFile` — 32 × 32 bits, lectura asíncrona, escritura síncrona, `$0` siempre 0.
- [ ] Testbenches, capturas y tablas (plantilla pendiente).

### Fase 4 — Siguiente práctica (fuera de alcance)
- Datapath monociclo: PC → IMEM → ControlUnit/RegisterFile → ALUControl/ALU → write-back, y el salto (`Jump`).

### Flujo de trabajo por módulo
1. Leer el `README.md` de la carpeta (especificación + casos).
2. Llenar la columna **Esperado** de la tabla de casos **a mano**.
3. Implementar el módulo y su testbench (comentados).
4. Compilar y simular; comparar contra lo esperado.
5. Abrir GTKWave, ajustar formatos (decimal / binario / hex) y *Zoom Fit*; tomar capturas.
6. Pasar código, capturas y tablas a la plantilla `.docx`.

---

## 6. Decisiones pendientes e inconsistencias detectadas

1. **Códigos `funct` contradictorios.** La tabla `.xlsx` y la tabla del enunciado de ALUControl no coinciden:

   | Instr. | `.xlsx` | Enunciado ALUControl |
   |---|---|---|
   | ADD  | `100000` | `100000` |
   | SUB  | `100010` | `100100` |
   | MUL  | `011000` | `100001` |
   | DIV  | `011010` | `100010` |
   | MOV  | — | `100011` |

   `100010` es SUB en una y DIV en la otra. **Propuesta:** usar los códigos del enunciado de ALUControl
   (es la tabla contra la que se califica ese módulo e incluye MOV) y que el programa de la IMEM use esos
   mismos códigos. Confirmar con el profesor **antes** de armar el programa de la IMEM.

2. **ALUOp de ADDI y SUBI.** El enunciado solo define `ALUOp = 00` (MOVI → `0000`) y `10` (tipo R).
   Si ADDI/SUBI usaran `00`, la ALU haría MOVI. **Propuesta:** `ALUOp = 01` → suma (ADDI) y
   `ALUOp = 11` → resta (SUBI). Afecta a ControlUnit (entrega 2) y ALUControl (entrega 3).

3. **Valores «—» de la Unidad de Control** (el enunciado no los fija). **Propuesta:**

   | Tipo | Opcode | RegDst | ALUSrc | RegWrite | Jump | ALUOp |
   |---|---|---|---|---|---|---|
   | R | `000000` | 1 | 0 | 1 | 0 | `10` |
   | MOVI | `001010` | 0 | 1 | 1 | 0 | `00` |
   | ADDI | `001000` | 0 | 1 | 1 | 0 | `01` |
   | SUBI | `001001` | 0 | 1 | 1 | 0 | `11` |
   | JUMP | `000010` | 0 | 0 | **0** | 1 | `00` |
   | No definido | otro | 0 | 0 | **0** | **0** | `00` |

   Lo importante: en J y en opcodes no definidos `RegWrite = 0` (no escribir registros) y `Jump = 0` salvo en J.

4. **ALU:** decidir (y documentar) aritmética con o sin signo (recomendado: `$signed` en la división),
   qué devuelve la división entre cero (recomendado: `0`, evitando `x`) y qué hace un `alu_control` no definido.

5. **Indexación de la IMEM:** el enunciado usa `addr[4:0]`, pero el arreglo tiene 16 palabras: las direcciones
   16–31 leen `x`. Con `addr[3:0]` la dirección 16 vuelve a la 0. **Propuesta:** respetar `addr[4:0]` como pide
   el enunciado y documentar el caso 8 de la tabla (dirección 16 → `x`).

6. **Incremento del PC:** la plantilla fija `next_pc = current_pc + 1` (direccionamiento por palabra), no `+4`.

7. **Entrega 3:** todavía no hay plantilla `.docx`; se seguirá el mismo formato que las anteriores.

---

## 7. Detalles técnicos a recordar

- **Cuándo imprimir:** el PC cambia con `<=` en `posedge`; imprimir en `negedge` (o `#1` después) para ver el valor nuevo.
- **Ver PC = 0:** el PC vale `x` hasta el primer `posedge` con `reset = 1`; soltar reset después de ese flanco.
- **Combinacional:** en `always @(*)` asignar **todas** las salidas antes del `case` para evitar latches/`x`.
- **Con signo:** los vectores son sin signo; `5 - 10` se imprime como `4294967291` con `%d`; usar `$signed()`.
- **Multiplicación:** el producto se trunca a 32 bits (`65536 × 65536 = 0`, `zero = 1`).
- **Banco de registros:** desde el testbench se accede al arreglo interno con referencia jerárquica (`uut.registers[1]`).
