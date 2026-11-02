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
  <img src="https://img.shields.io/badge/Testbenches-8_de_8_OK-10B981?style=for-the-badge&labelColor=18181B" alt="Testbenches: 8 de 8 OK">
</p>

<p align="center">
  <code>PC</code> &nbsp;·&nbsp; <code>IMEM</code> &nbsp;·&nbsp;
  <code>ControlUnit</code> &nbsp;·&nbsp; <code>ALU</code> &nbsp;·&nbsp;
  <code>ALUControl</code> &nbsp;·&nbsp; <code>RegisterFile</code> &nbsp;·&nbsp; <code>MIPS</code>
</p>

---

Construcción de los módulos **PC, IMEM, Unidad de Control, ALU, ALUControl y Banco de Registros**. Cada módulo se verifica con su propio testbench y después todos se integran en el datapath completo (`08_MIPS`).

> **Estado actual:** los seis módulos, la integración PC + IMEM y el procesador completo están implementados y verificados: 8 testbenches, 0 errores. `08_MIPS` ejecuta las **26 instrucciones binarias de clase** (Entrega Final 1) ciclo a ciclo y deja en el banco los valores calculados a mano ([Arquitectura §7](docs/Arquitectura.md#s7)).
>
> **Próximo paso:** tomar las capturas de consola y la foto del CMD, y llenar la plantilla de la Entrega Final 1 ([ver lista](#entrega-final-1--procesador-completo)).

**Navegación**  
[Entregas](#entregas-y-alcance) · [Repositorio](#estructura-del-repositorio) · [Simulación](#herramientas-y-comandos) · [ISA](#conjunto-de-instrucciones-isa) · [Hoja de ruta](#hoja-de-ruta) · [Decisiones](#decisiones-de-diseño) · [Notas técnicas](#notas-técnicas)

---

## Entregas y alcance

| Entrega | Alcance | Carpetas | Plantilla |
| :--- | :--- | :--- | :--- |
| **1 · PC e IMEM** | Program Counter, memoria de instrucciones e integración | `01_PC` · `02_IMEM` · `03_PC_IMEM` | [Entrega_PC_IMEM.docx](docs/Entrega_PC_IMEM.docx) |
| **2 · Control y ALU** | Unidad de Control y ALU | `04_ControlUnit` · `05_ALU` | [Entrega_ControlUnit_ALU.docx](docs/Entrega_ControlUnit_ALU.docx) |
| **3 · ALUControl y registros** | ALUControl y Banco de Registros | `06_ALUControl` · `07_RegisterFile` | [Entrega_ALUControl_RegisterFile.docx](docs/Entrega_ALUControl_RegisterFile.docx) |
| **Final 1 · Procesador** | Procesador completo ejecutando las 26 instrucciones de clase | `08_MIPS` (con los módulos 01–07) | [Entrega_Final_Procesador_MIPS.docx](docs/Entrega_Final_Procesador_MIPS.docx) |
| **Final 2 · NanoBoard** | El mismo procesador en la FPGA, con dos Memory Instrument | pendiente | [Entrega_Final_2_Fisico_NanoBoard3000.docx](docs/Entrega_Final_2_Fisico_NanoBoard3000.docx) |

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
| [`02_IMEM/`](02_IMEM/) | Entrega 1 · Ejercicio 2 · programa de clase | ✅ Verificado · repetir `consola.png` (programa nuevo) |
| [`03_PC_IMEM/`](03_PC_IMEM/) | Entrega 1 · Ejercicio 3 · programa de clase | ✅ Verificado · repetir `consola.png` (programa nuevo) |
| [`04_ControlUnit/`](04_ControlUnit/) | Entrega 2 · Ejercicio 1 | ✅ Verificado · capturas listas |
| [`05_ALU/`](05_ALU/) | Entrega 2 · Ejercicio 2 | ✅ Verificado · capturas listas |
| [`06_ALUControl/`](06_ALUControl/) | Entrega 3 · Ejercicios 1–2 · `funct` de clase | ✅ Verificado · repetir `consola.png` (`funct` nuevos) |
| [`07_RegisterFile/`](07_RegisterFile/) | Entrega 3 · Ejercicios 3–4 | ✅ Verificado · falta `consola.png` |
| [`08_MIPS/`](08_MIPS/) | Entrega Final 1 · Procesador completo | ✅ Verificado · falta `consola.png` y foto del CMD |

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
│   ├── Entrega_Final_Procesador_MIPS.docx    # Plantilla de la Entrega Final 1 (simulación)
│   ├── Entrega_Final_2_Fisico_NanoBoard3000.docx  # Plantilla de la Entrega Final 2 (placa)
│   └── Tabla Opcode y Funct.xlsx             # Opcodes y funct (coinciden con las instrucciones de clase: D1)
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
├── 07_RegisterFile/
│   ├── README.md
│   ├── RegisterFile.v
│   └── RegisterFile_tb.v
└── 08_MIPS/                        # Reutiliza los seis módulos
    ├── README.md
    ├── MIPS.v                      # Módulo superior: instancias + assign
    └── MIPS_tb.v
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

### Simular el procesador completo

Ejecutar desde `08_MIPS/`:

```powershell
iverilog -Wall -o MIPS_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v ../04_ControlUnit/ControlUnit.v ../05_ALU/ALU.v ../06_ALUControl/ALUControl.v ../07_RegisterFile/RegisterFile.v MIPS.v MIPS_tb.v
vvp MIPS_tb.vvp
gtkwave MIPS_tb.vcd MIPS_tb.gtkw
```

## Conjunto de instrucciones (ISA)

Opcodes y códigos `funct`: los de las **26 instrucciones binarias de clase** (decisión D1), que coinciden con
`docs/Tabla Opcode y Funct.xlsx`. MOV no aparece en esas instrucciones y conserva el `funct` de la tabla del
enunciado de ALUControl. Los `funct` de SUB, MUL y DIV de esa tabla (`100100`, `100001`, `100010`) **ya no se
usan**: con ellos, el `SUB` de clase (`100010`) se habría ejecutado como DIV.

| Instrucción | Tipo | Opcode | Funct | `ALUOp` | `alu_control` | Operación |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **ADD** | R | `000000` | `100000` | `10` | `0010` | `$rd = $rs + $rt` |
| **SUB** | R | `000000` | `100010` | `10` | `0110` | `$rd = $rs - $rt` |
| **MUL** | R | `000000` | `011000` | `10` | `1000` | `$rd = $rs * $rt` (32 bits bajos) |
| **DIV** | R | `000000` | `011010` | `10` | `1001` | `$rd = $rs / $rt` (con signo; entre 0 da 0) |
| **MOV** | R | `000000` | `100011` | `10` | `0001` | `$rd = $rs` |
| **MOVI** | I | `001010` | — | `00` | `0000` | `$rt = imm` |
| **ADDI** | I | `001000` | — | `01` | `0010` | `$rt = $rs + imm` |
| **SUBI** | I | `001001` | — | `11` | `0110` | `$rt = $rs - imm` |
| **JUMP** | J | `000010` | — | `00` | — | `PC = address` |

El inmediato de 16 bits se extiende **con signo** a 32 bits (D7): un inmediato `-3` llega a la ALU como
`0xFFFFFFFD`. (Los inmediatos del programa de clase son todos positivos.)

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
- [x] **`02_IMEM`** — 1024 × 32 bits, las 26 instrucciones de clase, lectura combinacional; fuera de 0–1023 lee `0`. 31/31 lecturas OK.
- [x] **`03_PC_IMEM`** — PC + IMEM con `next_pc = current_pc + 1`; instrucción y campos en cada ciclo. 27/27 ciclos OK.
- [x] **`04_ControlUnit`** — Decodificador de opcode con valores por defecto antes del `case`. 12/12 pruebas OK.
- [x] **`05_ALU`** — Con signo, `/0 → 0`, control no definido → `0`, bandera `zero`. 22/22 pruebas OK.
- [x] **`06_ALUControl`** — `always @(*)` con valor por defecto y `case` sobre `ALUOp` y `funct` (los de clase). 17/17 pruebas OK.
- [x] **`07_RegisterFile`** — 32 × 32 bits, lectura asíncrona, escritura síncrona, `$0` siempre en `0`. 19/19 pruebas OK.

### Pendiente para entregar

- [ ] **Capturas de consola** (deben verse `iverilog` y `vvp`): repetir `02_IMEM`, `03_PC_IMEM` y
  `06_ALUControl` (cambiaron con el programa de clase) y tomar las de `07_RegisterFile` y `08_MIPS`. La de
  `04_ControlUnit` empieza con un intento fallido (`vvp ControlUnit.vvp`); conviene repetirla o recortarla.
- [ ] Llenar las plantillas `.docx` con el código, las capturas y las tablas de casos de cada README.
  En la entrega 3, explicar las filas 7, 10 y 11 de la tabla de ALUControl (ver
  [Diferencias con las plantillas](#diferencias-con-las-plantillas)).

### Entrega Final 1 · Procesador completo

Todo lo que pide la plantilla está en [`08_MIPS/README.md`](08_MIPS/README.md#entrega-final-1-cómo-responde-el-diseño).

- [x] Archivos `.v`: `PC.v`, `IMEM.v`, `ControlUnit.v`, `ALUControl.v`, `RegisterFile.v`, `ALU.v`, el top module
  `MIPS.v` y el testbench `MIPS_tb.v`. Juntos en una carpeta compilan con `iverilog -o salida.vvp *.v`.
- [x] IMEM de 1024 palabras con las 26 instrucciones de clase copiadas sin cambios.
- [x] Testbench con el formato sugerido (`PC=… Instr=…`, campos, señales, `rd1`/`rd2`/`ALU` y `$rd<=valor`),
  26 ciclos explicados en un comentario, y los 32 registros al final. 0 errores.
- [x] `gtkwave.png` con reloj, PC, instrucción, control, operandos, ALU, registro escrito y `$1`–`$20`.
- [x] Valores esperados a mano (secciones 8 y 10) y decisiones de diseño (sección 9) redactadas en el README.
- [ ] `consola.png` de `08_MIPS` (varias capturas consecutivas si no cabe).
- [ ] Foto del CMD con la tabla «Valores finales de los registros».
- [ ] Llenar `Entrega_Final_Procesador_MIPS.docx`: integrantes, módulos, diagrama, código, capturas y tablas.

### Fase 4 · Integración del datapath

Los seis módulos se conectan en [`08_MIPS`](08_MIPS/) sin modificarlos. Detalle en
[Arquitectura §5.8](docs/Arquitectura.md#s5-8).

- [x] **`08_MIPS/MIPS.v`** — Módulo superior: seis instancias con el mismo `clk` y `reset` para el PC y el banco;
  campos, extensión de signo, mux `RegDst`, mux `ALUSrc`, `PC + 1`, mux `Jump` y write-back, todo con `assign`.
  Compila sin advertencias con `iverilog -Wall`.
- [x] **`08_MIPS/MIPS_tb.v`** — Reset, 26 ciclos del programa de clase comparados señal por señal con
  [Arquitectura §7](docs/Arquitectura.md#s7), registro escrito tras cada flanco y estado final de los 32
  registros. Todo OK; seis de siete mutaciones detectadas (la extensión con ceros no se nota: el programa de
  clase no tiene inmediatos negativos).

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
| D1 | `funct` de las instrucciones binarias de clase (= `.xlsx`); MOV conserva el del enunciado | IMEM, ALUControl |
| D2 | `ALUOp`: `00` MOVI, `01` ADDI, `10` tipo R, `11` SUBI | ControlUnit, ALUControl |
| D3 | Tabla de control sin `x`: JUMP y opcodes no definidos con `RegWrite = 0` | ControlUnit |
| D4 | ALU con signo; división entre cero → `0`; control no definido → `0` | ALU |
| D5 | IMEM de 1024 palabras; sin programa y fuera de 0–1023 lee `0` (NOP): tras `JUMP 1024` los registros quedan congelados | IMEM |
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
| Entrega 3 · ALUControl, casos 2–4 | `funct` del enunciado (SUB `100100`, MUL `100001`, DIV `100010`) | `funct` de las instrucciones de clase (`100010`, `011000`, `011010`), D1 | [`06_ALUControl`](06_ALUControl/README.md) |
| Entrega Final 1 · datapath de referencia | DMEM, `MemRead`, `MemWrite`, `MemtoReg`, sumador de *branch*, `PC + 4` | Sin DMEM ni *branch* (la ISA no los usa); `PC + 1` (D6) | [`08_MIPS`](08_MIPS/README.md) |

## Notas técnicas

| Tema | Recordatorio |
| :--- | :--- |
| **Cuándo imprimir** | El PC cambia con `<=` en `posedge`. Imprimir en `negedge` o `#1` después del flanco para observar el valor nuevo. |
| **Observar PC = 0** | El PC vale `x` hasta el primer `posedge` con `reset = 1`. Liberar el reset después de ese flanco. |
| **Lógica combinacional** | En `always @(*)`, asignar **todas** las salidas antes del `case` para evitar latches y valores `x`. |
| **Valores con signo** | Los vectores sin declaración `signed` son sin signo. Un resultado de 32 bits de `5 - 10` se imprime como `4294967291` con `%d`; usar `$signed()` para interpretarlo con signo. |
| **Multiplicación** | El producto se trunca a 32 bits: `65536 × 65536 = 0`, con `zero = 1`. |
| **Banco de Registros** | El testbench puede acceder al arreglo interno mediante una referencia jerárquica: `uut.registers[1]` (en el datapath, `uut.rf.registers[1]`). |
| **Arranque del datapath** | Antes del primer flanco las salidas de los `always @(*)` valen `x` (aún no se han ejecutado), también `RegWrite`. No hay escrituras espurias porque el reset del banco tiene prioridad. |

---

[Volver al inicio](#procesador-mips-en-verilog)