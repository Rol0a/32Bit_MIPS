# 09 — Procesador MIPS en la NanoBoard-3000XN

**Entrega Final 2 · Presentación física** · Estado: ✅ simulado y verificado (carga, 23 pasos con rebotes,
32/32 registros, Run y divisor) · ⏳ falta probarlo en la placa (Altium Designer 14.3, Spartan-3AN)

## Objetivo
Un solo archivo Verilog, `MIPS_NanoBoard.v`, que se agrega al proyecto FPGA de Altium y contiene todo el
procesador. El programa entra por el **Memory Instrument 1**, el procesador lo ejecuta dentro de la FPGA y los
registros se leen en el **Memory Instrument 2**. Es el mismo procesador de [`08_MIPS`](../08_MIPS/README.md)
(mismas instrucciones, mismos resultados) más lo que pide la placa:

- la IMEM se escribe desde afuera (instrumento 1) y se puede leer de vuelta;
- los 32 registros se leen desde afuera (instrumento 2);
- Reset, Run y Step deciden cuándo avanza el procesador, con el mismo enable para el PC y el banco.

No ejecuta solo el programa de clase: corre cualquier programa escrito con las 9 instrucciones de la ISA
(ver [Verificación](#verificación)).

| Archivo | Contenido | ¿Va a Altium? |
|---|---|---|
| `MIPS_NanoBoard.v` | Todo el diseño: tabla de la ISA, módulo superior `MIPS_NanoBoard` y los siete módulos | **Sí, solo este** |
| `MIPS_NanoBoard_tb.v` | Testbench: hace el papel de la placa y de los dos instrumentos | No (solo simulación) |

Los módulos de `01`–`07` y `08_MIPS/MIPS.v` no se tocan: siguen siendo las entregas simuladas.

## Contenido de `MIPS_NanoBoard.v`

| Sección | Qué es | Diferencia con la versión simulada |
|---|---|---|
| 1. Tabla de la ISA | Opcodes, funct, ALUOp y códigos de la ALU con nombre (`` `OP_ADDI ``, `` `ALU_DIV ``…) | Antes eran números repetidos en tres módulos |
| 2. `MIPS_NanoBoard` | Módulo superior: los pines del símbolo en Altium | Puertos de los instrumentos y controles; el PC se queda en 1024 |
| 3. `RunControl` | Reset, Run, Step y espera de la DIV → `advance` | Nuevo |
| 4. `PC` | Program Counter | Entrada `enable` |
| 5. `IMEM` | 1024 palabras, dos puertos | Puerto de escritura y lectura de vuelta; sin programa precargado |
| 6. `ControlUnit` | opcode → control | Igual, con nombres |
| 7. `ALUControl` | ALUOp + funct → operación | Igual, con nombres |
| 8. `ALU` | Operaciones con signo | DIV escrita como división binaria paso a paso (en vez de `/`) |
| 9. `RegisterFile` | 32 registros | Tercer puerto de lectura para el instrumento 2 |

```
 Interruptores ─► RunControl ──advance──┬──────────────► PC ──current_pc──► IMEM ──instruction──┐
 y botón Step     (sincroniza, filtra,  │                                    ▲  │                 │
                   un pulso por Step,   │                 Instrumento 1 ─────┘  └─► imem_rdata    │
                   espera de la DIV)    │                                                         ▼
                                        └─► RegWrite & advance ─► RegisterFile ◄── ControlUnit, ALUControl
                                                                   │  ▲                         │
                                       Instrumento 2 ◄── reg_data ─┘  └──── ALU ◄───────────────┘
```

## Pines: qué se conecta a qué (sección 2 de la plantilla)

| Pin del instrumento / control | Puerto de `MIPS_NanoBoard` | Ancho | Sentido |
|---|---|:---:|---|
| Instrumento 1 · dirección | `imem_addr` | 10 | instrumento → diseño |
| Instrumento 1 · dato (escritura) | `imem_wdata` | 32 | instrumento → diseño |
| Instrumento 1 · escritura | `imem_we` | 1 | instrumento → diseño |
| Instrumento 1 · dato (lectura), si lo tiene | `imem_rdata` | 32 | diseño → instrumento |
| Instrumento 2 · dirección | `reg_addr` | 5 | instrumento → diseño |
| Instrumento 2 · dato | `reg_data` | 32 | diseño → instrumento |
| Control · Reset | `reset_sw` | 1 | interruptor → diseño |
| Control · Run | `run_sw` | 1 | interruptor → diseño |
| Control · Step | `step_btn` | 1 | botón → diseño |
| Reloj | `clk` | 1 | placa → diseño |
| (opcional) | `current_pc`, `instruction` | 32 | diseño → otro instrumento o LEDs |

Los tres controles son **activos en alto** (1 = activo), como en la plantilla. Si en la placa un interruptor
o el botón da 0 al activarlo, se pone un inversor en el esquemático entre el pin y el puerto.
`current_pc` e `instruction` se pueden dejar sin conectar.

## Parámetros que se pueden editar

Están al principio del módulo `MIPS_NanoBoard`. También se pueden cambiar desde el esquemático sin tocar el
archivo, si la versión de Altium deja editar los parámetros del símbolo.

| Parámetro | Valor | Qué controla | Cuándo cambiarlo |
|---|:---:|---|---|
| `IMEM_WORDS` | `1024` | Palabras de la IMEM | Si el Build dice que el diseño no cabe: bajarlo (256, 128…). Las direcciones que sobran leen 0 |
| `DIV_WAIT` | `16` | Ciclos extra de una DIV (dura `DIV_WAIT + 1`) | Con un reloj más rápido que 20 MHz, subirlo (máximo 255) |
| `DEBOUNCE_BITS` | `18` | Filtro del botón: 2^18 ciclos = 13 ms a 20 MHz | Si un Step todavía avanza dos instrucciones, subirlo a 19 o 20 |

## Cómo se usa en la placa

1. **Reset = 1, Run = 0.** El PC queda en 0 y los 32 registros en 0.
2. **Escribir el programa** en el instrumento 1: palabra #1 en la dirección 0, #2 en la 1… hasta la #26 en la
   25. Leer de vuelta para confirmar (`imem_rdata`). Las direcciones que no se escriben valen 0 (NOP).
3. **Reset = 0.** Sin pulsar Step no cambia nada.
4. **Step:** cada pulsación ejecuta una instrucción. En el instrumento 2, escribir el número de registro en
   la dirección y leer sus 32 bits.
5. **Run = 1:** el programa corre a reloj completo y en unos 3 µs llega al JUMP 1024. Ahí el PC se queda en
   1024 y los registros ya no cambian: se leen los finales con calma.

Para volver a empezar: Reset = 1 (borra los registros; la IMEM conserva el programa) y Reset = 0.

### En Altium Designer 14.3
1. Agregar `MIPS_NanoBoard.v` al proyecto FPGA (**no** el testbench).
2. En la hoja principal, crear el símbolo del módulo `MIPS_NanoBoard` a partir del archivo (en AD14, algo como
   *Design » Create Sheet Symbol From Sheet or HDL*; el nombre exacto del menú puede variar).
3. Poner los dos Memory Instrument y los controles, y cablear según la tabla de pines.
4. Compilar y revisar las advertencias de anchos (10, 32 y 5 bits) y de pines sin conectar.
5. Programar la FPGA y abrir los instrumentos desde *Instrument Rack – Soft Devices*.

## Decisiones de diseño

| # | Decisión | Por qué |
|---|---|---|
| B1 | **El PC se queda quieto al salir de la IMEM** (`pc_outside`). Tras JUMP 1024 el PC vale 1024 para siempre | Es el «lazo final» de la plantilla sin cambiar ninguna instrucción de clase. Si siguiera contando, a reloj completo daría la vuelta a 0 tras 2^32 ciclos (unos 3,6 min a 20 MHz) y el programa volvería a correr |
| B2 | **La DIV espera `DIV_WAIT` ciclos** antes de escribir; las demás instrucciones tardan un ciclo | El divisor no tiene reloj y tarda más que un ciclo de 50 ns. Con Run a reloj completo la DIV escribiría un valor a medio calcular. Con Step la espera no se nota |
| B3 | **DIV escrita como división binaria paso a paso** (función `signed_div`) en vez de `$signed(a) / $signed(b)` | No está confirmado que el sintetizador de Altium 14 acepte `/` con divisor variable; sumas, restas y comparaciones las acepta cualquiera. Da exactamente lo mismo que la ALU de `05_ALU` (entre 0 da 0) |
| B4 | **Run = 1 es reloj completo**: una instrucción por ciclo | Decisión del grupo |
| B5 | **Step con sincronización, filtro de rebotes y detección de flanco** | Solo con el flanco, un rebote del botón puede avanzar varias instrucciones (síntoma de la plantilla «un pulso avanza varias») |
| B6 | **Reset y Run también se sincronizan** (dos flip-flops) | Vienen de interruptores, sin relación con el reloj. Cuesta 2 ciclos de retraso |
| B7 | **Lectura de vuelta de la IMEM** (`imem_rdata`) | La plantilla pide leer de vuelta el programa (paso 6). En la Spartan-3AN usa la salida del puerto de escritura de la RAM distribuida: no gasta memoria extra |
| B8 | **Funct no definido: igual que en simulación** (escribe 0 en `rd`) | El procesador de la placa se comporta igual que `08_MIPS`; no hay nada que explicar en «Diferencias con la simulación» |
| B9 | **Sin programa precargado**: la IMEM arranca en 0 | Lo que corre es exactamente lo que se escribió con el instrumento |
| B10 | **Los códigos de la ISA tienen nombre** (`` `define `` al principio del archivo) | Un código se cambia en un solo lugar; los módulos se leen como la tabla de instrucciones |

## Cómo agregar una instrucción

**Tipo R con una operación nueva**, por ejemplo `AND rd, rs, rt` (funct `100100`):

1. Tabla 1: `` `define FUNCT_AND 6'b100100 `` y un código de ALU libre: `` `define ALU_AND 4'b0011 ``.
2. `ALUControl`, dentro de `` `ALUOP_R ``: `` `FUNCT_AND: alu_control = `ALU_AND; ``
3. `ALU`: `` `ALU_AND: result = src1 & src2; ``

ControlUnit no cambia: todas las tipo R comparten el opcode `000000`.

**Tipo I con una operación nueva** (ANDI, ORI, SLTI…): además de lo anterior hace falta un opcode
(`` `define OP_ANDI ``) y una rama en ControlUnit. Como los cuatro valores de `ALUOp` (2 bits) ya están
usados, hay que ensanchar `ALUOp` a 3 bits en `ControlUnit`, `ALUControl` y en el cable del módulo superior.

**Una operación lenta** (que no termine en un ciclo): agregarla en `assign slow_op` del módulo superior para
que también espere `DIV_WAIT` ciclos.

Después de cualquier cambio: agregar la prueba al testbench y simular (ver [Comandos](#comandos)).

## Diferencias con la simulación (sección 8 de la plantilla)

| Situación | Respuesta |
|---|---|
| Dirección de cada instrucción | La #1 en la dirección 0 y la #n en la n − 1. La dirección 30 no se usa: no se escribe y lee 0 (NOP). El programa termina con el JUMP 1024 de la dirección 21 |
| Diferencias con la simulación | Los registros terminan con los mismos valores. Cambian dos cosas que no se ven en los registros: el PC se queda en 1024 (en `08_MIPS` sigue contando 1025, 1026…) y en Run cada DIV tarda 17 ciclos en vez de 1 |

## Verificación

**Testbench (`MIPS_NanoBoard_tb.v`)**, con reloj de 20 MHz y el filtro reducido a 8 ciclos (`DEBOUNCE_BITS = 3`).
Un solo `$display` da una línea por comprobación: la fase, el PC, las direcciones de los dos instrumentos, el
valor, el esperado, `OK`/`ERROR` y qué se comprueba. No hay línea de resumen: un fallo se ve como `ERROR` en su fila.

| Fase | Qué comprueba | Resultado |
|---|---|---|
| 1 | Escribe las 26 palabras por el puerto del instrumento 1 y las lee de vuelta; direcciones 30 y 1023 leen 0 | ✅ |
| 2 | Reset = 0 y Run = 0 durante 50 ciclos: PC = 0 y los 32 registros en 0 | ✅ |
| 3 | 23 pulsaciones con 3 rebotes al pulsar y 3 al soltar: cada una ejecuta **exactamente una** instrucción; el registro escrito tiene el valor calculado a mano; incluye la tabla de la sección 5 (pasos 1, 5, 6, 9, 21) | ✅ |
| 4 | Los 32 registros por el puerto del instrumento 2 | ✅ 32/32 |
| 5 | Reset y Run = 1: el PC se queda en 1024, la DIV dura 17 ciclos, el programa 54 ciclos, registros finales correctos | ✅ |
| 6 | Otro programa: −7 / 2 = −3, −7 / −2 = 3, 2 / −2 = −1, −7 / 0 = 0, 7 / −2 = −3 | ✅ |

**Programas aleatorios.** 1600 programas aleatorios (todas las instrucciones, los 32 registros, inmediatos
negativos y extremos, saltos hacia adelante, hacia atrás, a sí mismos y fuera de la IMEM, palabras sin
definir) se cargaron por el puerto del instrumento 1, corrieron con Run (`DIV_WAIT` = 0, 3 y 16) y se leyeron
por el del instrumento 2. Los 1600 coinciden con un modelo de la ISA escrito aparte en Python.

**El testbench detecta los errores.** Con tres errores metidos a propósito:

| Error | Testbench | Programas aleatorios |
|---|---|---|
| El divisor ignora el signo | 3 errores (fase 6) | 4 de 100 |
| El PC no se queda en 1024 | 2 errores (fases 3 y 5) | 44 de 100 |
| El banco escribe sin `advance` | 17 errores (fases 2, 3 y 4) | 2 de 100 |

**Síntesis: sin probar todavía.** No se pudo sintetizar en esta computadora (el Altium Designer 26 instalado
no parece incluir el flujo de FPGA, que sí tiene el 14.3 del laboratorio). Estimación a mano para la XC3S1400AN (22 528 LUT, 22 528 flip-flops):

| Bloque | Estimación |
|---|---|
| IMEM 1024 × 32, RAM distribuida de doble puerto | ~4100 LUT como RAM + ~1300 de multiplexores |
| Banco de registros | 1024 flip-flops + ~1000 LUT (3 puertos de lectura) |
| Divisor (32 etapas de 33 bits) | ~2100 LUT |
| Multiplicador | 4 multiplicadores 18 × 18 de la FPGA |
| **Total** | **~9 000 – 10 000 LUT (cerca del 45 %)** |

Si el sintetizador no convierte la IMEM en RAM y la arma con flip-flops, 1024 × 32 = 32 768 flip-flops no
caben: en ese caso, bajar `IMEM_WORDS` a 256.

## Comandos

```bash
# Desde esta carpeta. -g2001: solo Verilog-2001, lo que acepta Altium 14
iverilog -g2001 -Wall -o MIPS_NanoBoard_tb.vvp MIPS_NanoBoard.v MIPS_NanoBoard_tb.v
vvp MIPS_NanoBoard_tb.vvp
gtkwave MIPS_NanoBoard_tb.vcd
```

## Pendiente
- [ ] Probar en la placa: Build en Altium 14.3, carga del programa, tabla de la sección 5 y registros finales.
- [ ] Capturas de la plantilla: esquemático, instrumento de instrucciones e instrumento de resultados.
- [ ] Llenar la hoja `docs/Entrega_Final_2_Fisico_NanoBoard3000.docx`.
