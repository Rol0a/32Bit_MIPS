# 01 — Program Counter (PC)

**Entrega 1 · Ejercicio 1** · Estado: ✅ implementado y verificado (10/10 ciclos OK) ·
`gtkwave.png` lista, `consola.png` por repetir (nuevo formato del testbench)

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
- Cada caso son dos líneas: una pone `reset`, `next_pc` y el PC `esperado` (calculado a mano), y la otra
  espera el flanco e imprime: `@(posedge clk) #1 $display(...)`. El `#1` deja que el `<=` del PC se asiente.
  Los cambios entre flancos del caso 4 se imprimen con `#2`, sin flanco de por medio.
- `wire ok = (current_pc === esperado)` decide `OK`/`ERROR` en cada línea (con `===`, así una `x` cuenta
  como error). No hay línea de resumen: un fallo se ve como `ERROR` en su fila.
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

Además, antes del primer flanco el PC vale `x` (el reset es síncrono), como advierte la plantilla: la primera
línea de la consola lo comprueba.

### Salida de la consola
```
t=  1 ns  reset=1  next_pc=       100  ->  current_pc=         x  OK
t=  6 ns  reset=1  next_pc=       100  ->  current_pc=         0  OK
t= 16 ns  reset=1  next_pc=       200  ->  current_pc=         0  OK
t= 26 ns  reset=0  next_pc=         1  ->  current_pc=         1  OK
t= 36 ns  reset=0  next_pc=         2  ->  current_pc=         2  OK
t= 46 ns  reset=0  next_pc=         3  ->  current_pc=         3  OK
t= 56 ns  reset=0  next_pc=         4  ->  current_pc=         4  OK
t= 58 ns  reset=0  next_pc=        50  ->  current_pc=         4  OK
t= 60 ns  reset=0  next_pc=        60  ->  current_pc=         4  OK
t= 66 ns  reset=0  next_pc=        60  ->  current_pc=        60  OK
t= 76 ns  reset=0  next_pc=4294967295  ->  current_pc=4294967295  OK
t= 86 ns  reset=1  next_pc=         7  ->  current_pc=         0  OK
t= 96 ns  reset=0  next_pc=         1  ->  current_pc=         1  OK
PC_tb.v:66: $finish called at 96000 (1ps)
```

## Capturas
- `consola.png` (por repetir): comando de compilación/ejecución y una línea por ciclo.
- `gtkwave.png`: `clk`, `reset`, `next_pc`, `current_pc` en **decimal**, *Zoom Fit*.

## Comandos
```powershell
iverilog -o PC_tb.vvp PC.v PC_tb.v
vvp PC_tb.vvp
gtkwave PC_tb.vcd PC_tb.gtkw    # PC_tb.gtkw abre ya las 4 señales en decimal; luego View → Zoom Fit
```
