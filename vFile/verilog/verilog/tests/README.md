# RV32I directed regression tests

These tests have been run in Vivado against the current five-stage CPU and confirmed by the user to print `All tests passed!`.

The active simulation still reads `../inst_data.hex`. Files in `hex/` are immutable snapshots of passing programs, and matching files in `expected/` preserve the exact `check_regFile` and `check_memory` calls that passed. To rerun one manually, copy its hex contents into `inst_data.hex` and its `.svh` check block into the checking section of `test.sv`.

RAM expectations use the internal word-array index `ram[index]`, not a byte address.

## Test index

| Test | Main coverage | Expected architectural state |
|---|---|---|
| `01_basic_load_use.hex` | ADDI, ADD forwarding, SW/LW, immediate load-use | `x1=5`, `x2=7`, `x3=12`, `x4=12`, `x5=17`, `RAM[0]=12` |
| `02_branch_flush.hex` | Taken BEQ and suppression of wrong-path register/RAM writes | `x1=5`, `x2=0`, `x3=7`, `x6=42`, `RAM[1]=42` |
| `03_jal_jalr.hex` | JAL/JALR targets, link addresses and wrong-path flush | `x2=0`, `x3=7`, `x4=0`, `x5=16`, `x7=36`, `x8=9`, `x10=44`, `RAM[2]=42` |
| `04_load_store_width.hex` | SB/SH and LB/LBU/LH/LHU sign/zero extension | `x2=ffffffff`, `x3=000000ff`, `x5=fffffffe`, `x6=0000fffe`, `x7=fffeff00`, `RAM[0]=fffeff00` |
| `05_branch_compare.hex` | BNE/BLT/BGE/BLTU/BGEU taken and BEQ not taken | `x1=ffffffff`, `x2=1`, `x3..x8=3..8` |
| `06_integer_alu.hex` | RV32I R/I ALU operations, LUI and AUIPC | `x1=fffffff0`, `x3=fffffff3`, `x10=fffffffe`, `x11=1`, `x12=0`, `x22=12345000`, `x23=00001058` |
| `07_backward_redirect.hex` | Backward BLT loop, negative memory offsets, forward/backward JAL | `x1=5`, `x3=15`, `x6=42`, `x7=44`, `x10=60`, `x11=11`, `RAM[15]=42` |
| `08_ram_byte_lane.hex` | All four SB lanes, both SH halves, LBU/LHU readback | `x5=11223344`, `x7=11223344`, `x8..x11=44,33,22,11`, `RAM[0]=RAM[1]=11223344` |
| `09_jalr_edge.hex` | JALR bit-0 clearing, negative immediate, base forwarding, x0 protection | `x0=0`, `x2=0`, `x3=7`, `x4=9`, `x5=20`, `x7=44`, `x9=0`, `RAM[3]=42` |
| `10_forwarding_stress.hex` | Newest-result priority, dual-source/store/load/branch forwarding | `x1=3`, `x2=6`, `x3=43`, `x5=44`, `x7=7`, `RAM[0]=0`, `RAM[4]=43` |

## Detailed programs

### 01 — Basic load-use

```assembly
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2
sw   x3, 0(x0)
lw   x4, 0(x0)
add  x5, x4, x1
jal  x0, 0
```

### 02 — Branch flush

```assembly
addi x1, x0, 5
addi x6, x0, 42
sw   x6, 4(x0)
beq  x1, x1, target
addi x2, x0, 99       # wrong path
sw   x1, 4(x0)        # wrong path
target: addi x3, x0, 7
jal  x0, 0
```

### 03 — JAL and JALR

Tests a JAL from PC 12 to 24 and a JALR from PC 32 to address 44. Instructions between each redirect and its target must not change registers or RAM.

### 04 — Load/store widths

Builds `RAM[0]=fffeff00` with SB and SH, then distinguishes signed LB/LH from unsigned LBU/LHU.

### 05 — Branch comparisons

Uses `x1=-1` and `x2=1` to distinguish signed from unsigned comparisons across all six RV32I branch forms.

### 06 — Integer ALU

Exercises ADD/SUB, bitwise operations, register/immediate shifts, signed/unsigned set-less-than, LUI and AUIPC. Several operations consume recently produced values.

### 07 — Backward redirects

Runs a five-iteration BLT loop producing `1+2+3+4+5=15`, accesses byte address 60 through `-4(x4)`, and tests both positive and negative JAL offsets.

### 08 — RAM byte lanes

Constructs `0x11223344` twice: once using four SB operations and once using two SH operations. It then reads every byte and both halfwords independently.

### 09 — JALR edge cases

Checks `(rs1 + imm) & ~1` with odd targets 33 and 49, including a negative immediate and a just-produced base register. Wrong-path writes must not take effect.

### 10 — Forwarding stress

Performs three consecutive writes to x1 before consuming it twice, then combines Store address/data forwarding, immediate load-use forwarding, and a branch comparison using the newest value. RAM[0] is explicitly initialized before testing wrong-path Store suppression.
