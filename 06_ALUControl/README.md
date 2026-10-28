# 06 — Control de la ALU (ALUControl)

**Entrega 3 · Ejercicios 1–2** · Estado: ✅ implementado y verificado (16/16 pruebas OK) · `gtkwave.png` lista,
`consola.png` por repetir (debe verse también el comando `iverilog`)

## Objetivo
Traducir `ALUOp` (de la Unidad de Control) y el campo `funct` (de las instrucciones R) en el código de 4 bits
que le indica a la ALU qué operación hacer. Es lógica combinacional pura: no tiene reloj ni estado.

| Archivo | Contenido |
|---|---|
| `ALUControl.v` | Módulo `ALUControl` |
| `ALUControl_tb.v` | Testbench `ALUControl_tb`, con 16 pruebas automáticas en el orden de la plantilla |
| `ALUControl_tb.gtkw` | Vista guardada de GTKWave: las 4 señales en binario |

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `ALUOp` | input | 2 | Clase de operación, generada por la Unidad de Control |
| `funct` | input | 6 | Campo `funct` de las instrucciones tipo R |
| `alu_control` | output reg | 4 | Operación para la ALU |

## Tabla de verdad implementada

| ALUOp | funct | Instrucción | `alu_control` | Operación de la ALU |
|---|---|---|:---:|---|
| `00` | cualquiera | MOVI | `0000` | `result = src2` (inmediato) |
| `01` | cualquiera | ADDI | `0010` | `result = src1 + src2` |
| `10` | `100000` | ADD | `0010` | `result = src1 + src2` |
| `10` | `100100` | SUB | `0110` | `result = src1 - src2` |
| `10` | `100001` | MULT | `1000` | `result = src1 * src2` |
| `10` | `100010` | DIV | `1001` | `result = src1 / src2` |
| `10` | `100011` | MOV | `0001` | `result = src1` |
| `10` | otro | no definido | `1111` | `result = 0` |
| `11` | cualquiera | SUBI | `0110` | `result = src1 - src2` |

## Decisiones de diseño

1. **Códigos `funct` del enunciado** (decisión 1 del README principal). Se usan los de la tabla de
   ALUControl, **no** los de `docs/Tabla Opcode y Funct.xlsx`, que se contradecían con ella (`100010` era SUB
   en una y DIV en la otra). El programa de la IMEM se codifica con estos mismos valores. Los códigos de la
   hoja ya no se reconocen: el `funct` de MULT en la hoja (`011000`) da `1111` (prueba 13).
2. **`ALUOp = 01` → ADDI y `ALUOp = 11` → SUBI** (decisión 2). El enunciado solo define `00` (MOVI) y `10`
   (tipo R). Si ADDI y SUBI usaran `00`, la ALU ejecutaría MOVI y el resultado sería solo el inmediato. Con
   esta extensión del grupo, los cuatro valores de `ALUOp` quedan definidos.
   > **Ojo con la plantilla.** Su caso 7 dice que ADDI «llega con `ALUOp = 00`» y sus casos 10 y 11 tratan
   > `01` y `11` como «no definidos». En nuestro diseño no es así: la prueba 7 muestra que ADDI con `00`
   > daría `0000` (MOVI, la ALU devolvería solo el inmediato), y las pruebas 10 y 11 muestran que `01` y
   > `11` dan suma y resta. Al llenar la tabla del `.docx`, explicarlo en esas tres filas.
3. **`1111` = no definido** (decisión 4). No corresponde a ninguna operación de la ALU, así que una
   combinación inválida se distingue a simple vista en la simulación. La ALU devuelve `0` con cualquier
   código no contemplado.
4. **Valor por defecto antes del `case`**, como pide la plantilla y como hacen la Unidad de Control y la ALU.
   `alu_control = 1111` se asigna primero; cada rama solo lo cambia si la combinación está definida.

## Cómo funciona el código
```verilog
always @(*) begin
    alu_control = 4'b1111;                                // por defecto: no definido
    case (ALUOp)
        2'b00: alu_control = 4'b0000;                     // MOVI
        2'b01: alu_control = 4'b0010;                     // ADDI: suma
        2'b10: begin                                      // tipo R
            case (funct)
                6'b100000: alu_control = 4'b0010;         // ADD
                ...
                default: ;                                // funct no definido: queda 1111
            endcase
        end
        2'b11: alu_control = 4'b0110;                     // SUBI: resta
        default: ;                                        // solo si ALUOp trae x o z: queda 1111
    endcase
end
```
- `always @(*)` se reevalúa en cuanto cambia `ALUOp` o `funct`. La salida se declara `output reg` solo
  porque se asigna dentro de un `always`; no guarda ningún valor entre ciclos.
- **Decodificación en dos niveles:** `ALUOp` decide la clase de instrucción y solo cuando vale `10` (tipo R)
  se consulta `funct`. En MOVI, ADDI y SUBI, `funct` se ignora: en una instrucción I esos 6 bits son la parte
  baja del inmediato, así que pueden valer cualquier cosa. Por ejemplo, `addi $9, $8, 10` llega con
  `funct = 001010`.
- **ADDI y SUBI reutilizan los códigos de ADD y SUB:** la ALU no distingue si `src2` viene de un registro o
  del inmediato; eso lo decide el mux `ALUSrc`. Por eso bastan `0010` y `0110`.
- **Sin latches:** `alu_control` recibe `1111` antes del `case`, así que todos los caminos le dan un valor y
  no aparecen latches ni valores `x`. Con los cuatro valores de `ALUOp` cubiertos, el `default` externo solo
  se alcanza si `ALUOp` trae `x` o `z` (prueba 16); se conserva como protección.

## Interacción con los otros módulos

ALUControl está entre la Unidad de Control y la ALU. Se integrará en el datapath en la Fase 4 del README
principal (fuera del alcance de esta práctica); por ahora el testbench prueba el módulo aislado.

```
  IMEM: instr[31:26] (opcode)
            │
            ▼
       ControlUnit
            │  ALUOp [1:0]
            ▼
       ALUControl ◄─────── IMEM: instr[5:0] (funct)
            │  alu_control [3:0]
            ▼
           ALU ◄────────── src1 = read_data1 · src2 = read_data2 o inmediato
            │  result
            ▼
      RegisterFile (write_data; se escribe en el flanco ↑)
```

| Puerto | Viene de / va a | Detalle |
|---|---|---|
| `ALUOp` | ControlUnit | Sale del opcode: `00` en MOVI, `01` en ADDI, `10` en tipo R y `11` en SUBI |
| `funct` | IMEM: `instruction[5:0]` | Solo tiene sentido en tipo R; en tipo I son los 6 bits bajos del inmediato |
| `alu_control` | ALU: `alu_control` | La ALU usa esta misma codificación desde la entrega 2 |

**Por qué un módulo aparte:** la Unidad de Control solo mira el opcode, y todas las instrucciones R comparten
el opcode `000000`; la operación concreta está en `funct`. ALUControl hace ese segundo nivel de
decodificación, de modo que la Unidad de Control no necesita leer `funct`.

**Todo ocurre en el mismo ciclo:** IMEM → ControlUnit → ALUControl → ALU es una cadena combinacional. El
resultado está listo antes del siguiente flanco de subida, que es cuando el banco de registros lo guarda.

### Relación con el banco de registros
ALUControl no se conecta al banco de registros, pero decide qué valor llega a su `write_data`:

| Instrucción | `ALUOp` | `alu_control` | Operación de la ALU | Efecto en el banco |
|---|:---:|:---:|---|---|
| ADD | `10` | `0010` | `src1 + src2` | `$rd = $rs + $rt` |
| SUB | `10` | `0110` | `src1 - src2` | `$rd = $rs - $rt` |
| MULT | `10` | `1000` | `src1 * src2` | `$rd = $rs * $rt` |
| DIV | `10` | `1001` | `src1 / src2` | `$rd = $rs / $rt` |
| MOV | `10` | `0001` | `result = src1` | `$rd = $rs` |
| R con `funct` no definido | `10` | `1111` | `result = 0` | `$rd = 0` |
| MOVI | `00` | `0000` | `result = src2` (inmediato) | `$rt = imm` |
| ADDI | `01` | `0010` | `src1 + src2` (inmediato) | `$rt = $rs + imm` |
| SUBI | `11` | `0110` | `src1 - src2` (inmediato) | `$rt = $rs - imm` |
| JUMP | `00` | `0000` | irrelevante | ninguno: `RegWrite = 0` |

Todas las operaciones de la ALU son con signo y el inmediato llega extendido con signo a 32 bits: por ejemplo,
`subi $7, $9, 15` con `$9 = 10` deja `$7 = -5`. Una instrucción R con `funct` no definido sí escribe en
`$rd`, porque la Unidad de Control solo ve el opcode y pone `RegWrite = 1`; lo que se escribe es `0`.

El recorrido completo de una instrucción por el datapath (`add $3, $1, $2`) está en el
[README del banco de registros](../07_RegisterFile/README.md).

## Testbench (`ALUControl_tb.v`)
- Tarea `probar(op, fn, esperado, caso)`: aplica las entradas, espera 10 ns y compara `alu_control` con el
  esperado usando `!==`, así una `x` también cuenta como error. Imprime una línea por prueba con el formato
  del enunciado (`ALUOp=10, funct=100000 -> alu_control=0010`), el esperado, `OK`/`ERROR` y el caso.
- No usa reloj: el módulo es combinacional, basta con esperar a que la salida se asiente.
- Las pruebas 1–11 son los casos 1–11 de la plantilla, en el mismo orden. En las instrucciones I, `funct`
  lleva los 6 bits bajos del inmediato de una instrucción real del programa (`movi $1, 7` → `000111`,
  `addi $9, $8, 10` → `001010`, `subi $7, $9, 15` → `001111`). Las pruebas 12–16 son adicionales.
- Al final imprime el total de pruebas y si hubo errores.
- `$dumpfile("ALUControl_tb.vcd")` y `$dumpvars(0, ALUControl_tb)`.
- **Comprobación del testbench:** con tres errores introducidos a propósito en `ALUControl.v` (quitar el
  valor por defecto, ADDI como MOVI, MOV mal codificado) el testbench reporta 4, 2 y 1 errores. Detecta los
  tres.

## Casos de prueba (resultados de la simulación)

Las columnas siguen la tabla de la plantilla; el esperado sale de la tabla del enunciado y de las decisiones 2
y 3.

| # | Caso de prueba | ALUOp | funct | Esperado | Obtenido (consola) | ¿OK? |
|---|---|:---:|:---:|:---:|:---:|:---:|
| 1 | ADD | `10` | `100000` | `0010` | `0010` | ✅ |
| 2 | SUB | `10` | `100100` | `0110` | `0110` | ✅ |
| 3 | MULT | `10` | `100001` | `1000` | `1000` | ✅ |
| 4 | DIV | `10` | `100010` | `1001` | `1001` | ✅ |
| 5 | MOV | `10` | `100011` | `0001` | `0001` | ✅ |
| 6 | MOVI (`funct` elegido: bits bajos de `movi $1, 7`) | `00` | `000111` | `0000` | `0000` | ✅ |
| 7 | ADDI si llegara con `ALUOp = 00`, como supone la plantilla: sale MOVI. Por eso nuestro ADDI usa `01` (caso 10) | `00` | `001010` | `0000` | `0000` | ✅ |
| 8 | Con `ALUOp = 00` el `funct` de la suma no cambia nada | `00` | `100000` | `0000` | `0000` | ✅ |
| 9 | `funct` no definido: nuestro módulo devuelve `1111` | `10` | `111111` | `1111` | `1111` | ✅ |
| 10 | `ALUOp = 01`: el grupo lo usa para ADDI → suma | `01` | `001010` | `0010` | `0010` | ✅ |
| 11 | `ALUOp = 11`: el grupo lo usa para SUBI → resta | `11` | `001111` | `0110` | `0110` | ✅ |
| 12 | Adicional: `funct` todo en 0 (la instrucción `0x00000000`) | `10` | `000000` | `1111` | `1111` | ✅ |
| 13 | Adicional: `funct` de MULT en la hoja `.xlsx`, ya no se reconoce | `10` | `011000` | `1111` | `1111` | ✅ |
| 14 | Adicional: ADDI con el `funct` de SUB: sigue sumando | `01` | `100100` | `0010` | `0010` | ✅ |
| 15 | Adicional: SUBI con el `funct` de ADD: sigue restando | `11` | `100000` | `0110` | `0110` | ✅ |
| 16 | Adicional: `ALUOp` con `x`: el valor por defecto evita la `x` | `xx` | `100000` | `1111` | `1111` | ✅ |

**Total: 16 pruebas, 0 errores.** En la plantilla, la fila 12 («caso adicional») puede llevar cualquiera de
las pruebas 12–16.

### Salida de la consola
```
=== Testbench ALUControl ===
 1  ALUOp=10, funct=100000 -> alu_control=0010 | esperado=0010  OK     Caso 1: ADD
 2  ALUOp=10, funct=100100 -> alu_control=0110 | esperado=0110  OK     Caso 2: SUB
 3  ALUOp=10, funct=100001 -> alu_control=1000 | esperado=1000  OK     Caso 3: MULT
 4  ALUOp=10, funct=100010 -> alu_control=1001 | esperado=1001  OK     Caso 4: DIV
 5  ALUOp=10, funct=100011 -> alu_control=0001 | esperado=0001  OK     Caso 5: MOV
 6  ALUOp=00, funct=000111 -> alu_control=0000 | esperado=0000  OK     Caso 6: MOVI (funct = bits de imm 7)
 7  ALUOp=00, funct=001010 -> alu_control=0000 | esperado=0000  OK     Caso 7: ADDI con ALUOp=00 da MOVI
 8  ALUOp=00, funct=100000 -> alu_control=0000 | esperado=0000  OK     Caso 8: ALUOp=00 ignora funct de ADD
 9  ALUOp=10, funct=111111 -> alu_control=1111 | esperado=1111  OK     Caso 9: funct no definido
10  ALUOp=01, funct=001010 -> alu_control=0010 | esperado=0010  OK     Caso 10: ALUOp=01, ADDI (suma)
11  ALUOp=11, funct=001111 -> alu_control=0110 | esperado=0110  OK     Caso 11: ALUOp=11, SUBI (resta)
12  ALUOp=10, funct=000000 -> alu_control=1111 | esperado=1111  OK     Adicional: funct 000000 (instr. 0)
13  ALUOp=10, funct=011000 -> alu_control=1111 | esperado=1111  OK     Adicional: funct de MUL en la .xlsx
14  ALUOp=01, funct=100100 -> alu_control=0010 | esperado=0010  OK     Adicional: ADDI con funct de SUB
15  ALUOp=11, funct=100000 -> alu_control=0110 | esperado=0110  OK     Adicional: SUBI con funct de ADD
16  ALUOp=xx, funct=100000 -> alu_control=1111 | esperado=1111  OK     Adicional: ALUOp x
=== 16 pruebas, todas las pruebas OK ===
ALUControl_tb.v:98: $finish called at 160000 (1ps)
```

## Capturas
- `gtkwave.png` (lista): `ALUOp`, `funct`, `alu_control` y `esperado` en binario, con las 16 pruebas a la
  vista (160 ns) y *Zoom Fit*.
- `consola.png` (por repetir): desde esta carpeta, con **los dos comandos visibles** (`iverilog` y `vvp`) y
  las 16 líneas de prueba. La captura anterior solo mostraba `vvp` y es de la versión con 15 pruebas.

## Comandos
```powershell
iverilog -o ALUControl_tb.vvp ALUControl.v ALUControl_tb.v
vvp ALUControl_tb.vvp
gtkwave ALUControl_tb.vcd ALUControl_tb.gtkw    # abre ya las 4 señales en binario; luego View → Zoom Fit
```
