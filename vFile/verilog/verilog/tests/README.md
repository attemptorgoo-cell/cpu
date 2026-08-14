# RV32I directed regression tests

Each archived test passed in Vivado when it was created. Tests 01–10 establish the earlier combinational-RAM baseline; Test 11 targets the synchronous-RAM Load-use change, Test 12 is the post-refactor consolidated regression, and Test 13 verifies explicit `use_rs1/use_rs2` decode metadata plus Load-use hazard gating. The user confirmed every run printed `All tests passed!`. After Test 13 passed, the active simulation was restored to Test 12 for the final consolidated regression.

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
| `11_sync_ram_load_use.hex` | Synchronous RAM and one-cycle Load-use stalls into ALU, Branch and Store | `x2=42`, `x3=43`, `x4=x5=x7=x8=85`, `x6=0`, `x9=170`, `RAM[0..2]=42,85,85`, `stall_count=4` |
| `12_sync_memory_consolidated.hex` | Consolidated synchronous Load/Store widths, byte lanes, Load-use consumers and taken redirect | `x1=x2=80ff7f01`, `x19..x22=a1b25501`, `x23=7`, `RAM[0]=RAM[1]=a1b25501`, `RAM[2]=0`, `stall_count=10` |
| `13_use_rs_decode_and_hazard.hex` | Decoder `use_rs1/use_rs2` matrix, unused-field false collisions, and true Load-use dependencies through rs1/rs2 | `x1=x5=x8=x10=x11=x12=42`, `x6=5`, `x7=00028000`, `x9=43`, `RAM[0]=RAM[1]=42`, `stall_count=3` |

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

### 11 — Synchronous RAM and Load-use stalls

```assembly
addi x1, x0, 42
sw   x1, 0(x0)
lw   x2, 0(x0)
addi x3, x2, 1
add  x4, x2, x3
sw   x4, 4(x0)
lw   x5, 4(x0)
beq  x5, x4, target
addi x6, x0, 99       # wrong path
target: lw x7, 4(x0)
sw   x7, 8(x0)
lw   x8, 8(x0)
add  x9, x8, x8
jal  x0, 0
```

Confirms that synchronous RAM returns Load data in WB and that each immediate consumer stalls for exactly one cycle before using WB-to-EX forwarding. It covers Load-to-ALU, Load-to-Branch, Load-to-Store-data and a dual-source Load dependency. The taken branch also proves that the held instruction stream resumes without executing the wrong-path `addi`.

### 12 — Consolidated synchronous memory regression

```assembly
lui  x1, 0x80ff8
addi x1, x1, -255       # x1 = 80ff7f01
sw   x1, 0(x0)

lw   x2, 0(x0)
addi x3, x2, 1
lb   x4, 0(x0)
addi x5, x4, 1
lb   x6, 1(x0)
addi x7, x6, 1
lbu  x8, 2(x0)
addi x9, x8, 1
lb   x10, 3(x0)
addi x11, x10, 1
lh   x12, 0(x0)
addi x13, x12, 1
lhu  x14, 2(x0)
addi x15, x14, 1

addi x16, x0, 0x55
sb   x16, 1(x0)
addi x17, x0, 0x66
sb   x17, 3(x0)
lui  x18, 0xA
addi x18, x18, 0x1b2    # x18 = 0000a1b2
sh   x18, 2(x0)         # RAM[0] = a1b25501

lw   x19, 0(x0)
add  x20, x19, x0
lw   x21, 0(x0)
sw   x21, 4(x0)
sw   x0, 8(x0)          # sentinel for wrong-path Store
lw   x22, 4(x0)
beq  x22, x19, target
addi x23, x0, 99        # wrong path
sw   x1, 8(x0)          # wrong path
target: addi x23, x0, 7
jal  x0, 0
```

This single regression replaces a manual rerun of the earlier memory-focused tests after the synchronous-RAM refactor. It checks LW/LB/LBU/LH/LHU formatting, SW/SB/SH lane writes, immediate Load consumers in ALU/Store/Branch paths, WB-to-EX forwarding, exactly ten one-cycle stalls, taken redirect, and preservation of the known-zero `RAM[2]` sentinel against a wrong-path Store.

### 13 — Explicit source-use decode and hazard gating

```assembly
addi x1,  x0, 42
sw   x1,  0(x0)

lw   x5,  0(x0)
addi x6,  x0, 5       # raw instr[24:20]=5, but OP-IMM does not use rs2

lw   x5,  0(x0)
lui  x7,  0x28        # raw instr[19:15]=5, but LUI uses no GPR source

lw   x8,  0(x0)
addi x9,  x8, 1       # true rs1 dependency

lw   x10, 0(x0)
add  x11, x0, x10     # true R-type rs2 dependency

lw   x12, 0(x0)
sw   x12, 4(x0)       # true Store-data rs2 dependency

jal  x0, 0
```

The testbench also probes one representative encoding for each supported opcode class: JAL and U-type instructions produce `0/0`; JALR, Load and OP-IMM produce `1/0`; Branch, Store and OP produce `1/1`; an unknown opcode defaults to `0/0`. The two raw-field collisions must not add stalls, while the three real dependencies must each add exactly one stall. Vivado passed every decoder and architectural check with `stall_count=3`.
