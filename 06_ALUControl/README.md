# 06 — Control de la ALU (ALUControl)

**Entrega 3 · Ejercicios 1–2** · Estado: ✅ implementado y verificado (11/11 pruebas OK) · capturas pendientes ·
⚠ [ADDI/SUBI sin resolver](#-pendiente-addi-y-subi)

## Objetivo
Traducir `ALUOp` (de la Unidad de Control) y el campo `funct` (de las instrucciones R) en el código de 4 bits
que le indica a la ALU qué operación hacer. Es lógica combinacional pura: no tiene reloj ni estado.

| Archivo | Contenido |
|---|---|
| `ALUControl.v` | Módulo `ALUControl` |
| `ALUControl_tb.v` | Testbench `ALUControl_tb`, con 11 pruebas automáticas |

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `ALUOp` | input | 2 | Clase de operación, generada por la Unidad de Control |
| `funct` | input | 6 | Campo `funct` de las instrucciones tipo R |
| `alu_control` | output reg | 4 | Operación para la ALU |

## Tabla de verdad implementada

| ALUOp | funct | Operación | `alu_control` |
|---|---|---|---|
| `00` | cualquiera | MOVI | `0000` |
| `10` | `100000` | ADD | `0010` |
| `10` | `100100` | SUB | `0110` |
| `10` | `100001` | MULT | `1000` |
| `10` | `100010` | DIV | `1001` |
| `10` | `100011` | MOV | `0001` |
| `10` | otro | no definido | `1111` |
| `01`, `11` | cualquiera | no definido | `1111` |

> Los códigos `funct` son los del enunciado de ALUControl (propuesta de la decisión 1 del README principal),
> **no** los de `docs/Tabla Opcode y Funct.xlsx`. El programa de la IMEM debe usar estos mismos códigos.

## Cómo funciona el código
```verilog
always @(*) begin
    case (ALUOp)
        2'b00: alu_control = 4'b0000;                     // MOVI
        2'b10: begin                                      // tipo R
            case (funct)
                6'b100000: alu_control = 4'b0010;         // ADD
                ...
                default:   alu_control = 4'b1111;         // funct no definido
            endcase
        end
        default: alu_control = 4'b1111;                   // ALUOp no definido
    endcase
end
```
- `always @(*)` se reevalúa en cuanto cambia `ALUOp` o `funct`. La salida se declara `output reg` solo
  porque se asigna dentro de un `always`; no guarda ningún valor entre ciclos.
- **Decodificación en dos niveles:** `ALUOp` decide la clase de instrucción y solo cuando vale `10` (tipo R)
  se consulta `funct`. Con `ALUOp = 00`, `funct` se ignora: en una instrucción I esos bits son parte del
  inmediato.
- Todos los caminos asignan `alu_control` (los dos `case` tienen `default`), así que no se infieren latches
  ni aparecen valores `x`.
- **`1111` = no definido:** no corresponde a ninguna operación de la ALU, así que una combinación inválida se
  distingue a simple vista en la simulación. Qué hace la ALU al recibirlo sigue pendiente (decisión 4 del
  README principal).

## ⚠ Pendiente: ADDI y SUBI
La decisión 2 del README principal propone `ALUOp = 01` → suma (`0010`) para ADDI y `ALUOp = 11` → resta
(`0110`) para SUBI, y la tabla propuesta de la Unidad de Control ya genera esos valores. La implementación
actual sigue solo la tabla del enunciado y devuelve `1111` para `01` y `11` (las pruebas 10 y 11 lo
comprueban). **Con este código, ADDI y SUBI no calcularían `$rs ± imm`.**

Para adoptar la propuesta:
1. Añadir `2'b01: alu_control = 4'b0010;` y `2'b11: alu_control = 4'b0110;` en `ALUControl.v`.
2. Cambiar el valor esperado de las pruebas 10 y 11 a `0010` y `0110` en `ALUControl_tb.v`.

Antes, confirmar la decisión 2 (idealmente con el profesor).

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
| `ALUOp` | ControlUnit | Sale del opcode: `10` en tipo R, `00` en MOVI; `01`/`11` propuestos para ADDI/SUBI |
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
| MOVI | `00` | `0000` | `result = src2` (inmediato) | `$rt = imm` |
| ADDI / SUBI | `01` / `11` | `1111` hoy (propuesta: `0010` / `0110`) | por definir | ⚠ ver [pendiente](#-pendiente-addi-y-subi) |
| JUMP | `00` | `0000` | irrelevante | ninguno: `RegWrite = 0` |

El recorrido completo de una instrucción por el datapath (`add $3, $1, $2`) está en el
[README del banco de registros](../07_RegisterFile/README.md).

## Testbench (`ALUControl_tb.v`)
- Tarea `probar(op, funcion, esperado)`: aplica las entradas, espera 10 ns, imprime `ALUOp`, `funct`,
  `alu_control` y el esperado, y cuenta un error si no coinciden (con `!==`, así una `x` cuenta como error).
- No usa reloj: el módulo es combinacional, basta con esperar a que la salida se asiente.
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
| 7 | MOVI ignora `funct` (el de ADD) | `00` | `100000` | `0000` | `0000` | ✅ |
| 8 | MOVI ignora `funct` (todo en 1) | `00` | `111111` | `0000` | `0000` | ✅ |
| 9 | `funct` no definido | `10` | `111111` | `1111` | `1111` | ✅ |
| 10 | `ALUOp = 01` (ADDI propuesto) ⚠ | `01` | `100000` | `1111` | `1111` | ✅ |
| 11 | `ALUOp = 11` (SUBI propuesto) ⚠ | `11` | `100000` | `1111` | `1111` | ✅ |

**Total: 11 pruebas, 0 errores.** ⚠ El esperado de las pruebas 10 y 11 cambia si se adopta la decisión 2.

### Salida de la consola
```
=== Pruebas de ALUControl ===
ALUOp=00, funct=000000 -> alu_control=0000 | esperado=0000
ALUOp=10, funct=100000 -> alu_control=0010 | esperado=0010
ALUOp=10, funct=100100 -> alu_control=0110 | esperado=0110
ALUOp=10, funct=100001 -> alu_control=1000 | esperado=1000
ALUOp=10, funct=100010 -> alu_control=1001 | esperado=1001
ALUOp=10, funct=100011 -> alu_control=0001 | esperado=0001
ALUOp=00, funct=100000 -> alu_control=0000 | esperado=0000
ALUOp=00, funct=111111 -> alu_control=0000 | esperado=0000
ALUOp=10, funct=111111 -> alu_control=1111 | esperado=1111
ALUOp=01, funct=100000 -> alu_control=1111 | esperado=1111
ALUOp=11, funct=100000 -> alu_control=1111 | esperado=1111
=== Fin: pruebas=11, errores=0 ===
ALUControl_tb.v:71: $finish called at 110 (1ns)
```

## Capturas (`capturas/`, pendientes)
- `consola.png`: comandos de compilación y ejecución, y las 11 líneas de prueba.
- `gtkwave.png`: `ALUOp`, `funct` y `alu_control` en binario, con las 11 pruebas a la vista (110 ns) y
  *Zoom Fit*.

## Comandos
```powershell
iverilog -o ALUControl_tb.vvp ALUControl.v ALUControl_tb.v
vvp ALUControl_tb.vvp
gtkwave ALUControl_tb.vcd
```
