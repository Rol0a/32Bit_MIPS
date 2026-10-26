<a id="procesador-mips-en-verilog"></a>

<p align="center">
  <strong>ARQUITECTURA DE COMPUTADORES · PRÁCTICA 1</strong>
</p>

<h1 align="center">⚙️ Procesador MIPS en Verilog</h1>

<p align="center">
  Del primer pulso de reloj al datapath.<br>
  <em>Diseño modular, simulación y verificación de un procesador MIPS simplificado.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/HDL-Verilog-6366F1?style=for-the-badge&labelColor=18181B" alt="HDL: Verilog">
  <img src="https://img.shields.io/badge/Arquitectura-32_bits-0EA5E9?style=for-the-badge&labelColor=18181B" alt="Arquitectura: 32 bits">
  <img src="https://img.shields.io/badge/Simulador-Icarus_Verilog_14-8B5CF6?style=for-the-badge&labelColor=18181B" alt="Simulador: Icarus Verilog 14">
  <img src="https://img.shields.io/badge/PC-Verificado-10B981?style=for-the-badge&labelColor=18181B" alt="PC: verificado">
</p>

<p align="center">
  <code>PC</code> &nbsp;·&nbsp; <code>IMEM</code> &nbsp;·&nbsp;
  <code>ControlUnit</code> &nbsp;·&nbsp; <code>ALU</code> &nbsp;·&nbsp;
  <code>ALUControl</code> &nbsp;·&nbsp; <code>RegisterFile</code>
</p>

---

Construcción de los módulos **PC, IMEM, Unidad de Control, ALU, ALUControl y Banco de Registros**. Cada módulo se verifica con su propio testbench antes de integrarlo en el datapath de las siguientes prácticas.

> **Estado actual:** `01_PC` implementado y verificado; capturas listas. Los demás archivos `.v` siguen siendo marcadores vacíos.
>
> **Próximo paso:** resolver las inconsistencias de la ISA antes de construir el programa de la IMEM.

**Navegación**  
[Entregas](#entregas-y-alcance) · [Repositorio](#estructura-del-repositorio) · [Simulación](#herramientas-y-comandos) · [ISA](#conjunto-de-instrucciones-isa) · [Hoja de ruta](#hoja-de-ruta) · [Decisiones pendientes](#decisiones-pendientes) · [Notas técnicas](#notas-técnicas)

---

## Entregas y alcance

| Entrega | Alcance | Carpetas | Plantilla |
| :--- | :--- | :--- | :--- |
| **1 · PC e IMEM** | Program Counter, memoria de instrucciones e integración | `01_PC` · `02_IMEM` · `03_PC_IMEM` | [Entrega_PC_IMEM.docx](docs/Entrega_PC_IMEM.docx) |
| **2 · Control y ALU** | Unidad de Control y ALU | `04_ControlUnit` · `05_ALU` | [Entrega_ControlUnit_ALU.docx](docs/Entrega_ControlUnit_ALU.docx) |
| **3 · ALUControl y registros** | ALUControl y Banco de Registros | `06_ALUControl` · `07_RegisterFile` | Pendiente |

### Evidencias por ejercicio

1. **Código Verilog comentado**, pegado como texto.
2. **Testbench comentado**, con `$dumpfile("nombre.vcd")` y `$dumpvars(0, nombre_del_tb)`.
3. **Captura de consola**, con los comandos de compilación y ejecución visibles.
4. **Captura de GTKWave**, con señales legibles y todos los ciclos a la vista mediante *Zoom Fit*.
5. **Tabla de casos de prueba**, con el valor esperado calculado a mano **antes de simular** y el valor obtenido copiado de la consola.

## Estructura del repositorio

| Carpeta | Contenido | Estado |
| :--- | :--- | :--- |
| [`01_PC/`](01_PC/) | Entrega 1 · Ejercicio 1 | ✅ Verificado |
| [`02_IMEM/`](02_IMEM/) | Entrega 1 · Ejercicio 2 | Pendiente |
| [`03_PC_IMEM/`](03_PC_IMEM/) | Entrega 1 · Ejercicio 3 | Pendiente |
| [`04_ControlUnit/`](04_ControlUnit/) | Entrega 2 · Ejercicio 1 | Pendiente |
| [`05_ALU/`](05_ALU/) | Entrega 2 · Ejercicio 2 | Pendiente |
| [`06_ALUControl/`](06_ALUControl/) | Entrega 3 · Ejercicios 1–2 | Pendiente |
| [`07_RegisterFile/`](07_RegisterFile/) | Entrega 3 · Ejercicios 3–4 | Pendiente |

<details>
<summary><strong>Ver árbol completo de archivos</strong></summary>

```text
P1/
├── README.md                       # Planificación general
├── docs/
│   ├── Entrega_PC_IMEM.docx         # Plantilla de la entrega 1
│   ├── Entrega_ControlUnit_ALU.docx # Plantilla de la entrega 2
│   └── Tabla Opcode y Funct.xlsx   # Tabla de opcodes y funct
├── 01_PC/
│   ├── README.md                   # Especificación, decisiones y casos
│   ├── PC.v
│   └── PC_tb.v
├── 02_IMEM/
│   ├── README.md
│   ├── IMEM.v
│   └── IMEM_tb.v
├── 03_PC_IMEM/                     # Reutiliza PC e IMEM
│   ├── README.md
│   └── PC_IMEM_tb.v
├── 04_ControlUnit/
│   ├── README.md
│   ├── ControlUnit.v
│   └── ControlUnit_tb.v
├── 05_ALU/
│   ├── README.md
│   ├── ALU.v
│   └── ALU_tb.v
├── 06_ALUControl/
│   ├── README.md
│   ├── ALUControl.v
│   └── ALUControl_tb.v
└── 07_RegisterFile/
    ├── README.md
    ├── RegisterFile.v
    └── RegisterFile_tb.v
```

</details>

### Convenciones

- **Módulos:** un módulo por archivo, con el mismo nombre: `PC.v` → `module PC`.
- **Testbenches:** archivo `<Modulo>_tb.v`, módulo `<Modulo>_tb` y ondas en `<Modulo>_tb.vcd`.
- **Capturas:** subcarpeta `capturas/` dentro de cada ejercicio, con `consola.png` y `gtkwave.png`.
- **Generados:** los archivos `*.vvp` y `*.vcd` no se versionan; se regeneran al simular.
- **Reutilización:** los módulos compartidos se compilan desde su carpeta original; **no se copian**.

## Herramientas y comandos

Entorno instalado: **Icarus Verilog 14** (`iverilog`, `vvp`) y **GTKWave**, en `C:\iverilog\bin`.

### Simular un módulo

Ejecutar desde `01_PC/`:

```powershell
# Compilar
iverilog -o PC_tb.vvp PC.v PC_tb.v

# Simular: imprime los $display y genera el archivo .vcd
vvp PC_tb.vvp

# Abrir las formas de onda
gtkwave PC_tb.vcd
```

### Simular la integración PC + IMEM

Ejemplo para cuando la IMEM y el testbench estén implementados. Ejecutar desde `03_PC_IMEM/`:

```powershell
iverilog -o PC_IMEM_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v PC_IMEM_tb.v
vvp PC_IMEM_tb.vvp
```

## Conjunto de instrucciones (ISA)

Fuentes: `docs/Tabla Opcode y Funct.xlsx` —con opcodes ampliados a 6 bits— y la tabla del enunciado de ALUControl.

> **ISA pendiente de confirmar.** La tabla siguiente conserva los códigos `funct` de la hoja de cálculo. Las entradas con ⚠ tienen discrepancias o decisiones pendientes; consulta [Decisiones pendientes](#decisiones-pendientes) antes de implementarlas.

| Instrucción | Tipo | Opcode | Funct (`.xlsx`) | Operación | `alu_control` |
| :--- | :---: | :---: | :---: | :--- | :---: |
| **ADD** | R | `000000` | `100000` | `$rd = $rs + $rt` | `0010` |
| **SUB** | R | `000000` | `100010` ⚠ | `$rd = $rs - $rt` | `0110` |
| **MUL** | R | `000000` | `011000` ⚠ | `$rd = $rs * $rt` | `1000` |
| **DIV** | R | `000000` | `011010` ⚠ | `$rd = $rs / $rt` | `1001` |
| **MOV** | R | `000000` | — ⚠ | `$rd = $rs` | `0001` |
| **MOVI** | I | `001010` | — | `$rt = imm` | `0000` |
| **ADDI** | I | `001000` | — | `$rt = $rs + imm` | `0010` ⚠ |
| **SUBI** | I | `001001` | — | `$rt = $rs - imm` | `0110` ⚠ |
| **JUMP** | J | `000010` | — | `PC = address` | — |

### Formatos de instrucción · 32 bits

| Tipo | Campos, del bit más significativo al menos significativo |
| :---: | :--- |
| **R** | `opcode[31:26]` · `rs[25:21]` · `rt[20:16]` · `rd[15:11]` · `shamt[10:6]` · `funct[5:0]` |
| **I** | `opcode[31:26]` · `rs[25:21]` · `rt[20:16]` · `immediate[15:0]` |
| **J** | `opcode[31:26]` · `address[25:0]` |

### Codificación de `alu_control`

La tabla de ALUControl fija esta codificación. La ALU de la entrega 2 la adopta desde el inicio para evitar cambios en la entrega 3.

| `alu_control` | Operación de la ALU | Instrucciones |
| :---: | :--- | :--- |
| `0000` | `result = src2` · pasa el inmediato | MOVI |
| `0001` | `result = src1` · pasa el registro | MOV |
| `0010` | `result = src1 + src2` | ADD, ADDI |
| `0110` | `result = src1 - src2` | SUB, SUBI |
| `1000` | `result = src1 * src2` · truncado a 32 bits | MUL |
| `1001` | `result = src1 / src2` | DIV |
| Otro | Valor seguro, por ejemplo `0` · **por definir** | — |

## Hoja de ruta

Cada fase depende de las decisiones de la anterior.

### Fase 0 · Cerrar decisiones de diseño

- [ ] Resolver las [inconsistencias detectadas](#decisiones-pendientes), idealmente con el profesor.
- [ ] Congelar la [tabla ISA](#conjunto-de-instrucciones-isa) como referencia única para IMEM, ControlUnit, ALUControl y ALU.

### Fase 1 · PC e IMEM

- [x] **`01_PC`** — Reset síncrono a `0` y carga de `next_pc` en `posedge clk`. Testbench con 5 casos mínimos + 1 adicional; resultado reportado: **10/10 OK**. Capturas listas.
- [ ] **`02_IMEM`** — Memoria de **16 × 32 bits**, programa de 10 instrucciones (≥ 1 R, ≥ 1 I y ≥ 1 J) y lectura combinacional. Testbench que recorra direcciones y separe los campos.
- [ ] **`03_PC_IMEM`** — Testbench que instancie PC + IMEM, con `next_pc = current_pc + 1`, e imprima la instrucción y sus campos en cada ciclo.
- [ ] Completar `docs/Entrega_PC_IMEM.docx` con tablas y capturas: **3 de consola + 3 de GTKWave**.

### Fase 2 · Unidad de Control y ALU

- [ ] **`04_ControlUnit`** — Decodificador combinacional de opcode, con valores por defecto antes del `case`.
- [ ] **`05_ALU`** — Suma, resta, multiplicación y división, más bandera `zero`, usando la codificación de `alu_control` acordada.
- [ ] Crear testbenches que **comparen los resultados contra lo esperado**, además de imprimirlos.
- [ ] Completar `docs/Entrega_ControlUnit_ALU.docx` con capturas y tablas.

### Fase 3 · ALUControl y Banco de Registros

- [ ] **`06_ALUControl`** — `always @(*)` y `case` sobre `ALUOp` y `funct`.
- [ ] **`07_RegisterFile`** — **32 × 32 bits**, lectura asíncrona, escritura síncrona y `$0` siempre en `0`.
- [ ] Preparar testbenches, capturas y tablas; plantilla pendiente.

### Fase 4 · Siguiente práctica

**Fuera del alcance actual:** integrar el datapath monociclo —PC, IMEM, ControlUnit/RegisterFile, ALUControl/ALU y write-back— e incorporar el salto (`Jump`).

### Flujo de trabajo por módulo

1. **Revisar** el `README.md` de la carpeta: especificación y casos de prueba.
2. **Calcular a mano** la columna **Esperado** de la tabla de casos.
3. **Implementar** el módulo y su testbench, ambos comentados.
4. **Compilar y simular**, comparando contra los valores esperados.
5. **Inspeccionar en GTKWave**, ajustar formatos (decimal, binario o hexadecimal), aplicar *Zoom Fit* y tomar capturas.
6. **Documentar** el código, las capturas y las tablas en la plantilla `.docx`.

## Decisiones pendientes

### 1. Códigos `funct` contradictorios

La hoja de cálculo y el enunciado de ALUControl no coinciden:

| Instrucción | Hoja `.xlsx` | Enunciado de ALUControl |
| :--- | :---: | :---: |
| ADD | `100000` | `100000` |
| SUB | `100010` | `100100` |
| MUL | `011000` | `100001` |
| DIV | `011010` | `100010` |
| MOV | — | `100011` |

> **Conflicto:** `100010` representa **SUB** en una tabla y **DIV** en la otra.

**Propuesta pendiente de confirmar:** usar los códigos del enunciado de ALUControl, ya que es la tabla contra la que se califica ese módulo e incluye MOV. El programa de la IMEM debe utilizar los mismos códigos. Confirmar con el profesor **antes de armar el programa**.

### 2. `ALUOp` de ADDI y SUBI

El enunciado solo define `ALUOp = 00` para MOVI (`alu_control = 0000`) y `ALUOp = 10` para instrucciones de tipo R. Si ADDI y SUBI usaran `00`, la ALU ejecutaría MOVI.

**Propuesta:** reservar `01` para la suma (ADDI) y `11` para la resta (SUBI). Esta decisión afecta a ControlUnit (entrega 2) y ALUControl (entrega 3).

### 3. Valores no definidos de la Unidad de Control

El enunciado deja algunas señales como «—». Se propone la siguiente tabla, **todavía pendiente de aprobación**:

| Tipo | Opcode | RegDst | ALUSrc | RegWrite | Jump | ALUOp |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| R | `000000` | 1 | 0 | 1 | 0 | `10` |
| MOVI | `001010` | 0 | 1 | 1 | 0 | `00` |
| ADDI | `001000` | 0 | 1 | 1 | 0 | `01` |
| SUBI | `001001` | 0 | 1 | 1 | 0 | `11` |
| JUMP | `000010` | 0 | 0 | **0** | 1 | `00` |
| No definido | Otro | 0 | 0 | **0** | **0** | `00` |

**Condiciones clave:** `RegWrite = 0` para JUMP y opcodes no definidos; `Jump = 0` salvo en JUMP.

### 4. Comportamiento de la ALU

Decidir y documentar:

- **Signo de la aritmética:** con o sin signo; se recomienda `$signed` en la división.
- **División entre cero:** se recomienda devolver `0` para evitar `x`.
- **Control no definido:** establecer el resultado para valores de `alu_control` no contemplados.

### 5. Indexación de la IMEM

El enunciado usa `addr[4:0]`, pero el arreglo tiene **16 palabras**: las direcciones 16–31 leen `x`. Con `addr[3:0]`, la dirección 16 vuelve a la 0.

**Propuesta:** respetar `addr[4:0]` como pide el enunciado y documentar el caso 8 de la tabla de pruebas: dirección `16` → `x`.

### 6. Incremento del PC

La plantilla fija `next_pc = current_pc + 1`: el direccionamiento es **por palabra**, por lo que el incremento es `+1`, no `+4`.

### 7. Plantilla de la entrega 3

Todavía no hay plantilla `.docx`. Se seguirá el mismo formato de las entregas anteriores.

## Notas técnicas

| Tema | Recordatorio |
| :--- | :--- |
| **Cuándo imprimir** | El PC cambia con `<=` en `posedge`. Imprimir en `negedge` o `#1` después del flanco para observar el valor nuevo. |
| **Observar PC = 0** | El PC vale `x` hasta el primer `posedge` con `reset = 1`. Liberar el reset después de ese flanco. |
| **Lógica combinacional** | En `always @(*)`, asignar **todas** las salidas antes del `case` para evitar latches y valores `x`. |
| **Valores con signo** | Los vectores sin declaración `signed` son sin signo. Un resultado de 32 bits de `5 - 10` se imprime como `4294967291` con `%d`; usar `$signed()` para interpretarlo con signo. |
| **Multiplicación** | El producto se trunca a 32 bits: `65536 × 65536 = 0`, con `zero = 1`. |
| **Banco de Registros** | El testbench puede acceder al arreglo interno mediante una referencia jerárquica: `uut.registers[1]`. |

---

[Volver al inicio](#procesador-mips-en-verilog)