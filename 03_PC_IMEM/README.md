# 03 — Integración PC + IMEM

**Entrega 1 · Ejercicio 3** · Estado: pendiente

## Objetivo
Conectar el PC con la IMEM para que cada ciclo se lea la instrucción apuntada por el PC.

## Conexión
```
          next_pc = current_pc + 1  (calculado en el testbench)
             │
        ┌────▼────┐ current_pc  ┌────────┐
 clk ──►│   PC    ├────────────►│  IMEM  ├──► instruction
reset ─►│         │    (addr)   │        │
        └─────────┘             └────────┘
```

- No hay módulo nuevo: la conexión vive en el testbench (`PC_IMEM_tb.v`), que instancia ambos módulos.
- Reutiliza `../01_PC/PC.v` y `../02_IMEM/IMEM.v` (no se copian).
- `next_pc = current_pc + 1` (direccionamiento por palabra, según la plantilla).

## Testbench (`PC_IMEM_tb.v`)
- Reset al inicio; soltarlo tras el primer `posedge` para alcanzar a ver la instrucción 0.
- En cada ciclo (`negedge`), dos líneas: instrucción completa y campos por nombre según el formato.
- Detener la simulación tras la última instrucción (dir. 9); las palabras 10–15 leen `x`.
- `$dumpfile("PC_IMEM_tb.vcd")` y `$dumpvars(0, PC_IMEM_tb)`.

### Formato de salida esperado
```
PC=0, Instr=000000_00001_00010_00011_00000_100000
      opcode=000000 rs=00001 rt=00010 rd=00011 shamt=00000 funct=100000
PC=1, Instr=001000_01000_01001_0000000000001010
      opcode=001000 rs=01000 rt=01001 immediate=0000000000001010
PC=8, Instr=000010_00000000000000001111101000
      opcode=000010 address=00000000000000001111101000
```

## Casos de prueba
Un ciclo por fila (ciclos 0–9): PC esperado, instrucción esperada (mnemónico), PC obtenido,
instrucción obtenida (opcode/funct). Se llena con el programa definido en `02_IMEM`.

## Capturas (`capturas/`)
- Consola: comandos y las dos líneas por ciclo.
- GTKWave: `clk`, `reset`, `current_pc` (decimal), `instruction` y campos; los 10 ciclos a la vista.

## Comandos
```powershell
iverilog -o PC_IMEM_tb.vvp ../01_PC/PC.v ../02_IMEM/IMEM.v PC_IMEM_tb.v
vvp PC_IMEM_tb.vvp
gtkwave PC_IMEM_tb.vcd
```
