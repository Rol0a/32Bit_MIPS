# 01 — Program Counter (PC)

**Entrega 1 · Ejercicio 1** · Estado: ✅ implementado y verificado (10/10 ciclos OK) · capturas listas

## Objetivo
Registro de 32 bits que guarda la dirección de la instrucción actual y la actualiza en cada ciclo de reloj.

## Puertos

| Puerto | Dirección | Ancho | Descripción |
|---|---|---|---|
| `clk` | input | 1 | Reloj |
| `reset` | input | 1 | Reinicia el PC a 0 (activo en alto) |
| `next_pc` | input | 32 | Dirección siguiente |
| `current_pc` | output reg | 32 | Dirección actual |

## Comportamiento
- En cada `posedge clk`: si `reset = 1` → `current_pc <= 0`; si no → `current_pc <= next_pc`.
- Asignación no bloqueante (`<=`) dentro de un `always @(posedge clk)`.

## Testbench (`PC_tb.v`)
- Reloj de 10 ns (`always #5 clk = ~clk`): flancos de subida en t = 5, 15, 25, … ns.
- Inicia con `clk = 0`, `reset = 1`, `next_pc = 100`; suelta `reset` en el ciclo 3.
- Las entradas cambian en el flanco de bajada (lejos del flanco activo) y se imprime 1 ns después de
  cada flanco de subida, cuando el `<=` del PC ya se asentó.
- La tarea `verificar` compara `current_pc` con el esperado (con `!==`, así una `x` cuenta como error)
  e imprime `OK`/`ERROR`; al final se muestra el total de errores.
- `$dumpfile("PC_tb.vcd")` y `$dumpvars(0, PC_tb)`.

## Casos de prueba (resultados de la simulación)

| # | Caso | reset | Dir. siguiente | PC esperado | PC obtenido | ¿OK? |
|---|---|---|---|---|---|---|
| 1 | Reset activo: con `reset = 1` y `next_pc ≠ 0`, el PC queda en 0 | 1 | 100 → 200 | 0 → 0 | 0 → 0 | ✅ |
| 2 | Soltar reset: el primer flanco con `reset = 0` carga `next_pc` | 0 | 1 | 1 | 1 | ✅ |
| 3 | Avance normal: el PC copia `next_pc` en cada flanco ↑ | 0 | 2 → 3 → 4 | 2 → 3 → 4 | 2 → 3 → 4 | ✅ |
| 4 | Cambio entre flancos: `next_pc` cambia 2 veces a mitad de ciclo; el PC no cambia hasta el flanco ↑ | 0 | 50 → 60 (entre flancos) | 4 → 4 → 60 | 4 → 4 → 60 | ✅ |
| 5 | Reset a mitad de ejecución: lo regresa a 0 y luego vuelve a avanzar | 1 → 0 | 7 → 1 | 0 → 1 | 0 → 1 | ✅ |
| 6 | Adicional: dirección con los 32 bits en 1 se guarda completa | 0 | 4294967295 (`0xFFFFFFFF`) | 4294967295 | 4294967295 | ✅ |

Además, antes del primer flanco el PC vale `x` (el reset es síncrono), como advierte la plantilla.

### Salida de la consola
```
=== Testbench PC ===
t=  1 ns  antes del primer flanco: current_pc=x (x: el PC aun no se ha reiniciado)
ciclo  1  t=  6 ns  reset=1  next_pc=       100  ->  current_pc=         0  esperado=         0  OK     Caso 1: reset activo
ciclo  2  t= 16 ns  reset=1  next_pc=       200  ->  current_pc=         0  esperado=         0  OK     Caso 1: reset activo
ciclo  3  t= 26 ns  reset=0  next_pc=         1  ->  current_pc=         1  esperado=         1  OK     Caso 2: soltar reset
ciclo  4  t= 36 ns  reset=0  next_pc=         2  ->  current_pc=         2  esperado=         2  OK     Caso 3: avance normal
ciclo  5  t= 46 ns  reset=0  next_pc=         3  ->  current_pc=         3  esperado=         3  OK     Caso 3: avance normal
ciclo  6  t= 56 ns  reset=0  next_pc=         4  ->  current_pc=         4  esperado=         4  OK     Caso 3: avance normal
          t= 62 ns  reset=0  next_pc=        50  ->  current_pc=         4  esperado=         4  OK     Caso 4: cambio entre flancos
          t= 64 ns  reset=0  next_pc=        60  ->  current_pc=         4  esperado=         4  OK     Caso 4: cambio entre flancos
ciclo  7  t= 66 ns  reset=0  next_pc=        60  ->  current_pc=        60  esperado=        60  OK     Caso 4: carga en el flanco
ciclo  8  t= 76 ns  reset=0  next_pc=4294967295  ->  current_pc=4294967295  esperado=4294967295  OK     Caso 6: 32 bits completos
ciclo  9  t= 86 ns  reset=1  next_pc=         7  ->  current_pc=         0  esperado=         0  OK     Caso 5: reset a mitad de ejecucion
ciclo 10  t= 96 ns  reset=0  next_pc=         1  ->  current_pc=         1  esperado=         1  OK     Caso 5: avanza tras el reset
=== 10 ciclos, todas las pruebas OK ===
```

## Capturas
- `consola.png`: comando de compilación/ejecución y una línea por ciclo.
- `gtkwave.png`: `clk`, `reset`, `next_pc`, `current_pc` en **decimal**, *Zoom Fit*.

## Comandos
```powershell
iverilog -o PC_tb.vvp PC.v PC_tb.v
vvp PC_tb.vvp
gtkwave PC_tb.vcd PC_tb.gtkw    # PC_tb.gtkw abre ya las 4 señales en decimal; luego View → Zoom Fit
```
