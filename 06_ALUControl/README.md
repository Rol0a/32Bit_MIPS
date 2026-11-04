# 06 — Control de la ALU (ALUControl)

**Entrega 3 · Ejercicios 1–2 → Entrega Final** · Estado: ✅ implementado y verificado (17/17 pruebas OK) ·
`gtkwave.png` lista, `consola.png` por repetir (`funct` de las instrucciones de clase)

## Objetivo
Traducir `ALUOp` (de la Unidad de Control) y el campo `funct` (de las instrucciones R) en el código de 4 bits
que le indica a la ALU qué operación hacer. Es lógica combinacional pura: no tiene reloj ni estado.

| Archivo | Contenido |
|---|---|
| `ALUControl.v` | Módulo `ALUControl` |
| `ALUControl_tb.v` | Testbench `ALUControl_tb`, con 17 pruebas automáticas en el orden de la plantilla |
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
| `10` | `100010` | SUB | `0110` | `result = src1 - src2` |
| `10` | `011000` | MULT | `1000` | `result = src1 * src2` |
| `10` | `011010` | DIV | `1001` | `result = src1 / src2` |
| `10` | `100011` | MOV | `0001` | `result = src1` |
| `10` | otro | no definido | `1111` | `result = 0` |
| `11` | cualquiera | SUBI | `0110` | `result = src1 - src2` |

## Decisiones de diseño

1. **Códigos `funct` de las instrucciones binarias de clase** (decisión D1 del README principal). ADD
   `100000`, SUB `100010`, MUL `011000` y DIV `011010` son los que traen las 26 instrucciones que el
   procesador debe ejecutar en la Entrega Final; coinciden con `docs/Tabla Opcode y Funct.xlsx`. MOV no
   aparece en esas instrucciones y conserva el `100011` de la tabla del enunciado de ALUControl.
   > **Cambio respecto a la Entrega 3.** Antes se usaban los `funct` de la tabla del enunciado de ALUControl
   > (SUB `100100`, MUL `100001`, DIV `100010`). Con ellos, `SUB $7, $3, $1` de clase (`funct = 100010`) se
   > habría ejecutado como DIV (`$7 = 3` en vez de 35) y los MUL/DIV de clase habrían dado `1111` (`0`). Los
   > códigos viejos de SUB y MUL ahora dan `1111` (pruebas 13 y 14).
2. **`ALUOp = 01` → ADDI y `ALUOp = 11` → SUBI** (decisión D2). El enunciado solo define `00` (MOVI) y `10`
   (tipo R). Si ADDI y SUBI usaran `00`, la ALU ejecutaría MOVI y el resultado sería solo el inmediato. Con
   esta extensión del grupo, los cuatro valores de `ALUOp` quedan definidos. Es la respuesta a «SUBI: ¿cómo
   consigue tu diseño que reste?» de la Entrega Final: la Unidad de Control manda `ALUOp = 11` y ALUControl lo
   convierte en `0110`, el mismo código de SUB.
   > **Ojo con la plantilla de la Entrega 3.** Su caso 7 dice que ADDI «llega con `ALUOp = 00`» y sus casos
   > 10 y 11 tratan `01` y `11` como «no definidos». En nuestro diseño no es así: la prueba 7 muestra que ADDI
   > con `00` daría `0000` (MOVI, la ALU devolvería solo el inmediato), y las pruebas 10 y 11 muestran que
   > `01` y `11` dan suma y resta.
3. **`1111` = no definido** (decisión D9). No corresponde a ninguna operación de la ALU, así que una
   combinación inválida se distingue a simple vista en la simulación. La ALU devuelve `0` con cualquier
   código no contemplado. La palabra `0` que la IMEM devuelve fuera del programa (después de `JUMP 1024`) cae
   aquí: `funct = 000000` → `1111` → la ALU da 0 y el destino es `$0` (NOP).
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
                6'b100010: alu_control = 4'b0110;         // SUB
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
  baja del inmediato, así que pueden valer cualquier cosa. Por ejemplo, `ADDI $1, $1, 10` llega con
  `funct = 001010`.
- **ADDI y SUBI reutilizan los códigos de ADD y SUB:** la ALU no distingue si `src2` viene de un registro o
  del inmediato; eso lo decide el mux `ALUSrc`. Por eso bastan `0010` y `0110`.
- **Sin latches:** `alu_control` recibe `1111` antes del `case`, así que todos los caminos le dan un valor y
  no aparecen latches ni valores `x`. Con los cuatro valores de `ALUOp` cubiertos, el `default` externo solo
  se alcanza si `ALUOp` trae `x` o `z` (prueba 17); se conserva como protección.

## Interacción con los otros módulos

ALUControl está entre la Unidad de Control y la ALU; en el procesador completo es la instancia `aluc` de
`08_MIPS/MIPS.v`. El testbench de esta carpeta prueba el módulo aislado.

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
| R con `funct` no definido | `10` | `1111` | `result = 0` | `$rd = 0` (si `rd = 0`, nada: NOP) |
| MOVI | `00` | `0000` | `result = src2` (inmediato) | `$rt = imm` |
| ADDI | `01` | `0010` | `src1 + src2` (inmediato) | `$rt = $rs + imm` |
| SUBI | `11` | `0110` | `src1 - src2` (inmediato) | `$rt = $rs - imm` |
| JUMP | `00` | `0000` | irrelevante | ninguno: `RegWrite = 0` |

Todas las operaciones de la ALU son con signo y el inmediato llega extendido con signo a 32 bits: por ejemplo,
`SUB $13, $4, $3` con `$4 = 25` y `$3 = 50` deja `$13 = -25`. Una instrucción R con `funct` no definido sí
escribe en `$rd`, porque la Unidad de Control solo ve el opcode y pone `RegWrite = 1`; lo que se escribe es
`0`.

El recorrido completo de una instrucción por el datapath está en el
[README del banco de registros](../07_RegisterFile/README.md) y en el del [procesador](../08_MIPS/README.md).

## Testbench (`ALUControl_tb.v`)
- Tarea `probar(op, fn, esperado, caso)`: aplica las entradas, espera 10 ns y compara `alu_control` con el
  esperado usando `===`, así una `x` también cuenta como error. Imprime una línea por prueba con el formato
  del enunciado (`ALUOp=10, funct=100000 -> alu_control=0010`), el esperado, `OK`/`ERROR` y el caso.
- No usa reloj: el módulo es combinacional, basta con esperar a que la salida se asiente.
- Las pruebas 1–11 son los casos 1–11 de la plantilla, en el mismo orden. En las instrucciones I, `funct`
  lleva los 6 bits bajos del inmediato de una instrucción real del programa de clase (`MOVI $1, 15` →
  `001111`, `ADDI $1, $1, 10` → `001010`, `SUBI $2, $2, 4` → `000100`). Las pruebas 12–17 son adicionales.
- No hay línea de resumen: un fallo se ve como `ERROR` en su fila. Las filas no llevan número: la prueba N es la fila N de la consola.
- `$dumpfile("ALUControl_tb.vcd")` y `$dumpvars(0, ALUControl_tb)`.
- **Comprobación del testbench:** con tres errores introducidos a propósito en `ALUControl.v` (quitar el
  valor por defecto, ADDI como MOVI, MOV mal codificado) el testbench reporta 5, 2 y 1 errores. Detecta los
  tres.

## Casos de prueba (resultados de la simulación)

Las columnas siguen la tabla de la plantilla; el esperado sale de la tabla implementada y de las decisiones
D1, D2 y D9.

| # | Caso de prueba | ALUOp | funct | Esperado | Obtenido (consola) | ¿OK? |
|---|---|:---:|:---:|:---:|:---:|:---:|
| 1 | ADD | `10` | `100000` | `0010` | `0010` | ✅ |
| 2 | SUB | `10` | `100010` | `0110` | `0110` | ✅ |
| 3 | MULT | `10` | `011000` | `1000` | `1000` | ✅ |
| 4 | DIV | `10` | `011010` | `1001` | `1001` | ✅ |
| 5 | MOV | `10` | `100011` | `0001` | `0001` | ✅ |
| 6 | MOVI (`funct` elegido: bits bajos de `MOVI $1, 15`) | `00` | `001111` | `0000` | `0000` | ✅ |
| 7 | ADDI si llegara con `ALUOp = 00`, como supone la plantilla: sale MOVI. Por eso nuestro ADDI usa `01` (caso 10) | `00` | `001010` | `0000` | `0000` | ✅ |
| 8 | Con `ALUOp = 00` el `funct` de la suma no cambia nada | `00` | `100000` | `0000` | `0000` | ✅ |
| 9 | `funct` no definido: nuestro módulo devuelve `1111` | `10` | `111111` | `1111` | `1111` | ✅ |
| 10 | `ALUOp = 01`: el grupo lo usa para ADDI → suma | `01` | `001010` | `0010` | `0010` | ✅ |
| 11 | `ALUOp = 11`: el grupo lo usa para SUBI → resta | `11` | `000100` | `0110` | `0110` | ✅ |
| 12 | Adicional: `funct` todo en 0 (la NOP que la IMEM devuelve fuera del programa) | `10` | `000000` | `1111` | `1111` | ✅ |
| 13 | Adicional: SUB de la tabla del enunciado, ya no se usa | `10` | `100100` | `1111` | `1111` | ✅ |
| 14 | Adicional: MUL de la tabla del enunciado, ya no se usa | `10` | `100001` | `1111` | `1111` | ✅ |
| 15 | Adicional: ADDI con el `funct` de SUB: sigue sumando | `01` | `100010` | `0010` | `0010` | ✅ |
| 16 | Adicional: SUBI con el `funct` de ADD: sigue restando | `11` | `100000` | `0110` | `0110` | ✅ |
| 17 | Adicional: `ALUOp` con `x`: el valor por defecto evita la `x` | `xx` | `100000` | `1111` | `1111` | ✅ |

**Total: 17 pruebas, 0 errores.** En la plantilla, la fila 12 («caso adicional») puede llevar cualquiera de
las pruebas 12–17.

### Salida de la consola
```
ALUOp=10, funct=100000 -> alu_control=0010 | esperado=0010  OK     Caso 1: ADD
ALUOp=10, funct=100010 -> alu_control=0110 | esperado=0110  OK     Caso 2: SUB
ALUOp=10, funct=011000 -> alu_control=1000 | esperado=1000  OK     Caso 3: MULT
ALUOp=10, funct=011010 -> alu_control=1001 | esperado=1001  OK     Caso 4: DIV
ALUOp=10, funct=100011 -> alu_control=0001 | esperado=0001  OK     Caso 5: MOV
ALUOp=00, funct=001111 -> alu_control=0000 | esperado=0000  OK     Caso 6: MOVI (funct = bits de imm 15)
ALUOp=00, funct=001010 -> alu_control=0000 | esperado=0000  OK     Caso 7: ADDI con ALUOp=00 da MOVI
ALUOp=00, funct=100000 -> alu_control=0000 | esperado=0000  OK     Caso 8: ALUOp=00 ignora funct de ADD
ALUOp=10, funct=111111 -> alu_control=1111 | esperado=1111  OK     Caso 9: funct no definido
ALUOp=01, funct=001010 -> alu_control=0010 | esperado=0010  OK     Caso 10: ALUOp=01, ADDI (suma)
ALUOp=11, funct=000100 -> alu_control=0110 | esperado=0110  OK     Caso 11: ALUOp=11, SUBI (resta)
ALUOp=10, funct=000000 -> alu_control=1111 | esperado=1111  OK     Adicional: funct 000000 (palabra 0)
ALUOp=10, funct=100100 -> alu_control=1111 | esperado=1111  OK     Adicional: 100100 (SUB del enunciado)
ALUOp=10, funct=100001 -> alu_control=1111 | esperado=1111  OK     Adicional: 100001 (MUL del enunciado)
ALUOp=01, funct=100010 -> alu_control=0010 | esperado=0010  OK     Adicional: ADDI con funct de SUB
ALUOp=11, funct=100000 -> alu_control=0110 | esperado=0110  OK     Adicional: SUBI con funct de ADD
ALUOp=xx, funct=100000 -> alu_control=1111 | esperado=1111  OK     Adicional: ALUOp x
ALUControl_tb.v:40: $finish called at 170000 (1ps)
```

## Capturas
- `gtkwave.png` (lista): `ALUOp`, `funct`, `alu_control` y `esperado` en binario, con las 17 pruebas a la
  vista (170 ns) y *Zoom Fit*.
- `consola.png` (por repetir): desde esta carpeta, con **los dos comandos visibles** (`iverilog` y `vvp`) y
  las 17 líneas de prueba. La captura anterior es de la versión con los `funct` del enunciado.

## Comandos
```powershell
iverilog -o ALUControl_tb.vvp ALUControl.v ALUControl_tb.v
vvp ALUControl_tb.vvp
gtkwave ALUControl_tb.vcd ALUControl_tb.gtkw    # abre ya las 4 señales en binario; luego View → Zoom Fit
```
