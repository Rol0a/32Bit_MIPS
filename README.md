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
  <img src="https://img.shields.io/badge/Testbenches-7_de_7_OK-10B981?style=for-the-badge&labelColor=18181B" alt="Testbenches: 7 de 7 OK">
</p>

<p align="center">
  <code>PC</code> &nbsp;·&nbsp; <code>IMEM</code> &nbsp;·&nbsp;
  <code>ControlUnit</code> &nbsp;·&nbsp; <code>ALU</code> &nbsp;·&nbsp;
  <code>ALUControl</code> &nbsp;·&nbsp; <code>RegisterFile</code>
</p>

---

Construcción de los módulos **PC, IMEM, Unidad de Control, ALU, ALUControl y Banco de Registros**. Cada módulo se verifica con su propio testbench antes de integrarlo en el datapath de las siguientes prácticas.

> **Estado actual:** los seis módulos y la integración PC + IMEM están implementados y verificados: 7 testbenches, 0 errores. Una prueba provisional que conecta los seis módulos ejecuta el programa de la IMEM y deja en el banco los valores calculados a mano ([Arquitectura §7](docs/Arquitectura.md#s7)).
>
> **Próximo paso:** completar las capturas de consola pendientes y las plantillas `.docx`, y empezar la integración del datapath ([Fase 4](#fase-4--integración-del-datapath-siguiente)).

**Navegación**  
[Entregas](#entregas-y-alcance) · [Repositorio](#estructura-del-repositorio) · [Simulación](#herramientas-y-comandos) · [ISA](#conjunto-de-instrucciones-isa) · [Hoja de ruta](#hoja-de-ruta) · [Decisiones](#decisiones-de-diseño) · [Notas técnicas](#notas-técnicas)

---

## Entregas y alcance

| Entrega | Alcance | Carpetas | Plantilla |
| :--- | :--- | :--- | :--- |
| **1 · PC e IMEM** | Program Counter, memoria de instrucciones e integración | `01_PC` · `02_IMEM` · `03_PC_IMEM` | [Entrega_PC_IMEM.docx](docs/Entrega_PC_IMEM.docx) |
| **2 · Control y ALU** | Unidad de Control y ALU | `04_ControlUnit` · `05_ALU` | [Entrega_ControlUnit_ALU.docx](docs/Entrega_ControlUnit_ALU.docx) |
| **3 · ALUControl y registros** | ALUControl y Banco de Registros | `06_ALUControl` · `07_RegisterFile` | [Entrega_ALUControl_RegisterFile.docx](docs/Entrega_ALUControl_RegisterFile.docx) |

### Evidencias por ejercicio

1. **Código Verilog comentado**, pegado como texto.
2. **Testbench comentado**, con `$dumpfile("nombre.vcd")` y `$dumpvars(0, nombre_del_tb)`.
3. **Captura de consola**, con los comandos de compilación y ejecución visibles.
4. **Captura de GTKWave**, con señales legibles y todos los ciclos a la vista mediante *Zoom Fit*.
5. **Tabla de casos de prueba**, con el valor esperado calculado a mano **antes de simular** y el valor obtenido copiado de la consola.

## Estructura del repositorio

| Carpeta | Contenido | Estado |
| :--- | :--- | :--- |
| [`01_PC/`](01_PC/) | Entrega 1 · Ejercicio 1 | ✅ Verificado · capturas listas |
| [`02_IMEM/`](02_IMEM/) | Entrega 1 · Ejercicio 2 | ✅ Verificado · repetir `consola.png` (falta `iverilog`) |
| [`03_PC_IMEM/`](03_PC_IMEM/) | Entrega 1 · Ejercicio 3 | ✅ Verificado · capturas listas |
| [`04_ControlUnit/`](04_ControlUnit/) | Entrega 2 · Ejercicio 1 | ✅ Verificado · capturas listas |
| [`05_ALU/`](05_ALU/) | Entrega 2 · Ejercicio 2 | ✅ Verificado · capturas listas |
| [`06_ALUControl/`](06_ALUControl/) | Entrega 3 · Ejercicios 1–2 | ✅ Verificado · repetir `consola.png` |
| [`07_RegisterFile/`](07_RegisterFile/) | Entrega 3 · Ejercicios 3–4 | ✅ Verificado · falta `consola.png` |

<details>
<summary><strong>Ver árbol completo de archivos</strong></summary>

```text
P1/
├── README.md                       # Planificación general
├── docs/
│   ├── Arquitectura.md                       # Documento técnico de referencia
│   ├── Entrega_PC_IMEM.docx                  # Plantilla de la entrega 1
│   ├── Entrega_ControlUnit_ALU.docx          # Plantilla de la entrega 2
│   ├── Entrega_ALUControl_RegisterFile.docx  # Plantilla de la entrega 3
│   └── Tabla Opcode y Funct.xlsx             # Opcodes (sus funct no se usan: D1)
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
- **Capturas:** `consola.png` y `gtkwave.png` en la raíz de la carpeta de cada ejercicio, junto a la vista guardada `<Modulo>_tb.gtkw`.
- **Generados:** los archivos `*.vvp` y `*.vcd` se regeneran al simular. Hoy están en git (no hay `.gitignore`), pero no se editan a mano.
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

Los módulos compartidos se compilan desde su carpeta original. Ejecutar desde `03_PC_IMEM/`:

```powershell
iverilog -o PC_IMEM_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v PC_IMEM_tb.v
vvp PC_IMEM_tb.vvp
```

## Conjunto de instrucciones (ISA)

Opcodes: `docs/Tabla Opcode y Funct.xlsx`, ampliados a 6 bits. Códigos `funct`: la tabla del enunciado de
ALUControl (decisión D1). **Los `funct` de la `.xlsx` no se usan**: se contradecían con el enunciado
(`100010` era SUB en una tabla y DIV en la otra).

| Instrucción | Tipo | Opcode | Funct | `ALUOp` | `alu_control` | Operación |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **ADD** | R | `000000` | `100000` | `10` | `0010` | `$rd = $rs + $rt` |
| **SUB** | R | `000000` | `100100` | `10` | `0110` | `$rd = $rs - $rt` |
| **MUL** | R | `000000` | `100001` | `10` | `1000` | `$rd = $rs * $rt` (32 bits bajos) |
| **DIV** | R | `000000` | `100010` | `10` | `1001` | `$rd = $rs / $rt` (con signo; entre 0 da 0) |
| **MOV** | R | `000000` | `100011` | `10` | `0001` | `$rd = $rs` |
| **MOVI** | I | `001010` | — | `00` | `0000` | `$rt = imm` |
| **ADDI** | I | `001000` | — | `01` | `0010` | `$rt = $rs + imm` |
| **SUBI** | I | `001001` | — | `11` | `0110` | `$rt = $rs - imm` |
| **JUMP** | J | `000010` | — | `00` | — | `PC = address` |

El inmediato de 16 bits se extiende **con signo** a 32 bits (D7): `movi $2, -3` carga `0xFFFFFFFD`.

### Formatos de instrucción · 32 bits

| Tipo | Campos, del bit más significativo al menos significativo |
| :---: | :--- |
| **R** | `opcode[31:26]` · `rs[25:21]` · `rt[20:16]` · `rd[15:11]` · `shamt[10:6]` · `funct[5:0]` |
| **I** | `opcode[31:26]` · `rs[25:21]` · `rt[20:16]` · `immediate[15:0]` |
| **J** | `opcode[31:26]` · `address[25:0]` |

### Codificación de `alu_control`

La tabla de ALUControl fija esta codificación y la ALU la usa tal cual.

| `alu_control` | Operación de la ALU | Instrucciones |
| :---: | :--- | :--- |
| `0000` | `result = src2` · pasa el inmediato | MOVI |
| `0001` | `result = src1` · pasa el registro | MOV |
| `0010` | `result = src1 + src2` | ADD, ADDI |
| `0110` | `result = src1 - src2` | SUB, SUBI |
| `1000` | `result = src1 * src2` · truncado a 32 bits | MUL |
| `1001` | `result = src1 / src2` · con signo; entre cero da `0` | DIV |
| `1111` y cualquier otro | `result = 0` | Tipo R con `funct` no definido |

## Hoja de ruta

### Fases 0 a 3 · Módulos

- [x] **Fase 0** — Decisiones de diseño cerradas (ver [Decisiones de diseño](#decisiones-de-diseño)) y tabla ISA congelada.
- [x] **`01_PC`** — Reset síncrono a `0` y carga de `next_pc` en `posedge clk`. 10/10 ciclos OK.
- [x] **`02_IMEM`** — 16 × 32 bits, programa de 10 instrucciones (5 R, 4 I, 1 J), lectura combinacional. 18/18 lecturas OK.
- [x] **`03_PC_IMEM`** — PC + IMEM con `next_pc = current_pc + 1`; instrucción y campos en cada ciclo. 10/10 ciclos OK.
- [x] **`04_ControlUnit`** — Decodificador de opcode con valores por defecto antes del `case`. 12/12 pruebas OK.
- [x] **`05_ALU`** — Con signo, `/0 → 0`, control no definido → `0`, bandera `zero`. 22/22 pruebas OK.
- [x] **`06_ALUControl`** — `always @(*)` con valor por defecto y `case` sobre `ALUOp` y `funct`. 16/16 pruebas OK.
- [x] **`07_RegisterFile`** — 32 × 32 bits, lectura asíncrona, escritura síncrona, `$0` siempre en `0`. 19/19 pruebas OK.

### Pendiente para entregar

- [ ] **Capturas de consola** (deben verse `iverilog` y `vvp`): repetir `02_IMEM` y `06_ALUControl` (solo se ve
  `vvp`; la de `06` además es de la versión anterior del testbench) y tomar la de `07_RegisterFile`. La de
  `04_ControlUnit` empieza con un intento fallido (`vvp ControlUnit.vvp`); conviene repetirla o recortarla.
- [ ] Llenar las tres plantillas `.docx` con el código, las capturas y las tablas de casos de cada README.
  En la entrega 3, explicar las filas 7, 10 y 11 de la tabla de ALUControl (ver
  [Diferencias con las plantillas](#diferencias-con-las-plantillas)).

### Fase 4 · Integración del datapath (siguiente)

Ya comprobado: los seis módulos compilan juntos sin advertencias de `iverilog -Wall`. Una prueba provisional,
que no está en el repositorio, los conecta con las piezas de [Arquitectura §5.8](docs/Arquitectura.md#s5-8),
ejecuta el programa de la IMEM y deja en el banco exactamente el estado de [Arquitectura §7](docs/Arquitectura.md#s7).

- [ ] Módulo superior (carpeta y nombre por decidir): instancias de los seis módulos con el mismo `clk` y
  `reset`, más extensión de signo, mux `RegDst`, mux `ALUSrc`, `PC + 1`, mux `Jump` y write-back (`result`).
- [ ] Testbench del datapath: una línea por ciclo y comprobación del estado final del banco con
  `uut.<banco>.registers[i]`.

### Flujo de trabajo por módulo

1. **Revisar** el `README.md` de la carpeta: especificación y casos de prueba.
2. **Calcular a mano** la columna **Esperado** de la tabla de casos.
3. **Implementar** el módulo y su testbench, ambos comentados.
4. **Compilar y simular**, comparando contra los valores esperados.
5. **Inspeccionar en GTKWave**, ajustar formatos (decimal, binario o hexadecimal), aplicar *Zoom Fit* y tomar capturas.
6. **Documentar** el código, las capturas y las tablas en la plantilla `.docx`.

## Decisiones de diseño

Todas están cerradas e implementadas. La lista completa, con alternativas y justificación, está en
[Arquitectura §10](docs/Arquitectura.md#s10).

| # | Decisión | Afecta a |
| :---: | :--- | :--- |
| D1 | `funct` de la tabla del enunciado de ALUControl, no los de la `.xlsx` | IMEM, ALUControl |
| D2 | `ALUOp`: `00` MOVI, `01` ADDI, `10` tipo R, `11` SUBI | ControlUnit, ALUControl |
| D3 | Tabla de control sin `x`: JUMP y opcodes no definidos con `RegWrite = 0` | ControlUnit |
| D4 | ALU con signo; división entre cero → `0`; control no definido → `0` | ALU |
| D5 | IMEM indexada con `addr[4:0]`: palabras 10–15 y dirección 16 leen `x` | IMEM |
| D6 | Direccionamiento por palabra: `next_pc = current_pc + 1` | PC, siguiente PC |
| D7 | Inmediato con extensión de signo | Datapath |
| D8 | Salto: `PC = {6'b0, address}` | Datapath |
| D9 | `alu_control = 1111` significa «no definido» | ALUControl, ALU |
| D11 | Reset síncrono en el PC y en el banco de registros | PC, RegisterFile |
| D12 | `$0` protegido en tres niveles (lectura, escritura y valor interno) | RegisterFile |

### Diferencias con las plantillas

| Plantilla | Qué supone | Qué hace el diseño | Dónde se explica |
| :--- | :--- | :--- | :--- |
| Entrega 2 · Unidad de Control | Deja celdas en «—» | Valores concretos (D3) | [`04_ControlUnit`](04_ControlUnit/README.md) |
| Entrega 3 · ALUControl, caso 7 | ADDI «llega con `ALUOp = 00`» | ADDI llega con `01`; con `00` saldría MOVI (prueba 7) | [`06_ALUControl`](06_ALUControl/README.md) |
| Entrega 3 · ALUControl, casos 10–11 | `ALUOp` `01` y `11` «no definidos» | `01` = ADDI (suma) y `11` = SUBI (resta), D2 | [`06_ALUControl`](06_ALUControl/README.md) |

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