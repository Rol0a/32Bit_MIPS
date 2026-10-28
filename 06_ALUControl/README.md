# 06 — Control de la ALU (ALUControl)

**Entrega 3 · Ejercicios 1–2** · Estado: ✅ implementado y verificado (15/15 pruebas OK) · capturas pendientes

## Objetivo
Traducir `ALUOp` (de la Unidad de Control) y el campo `funct` (de las instrucciones R) en el código de 4 bits
que le indica a la ALU qué operación hacer. Es lógica combinacional pura: no tiene reloj ni estado.

| Archivo | Contenido |
|---|---|
| `ALUControl.v` | Módulo `ALUControl` |
| `ALUControl_tb.v` | Testbench `ALUControl_tb`, con 15 pruebas automáticas |
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
   hoja ya no se reconocen: el `funct` de MULT en la hoja (`011000`) da `1111` (prueba 15).
2. **`ALUOp = 01` → ADDI y `ALUOp = 11` → SUBI** (decisión 2). El enunciado solo define `00` (MOVI) y `10`
   (tipo R). Si ADDI y SUBI usaran `00`, la ALU ejecutaría MOVI y el resultado sería solo el inmediato. Con
   esta extensión del grupo, los cuatro valores de `ALUOp` quedan definidos.
3. **`1111` = no definido** (decisión 4). No corresponde a ninguna operación de la ALU, así que una
   combinación inválida se distingue a simple vista en la simulación. La ALU devuelve `0` con cualquier
   código no contemplado.

## Cómo funciona el código
```verilog
always @(*) begin
    case (ALUOp)
        2'b00: alu_control = 4'b0000;                     // MOVI
        2'b01: alu_control = 4'b0010;                     // ADDI: suma
        2'b10: begin                                      // tipo R
            case (funct)
                6'b100000: alu_control = 4'b0010;         // ADD
                ...
                default:   alu_control = 4'b1111;         // funct no definido
            endcase
        end
        2'b11: alu_control = 4'b0110;                     // SUBI: resta
        default: alu_control = 4'b1111;                   // solo si ALUOp trae x o z
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
- Todos los caminos asignan `alu_control` (los dos `case` tienen `default`), así que no se infieren latches
  ni aparecen valores `x`. Con los cuatro valores de `ALUOp` cubiertos, el `default` externo solo se alcanza
  si `ALUOp` trae `x` o `z`; se conserva como protección.

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
- Tarea `probar(op, funcion, esperado, caso)`: aplica las entradas, espera 10 ns y compara `alu_control`
  con el esperado usando `!==`, así una `x` también cuenta como error. Imprime una línea por prueba con el
  número, `ALUOp`, `funct`, `alu_control`, el esperado, `OK`/`ERROR` y el nombre del caso.
- No usa reloj: el módulo es combinacional, basta con esperar a que la salida se asiente.
- Tres grupos de pruebas: las 8 instrucciones (1–8), instrucciones I que ignoran `funct` (9–12) y `funct`
  no definido (13–15).
- Al final imprime el total de pruebas y de errores.
- `$dumpfile("ALUControl_tb.vcd")` y `$dumpvars(0, ALUControl_tb)`.

## Casos de prueba (resultados de la simulación)

| # | Caso | ALUOp | funct | Esperado | Obtenido | ¿OK? |
|---|---|:---:|:---:|:---:|:---:|:---:|
| 1 | MOVI | `00` | `000000` | `0000` | `0000` | ✅ |
| 2 | ADD | `10` | `100000` | `0010` | `0010` | ✅ |
| 3 | SUB | `10` | `100100` | `0110` | `0110` | ✅ |
| 4 | MULT | `10` | `100001` | `1000` | `1000` | ✅ |
| 5 | DIV | `10` | `100010` | `1001` | `1001` | ✅ |
| 6 | MOV | `10` | `100011` | `0001` | `0001` | ✅ |
| 7 | ADDI | `01` | `000000` | `0010` | `0010` | ✅ |
| 8 | SUBI | `11` | `000000` | `0110` | `0110` | ✅ |
| 9 | MOVI ignora `funct` (el de ADD) | `00` | `100000` | `0000` | `0000` | ✅ |
| 10 | MOVI ignora `funct` (todo en 1) | `00` | `111111` | `0000` | `0000` | ✅ |
| 11 | ADDI ignora `funct` (el de SUB): sigue sumando | `01` | `100100` | `0010` | `0010` | ✅ |
| 12 | SUBI ignora `funct` (el de ADD): sigue restando | `11` | `100000` | `0110` | `0110` | ✅ |
| 13 | `funct` no definido (todo en 1) | `10` | `111111` | `1111` | `1111` | ✅ |
| 14 | `funct` no definido (todo en 0, la instrucción `0x00000000`) | `10` | `000000` | `1111` | `1111` | ✅ |
| 15 | `funct` de MULT en la hoja `.xlsx`: ya no se reconoce | `10` | `011000` | `1111` | `1111` | ✅ |

**Total: 15 pruebas, 0 errores.**

### Salida de la consola
```
=== Pruebas de ALUControl ===
 1  ALUOp=00, funct=000000 -> alu_control=0000 | esperado=0000  OK     MOVI
 2  ALUOp=10, funct=100000 -> alu_control=0010 | esperado=0010  OK     ADD
 3  ALUOp=10, funct=100100 -> alu_control=0110 | esperado=0110  OK     SUB
 4  ALUOp=10, funct=100001 -> alu_control=1000 | esperado=1000  OK     MULT
 5  ALUOp=10, funct=100010 -> alu_control=1001 | esperado=1001  OK     DIV
 6  ALUOp=10, funct=100011 -> alu_control=0001 | esperado=0001  OK     MOV
 7  ALUOp=01, funct=000000 -> alu_control=0010 | esperado=0010  OK     ADDI
 8  ALUOp=11, funct=000000 -> alu_control=0110 | esperado=0110  OK     SUBI
 9  ALUOp=00, funct=100000 -> alu_control=0000 | esperado=0000  OK     MOVI ignora funct (el de ADD)
10  ALUOp=00, funct=111111 -> alu_control=0000 | esperado=0000  OK     MOVI ignora funct (todo en 1)
11  ALUOp=01, funct=100100 -> alu_control=0010 | esperado=0010  OK     ADDI ignora funct (el de SUB)
12  ALUOp=11, funct=100000 -> alu_control=0110 | esperado=0110  OK     SUBI ignora funct (el de ADD)
13  ALUOp=10, funct=111111 -> alu_control=1111 | esperado=1111  OK     funct no definido (todo en 1)
14  ALUOp=10, funct=000000 -> alu_control=1111 | esperado=1111  OK     funct no definido (todo en 0)
15  ALUOp=10, funct=011000 -> alu_control=1111 | esperado=1111  OK     funct de MULT en la hoja .xlsx
=== Fin: pruebas=15, errores=0 ===
ALUControl_tb.v:76: $finish called at 150 (1ns)
```

## Capturas (`capturas/`, pendientes)
- `consola.png`: comandos de compilación y ejecución, y las 15 líneas de prueba.
- `gtkwave.png`: `ALUOp`, `funct`, `alu_control` y `esperado` en binario, con las 15 pruebas a la vista
  (150 ns) y *Zoom Fit*.

## Comandos
```powershell
iverilog -o ALUControl_tb.vvp ALUControl.v ALUControl_tb.v
vvp ALUControl_tb.vvp
gtkwave ALUControl_tb.vcd ALUControl_tb.gtkw    # abre ya las 4 señales en binario; luego View → Zoom Fit
```
