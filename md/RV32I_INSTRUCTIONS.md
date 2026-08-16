# RV32I 指令与五级流水实现手册

Updated: 2026-08-13

这是一份面向当前 CPU 项目的 RV32I 学习、译码和冒险处理手册。目标不是只记助记符，而是对每条指令都能回答：

1. 它是什么编码格式；
2. 它真正读取哪些寄存器、写哪个寄存器；
3. 立即数怎样构造；
4. 计算、访存或 redirect 的准确语义；
5. 源操作数在哪个流水级首次必须正确；
6. 当前 RTL 是否已经正确、完整地实现。

规范依据：

- [RISC-V Unprivileged ISA Specification：RV32I Base Integer Instruction Set v2.1](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html)
- [riscv-opcodes：RV I 编码定义](https://github.com/riscv/riscv-opcodes/blob/master/extensions/rv_i)
- [riscv-opcodes：RV32 I 特定编码定义](https://github.com/riscv/riscv-opcodes/blob/master/extensions/rv32_i)

本文中的流水级、旁路和 stall 是**当前 CPU 的微架构实现**，不是 ISA 对所有处理器规定的固定做法。

建议阅读路线：

- 第一次建立整体印象：读第 2、3、4、6、14 节；
- 查某条指令的合法编码和语义：读第 5 节；
- 设计 decoder、hazard 或 forwarding：读第 4、6、7、9 节；
- 手工读机器码：读第 3、5、10 节；
- 快速复习：直接回答第 14 节的问题，再回查不会的部分。

## 1. 范围和术语

本文只讨论：

- `XLEN=32`，整数寄存器和 PC 均为 32 位；
- RV32I 基础整数 ISA 的 40 条独立指令；
- 固定 32-bit 指令编码；
- 当前五级顺序流水线：`IF → ID → EX → MEM → WB`。

本文不包含：

- RV64I 的 `*W`、`LD/SD` 等指令；
- M 扩展的乘除法；
- A 原子扩展；
- F/D 浮点扩展；
- C 压缩扩展；
- `Zicsr` 的六条 CSR 指令；
- `Zifencei` 的 `FENCE.I`；
- 特权指令和完整 trap/中断系统。

容易混淆的边界：

- `ECALL`、`EBREAK` 和 `FENCE` 属于 RV32I，本文会列出；
- `FENCE.I` 已属于 `Zifencei`，不是基础 RV32I；
- CSR 指令属于 `Zicsr`，不是基础 RV32I；
- `MRET`、`WFI`、`mtvec/mepc/mcause` 等属于特权架构；
- 伪指令不是 decoder 要新增的硬件指令，而是汇编器展开已有真指令。

## 2. 先记住的核心模型

### 2.1 架构状态

- 32 个 32 位整数寄存器：`x0`～`x31`；
- `x0` 永远读出 0，写入结果被丢弃；
- `pc` 保存当前指令地址；
- 除 `x0` 外，寄存器没有硬件规定的特殊用途；`ra/sp/a0` 等只是 ABI 软件约定。

即使 `rd=x0`，指令的其他语义仍然存在。例如 `lw x0, 0(x1)` 不能仅因目标是 x0 就跳过访存语义：访问异常仍必须报告，执行环境定义的 I/O 读取行为也仍须遵守，只是正常读出的寄存器结果被丢弃。

### 2.2 60 秒速记

| 指令格式/类别 | `rs1` | `rs2` | `rd` | 最重要的用途 |
|---|---:|---:|---:|---|
| R 型 OP | 读 | 读 | 写 | 两个寄存器做 ALU 运算 |
| I 型 OP-IMM | 读 | 不读 | 写 | 寄存器与立即数运算 |
| I 型 Load | 读 | 不读 | 写 | `rs1+imm` 是地址 |
| I 型 JALR | 读 | 不读 | 写 | `rs1+imm` 是跳转目标 |
| S 型 Store | 读 | 读 | 不写 | `rs1` 是地址，`rs2` 是写数据 |
| B 型 Branch | 读 | 读 | 不写 | 比较两寄存器并决定 redirect |
| U 型 | 不读 | 不读 | 写 | 大立即数，LUI 或 AUIPC |
| J 型 JAL | 不读 | 不读 | 写 | PC 相对跳转并保存 `pc+4` |
| FENCE/ECALL/EBREAK | 不读 | 不读 | 不写 | 顺序约束或请求 trap |

记忆句：

> R 两读一写；I 通常一读一写；S/B 两读不写；U/J 不读而写。

其中最值得额外记忆的是 Store：汇编语法 `sw rs2, imm(rs1)` 中，括号里的 `rs1` 是地址基址，第一个操作数 `rs2` 是写入内存的数据。

## 3. 固定字段和六种格式

### 3.1 所有格式中的固定位置

本文所列固定 32-bit 基础指令都满足 `instr[1:0]=2'b11`。如果引入 C 扩展，低两位不是 `11` 的编码可能表示 16-bit 压缩指令；当前项目不支持这种情况。

| 字段 | 指令位 | 含义 |
|---|---:|---|
| `opcode` | `[6:0]` | 指令大类 |
| `rd` | `[11:7]` | 目标寄存器（该格式有目标时） |
| `funct3` | `[14:12]` | 类内功能选择 |
| `rs1` | `[19:15]` | 源寄存器 1（该格式真正使用时） |
| `rs2` | `[24:20]` | 源寄存器 2（该格式真正使用时） |
| `funct7` | `[31:25]` | 更细的功能选择 |

固定字段位置降低了硬件译码成本，但**位段位置固定不代表每种格式都把它当寄存器**。例如 I 型的 `[24:20]` 属于立即数；U/J 型中落在 `rs1/rs2` 位置的位也属于立即数。

### 3.2 格式布局

```text
31          25 24      20 19      15 14   12 11       7 6          0
+--------------+----------+----------+-------+----------+------------+
| funct7       | rs2      | rs1      |funct3 | rd       | opcode     | R
+--------------+----------+----------+-------+----------+------------+
| imm[11:0]               | rs1      |funct3 | rd       | opcode     | I
+--------------+----------+----------+-------+----------+------------+
| imm[11:5]    | rs2      | rs1      |funct3 |imm[4:0]  | opcode     | S
+--------------+----------+----------+-------+----------+------------+
| imm[12|10:5] | rs2      | rs1      |funct3 |imm[4:1|11]| opcode    | B
+-----------------------------------------------+----------+------------+
| imm[31:12]                                   | rd       | opcode     | U
+-------------------------+----------+----------+----------+------------+
| imm[20|10:1|11|19:12]                       | rd       | opcode     | J
+----------------------------------------------------------+------------+
```

### 3.3 立即数重组

```systemverilog
I_imm = {{20{instr[31]}}, instr[31:20]};
S_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
B_imm = {{19{instr[31]}}, instr[31], instr[7],
         instr[30:25], instr[11:8], 1'b0};
U_imm = {instr[31:12], 12'b0};
J_imm = {{11{instr[31]}}, instr[31], instr[19:12],
         instr[20], instr[30:21], 1'b0};
```

等价地，只要最终总位宽是 32，也可以把 B/J 的符号位复制数与显式的 `instr[31]` 合并书写。关键是最终位数和位序必须正确。

| 立即数 | 数值范围/粒度 | 备注 |
|---|---|---|
| I/S | `-2048`～`2047` | 12 位二补码，符号扩展 |
| B | `-4096`～`4094`，偶数 | 编码最低位隐含 0，约 ±4 KiB |
| J | `-1048576`～`1048574`，偶数 | 编码最低位隐含 0，约 ±1 MiB |
| U | 20 位字段放入结果 `[31:12]` | 低 12 位补 0 |
| shift amount | `0`～`31` | RV32I 只使用 5 位 |

所有普通有符号立即数的符号位都位于 `instr[31]`。移位立即数是特例：`instr[24:20]` 是 5 位 `shamt`，高位用于严格区分合法的 SLLI/SRLI/SRAI 编码。

### 3.4 “偏移为 2 的倍数”不等于“目标必然 4 字节对齐”

B/J 立即数的最低位隐含 0，因此编码粒度是 2 字节。当前项目没有 C 扩展，基础 ISA 的 `IALIGN=32`，实际指令地址仍必须 4 字节对齐。

- taken Branch、JAL、JALR 若产生非 4 字节对齐目标，本应报告 instruction-address-misaligned；
- not-taken Branch 不报告其目标错位；
- 当前 RTL 尚未实现该异常。

## 4. `use_rs1/use_rs2` 的准确含义

项目讨论中常称为 `uses_rs1/uses_rs2`；当前工作树中的 RTL 信号名是 `use_rs1/use_rs2`。本文用 `use_rs*` 指代这一概念。

对当前这个简单 decoder，`use_rs1=1` 的含义是：

> 按这条合法基础运算的普通语义执行时，`rs1` 扮演整数源操作数角色。

它不表示：

- 指令某个固定原始位段恰好有一个寄存器号；
- 这个寄存器号不是 `x0`；
- 一定需要 stall；
- 一定在 EX 才读取寄存器堆。

例如：

```assembly
addi x6, x0, 5       # 机器码 0x00500313
```

这里原始 `instr[24:20]=5`，但该位段属于 I 型立即数，不是 `rs2`。因此：

```text
rs1=x0, use_rs1=1
use_rs2=0
```

即使源寄存器编码为 `x0`，`use_rs1` 仍为 1，因为它描述指令类别的操作数角色。`rd=x0` 不构成 RAW 生产者，应由 hazard 条件中的 `producer.rd != 0` 排除。

#### HINT 的保守处理

RV32I 中很多 `rd=x0` 的计算编码属于 HINT：除了推进 PC 和可能的性能计数器外，它们不改变架构可见状态，实现可以忽略提示。例如 `addi x0,x5,0` 可以不真正等待或读取 x5。

本文的 `use_rs*` 表按“把编码当作普通基础运算执行”的保守操作数角色填写，因此 OP/OP-IMM 即使 `rd=x0` 仍保持相应 `use_rs*=1`。这样简单而且正确，只可能产生不必要的等待，不会得到错误结果。未来若专门识别 HINT，可以在确认没有异常或其他可见副作用后进一步清除其动态依赖。NOP/HINT 不增加 RV32I 的 40 条独立指令计数。

### 4.1 `valid`、`legal/illegal` 和 `use_rs*` 应分开

- `valid`：流水槽里确实有一条指令；
- `legal/illegal`：完整 opcode、funct3、funct7 组合是否合法；
- `use_rs*`：一条合法指令读取哪些 GPR。

非法指令不是 bubble。未来严格译码应先默认关闭寄存器写、内存和 redirect 副作用，只有完整合法匹配才设置控制信号；非法有效指令则携带 PC 和原始机器码进入 trap 流程。

## 5. RV32I 40 条指令总表

### 5.0 opcode 速记地图

```text
LOAD     0000011    OP-IMM  0010011    AUIPC   0010111
STORE    0100011    OP      0110011    LUI     0110111
BRANCH   1100011    JALR    1100111    JAL     1101111
FENCE    0001111    SYSTEM  1110011
```

可以先按 opcode 认出大类，再用 funct3/funct7 确定具体指令。不要反过来死记每条 32 位机器码。

状态说明：

- **已实现**：当前数据通路能够执行合法编码，归档回归合计覆盖了该指令族；
- **未实现**：当前没有该指令所需的架构语义；
- 所有“已实现”指令仍受第 9 节所列严格译码、异常和地址范围限制。

### 5.1 U 型与无条件跳转

| 指令 | 格式 | opcode | funct3 | `use1/use2` | rd | 准确语义 | 当前状态 |
|---|---|---|---|---:|---|---|---|
| LUI | U | `0110111` | — | `0/0` | 写 | `rd = U_imm` | 已实现 |
| AUIPC | U | `0010111` | — | `0/0` | 写 | `rd = pc + U_imm` | 已实现 |
| JAL | J | `1101111` | — | `0/0` | 写 | `rd=pc+4; pc=pc+J_imm` | 已实现 |
| JALR | I | `1100111` | `000` | `1/0` | 写 | `rd=pc+4; pc=(rs1+I_imm)&~1` | 已实现；未严格检查 funct3 |

### 5.2 条件分支

所有 Branch 都是 B 型、opcode=`1100011`、`use1/use2=1/1`、不写 `rd`，target 均为“本条 Branch 的 `pc + B_imm`”。

| 指令 | funct3 | 条件 |
|---|---|---|
| BEQ | `000` | `rs1 == rs2` |
| BNE | `001` | `rs1 != rs2` |
| BLT | `100` | `$signed(rs1) < $signed(rs2)` |
| BGE | `101` | `$signed(rs1) >= $signed(rs2)` |
| BLTU | `110` | `unsigned(rs1) < unsigned(rs2)` |
| BGEU | `111` | `unsigned(rs1) >= unsigned(rs2)` |

六条均已实现。当前 decoder 尚未把其他 `funct3` 识别为非法指令。

### 5.3 Load

所有 Load 都是 I 型、opcode=`0000011`、`use1/use2=1/0`，有效地址为：

```text
EA = rs1 + sext(I_imm)
```

| 指令 | funct3 | 读取宽度 | 写入 rd |
|---|---|---:|---|
| LB | `000` | 8 位 | 符号扩展到 32 位 |
| LH | `001` | 16 位 | 符号扩展到 32 位 |
| LW | `010` | 32 位 | 原 32 位值 |
| LBU | `100` | 8 位 | 零扩展到 32 位 |
| LHU | `101` | 16 位 | 零扩展到 32 位 |

五条均已实现。当前同步 RAM 的 Load 数据在 WB 才能提供给紧邻消费者；非法 `funct3=011/110/111` 尚未被严格拒绝。

### 5.4 Store

所有 Store 都是 S 型、opcode=`0100011`、`use1/use2=1/1`，有效地址同样为：

```text
EA = rs1 + sext(S_imm)
```

| 指令 | funct3 | 写入内存的数据 |
|---|---|---|
| SB | `000` | `rs2[7:0]` |
| SH | `001` | `rs2[15:0]` |
| SW | `010` | `rs2[31:0]` |

三条均已实现。注意 `rs1` 是地址基址，`rs2` 才是 Store 数据；非法 funct3 尚未形成 illegal trap。

### 5.5 OP-IMM

所有 OP-IMM 都写 `rd`，opcode=`0010011`，`use1/use2=1/0`。

| 指令 | funct3 | 固定高 7 位/编码约束 | 语义 |
|---|---|---|---|
| ADDI | `000` | — | `rd = rs1 + sext(imm12)` |
| SLTI | `010` | — | `rd = signed(rs1) < signed(sext(imm12))` |
| SLTIU | `011` | — | `rd = unsigned(rs1) < unsigned(sext(imm12))` |
| XORI | `100` | — | `rd = rs1 ^ sext(imm12)` |
| ORI | `110` | — | `rd = rs1 \| sext(imm12)` |
| ANDI | `111` | — | `rd = rs1 & sext(imm12)` |
| SLLI | `001` | `funct7=0000000` | `rd = rs1 << shamt[4:0]` |
| SRLI | `101` | `funct7=0000000` | 逻辑右移，左侧补 0 |
| SRAI | `101` | `funct7=0100000` | 算术右移，左侧复制符号位 |

九条均已实现。当前 decoder 对移位立即数的完整 `funct7` 检查不严格。

特别注意：SLTIU 的立即数仍然先从 12 位**符号扩展**到 32 位，然后把两边作为无符号数比较。

### 5.6 OP（寄存器—寄存器）

所有 OP 都是 R 型、opcode=`0110011`、`use1/use2=1/1` 并写 `rd`。

| 指令 | funct3 | funct7 | 语义 |
|---|---|---|---|
| ADD | `000` | `0000000` | `rd = rs1 + rs2` |
| SUB | `000` | `0100000` | `rd = rs1 - rs2` |
| SLL | `001` | `0000000` | `rd = rs1 << rs2[4:0]` |
| SLT | `010` | `0000000` | 有符号小于则 1，否则 0 |
| SLTU | `011` | `0000000` | 无符号小于则 1，否则 0 |
| XOR | `100` | `0000000` | `rd = rs1 ^ rs2` |
| SRL | `101` | `0000000` | 逻辑右移 `rs2[4:0]` 位 |
| SRA | `101` | `0100000` | 算术右移 `rs2[4:0]` 位 |
| OR | `110` | `0000000` | `rd = rs1 \| rs2` |
| AND | `111` | `0000000` | `rd = rs1 & rs2` |

十条均已实现。ADD、ADDI、SUB 的溢出不会触发算术异常，只保留结果低 32 位，即模 `2^32` 回绕。

当前 decoder 若遇到 OP opcode 下未支持的 `{funct7,funct3}`，可能保留默认 ADD 控制并写 `rd`；例如本核未声明支持的 M 扩展 MUL 编码可能被误执行为 ADD。MUL 对实现了 M 扩展的处理器是合法指令，但对本项目计划采用的 RV32I-only 配置应进入 unsupported/illegal 处理，而不是悄悄执行成另一条指令。

### 5.7 FENCE、ECALL、EBREAK

| 指令 | opcode | funct3/固定字段 | `use1/use2` | ISA 语义 | 当前状态 |
|---|---|---|---:|---|---|
| FENCE | `0001111` | `funct3=000` | `0/0` | 按 pred/succ 约束外部可见内存与 I/O 顺序 | 未实现 |
| ECALL | `1110011` | `imm12=0, rs1=rd=0, funct3=000` | `0/0` | 向执行环境请求精确 trap | 未实现 |
| EBREAK | `1110011` | `imm12=1, rs1=rd=0, funct3=000` | `0/0` | 向调试环境请求精确 trap | 未实现 |

固定机器码：

```text
ECALL  = 0x00000073
EBREAK = 0x00100073
```

FENCE 的 I 型立即数字段细分为 `fm[31:28]`、`pred[27:24]`、`succ[23:20]`。基础 FENCE 的 `rs1` 和 `rd` 编码位是保留字段，并不表示读取或写入 GPR。规范要求基础实现忽略这些字段；多种保留的 `fm/pred/succ` 配置也应按规范保守地作为普通 FENCE 处理，而不能因为保留位非零就一律判 illegal。`FENCE.TSO` 是 FENCE 的特化编码，不另增加 RV32I 独立指令计数。

当前私有、顺序、无外部观察者的教学 RAM 环境中，忽略 FENCE 可能暂时表现得像 NOP，但不能宣称已经实现了完整 FENCE 语义。若 decoder 以后加入严格合法性判断，FENCE 必须作为具有自己合法性规则的特殊类别处理，不能机械套用 OP 指令的 funct7 匹配方式。

RV32I 一共是 40 条，而不是 37+若干伪指令：

```text
2 U + 2 Jump + 6 Branch + 5 Load + 3 Store
+ 9 OP-IMM + 10 OP + 1 FENCE + 2 Environment = 40
```

## 6. 每条指令的源操作数使用级

ISA 只规定指令语义，不规定 EX/MEM/WB 等流水级。下表区分当前 RTL 在 EX 锁存的候选值与真正产生功能副作用前的最终选择；寄存器堆物理读取发生在 ID，与这两个概念也不是一回事。当前 RTL 已加入 WB→MEM Store-data 晚旁路。

| 指令族 | `use1` | `rs1` 用途/当前需求 | `use2` | `rs2` 用途/EX 候选 | 最终选择 | rd 结果最早可用 | 数据 RAM/redirect |
|---|---:|---|---:|---|---|---|---|
| LUI | 0 | — | 0 | — | — | U-imm，EX 末 | — |
| AUIPC | 0 | —，另用本条 PC | 0 | — | — | PC+U-imm，EX 末 | — |
| JAL | 0 | —，另用本条 PC | 0 | — | — | link=PC+4，EX 末 | EX 无条件 redirect |
| JALR | 1 | 目标基址，EX | 0 | — | — | link=PC+4，EX 末 | EX 无条件 redirect |
| Branch | 1 | 比较，EX | 1 | 比较，EX | — | — | EX 条件 redirect |
| Load | 1 | 地址基址，EX | 0 | — | — | MEM→WB 边沿后的 WB 周期 | RAM 读 |
| Store | 1 | 地址基址，EX | 1 | 写数据，EX 选择并锁存 | **MEM 最终选择** | — | RAM 写 |
| OP-IMM | 1 | ALU 操作数，EX | 0 | — | — | ALU，EX 末 | — |
| OP | 1 | ALU 操作数，EX | 1 | ALU 操作数，EX | — | ALU，EX 末 | — |
| FENCE | 0 | — | 0 | — | — | — | 内存顺序屏障 |
| ECALL/EBREAK | 0 | — | 0 | — | — | — | trap redirect |

Load 数据在 MEM→WB 时钟边沿之后进入 RAM 输出，并在该 WB 周期内完成宽度选择与符号/零扩展；它不是等到 WB 周期末才可用。

Store.rs2 的 ISA 语义是“最终写入内存的数据”，而不是 ISA 规定它必须在哪一级读取。当前 RTL 在 EX 先选择并锁存 `S_type_src2_data`，在 MEM 写 RAM 前再检查同拍 WB 是否存在匹配的 Load 结果；匹配时由 WB 数据覆盖 EX 候选。因此纯 Load→Store-data 不再停顿，Store 地址相关仍需停一拍。

## 7. 冒险、旁路与 Store-data 晚旁路

### 7.1 当前结果何时可用

| 生产者 | 结果产生 | 紧邻消费者处理 |
|---|---|---|
| ALU/U/JAL/JALR link | EX 末 | 下一周期 MEM→EX 旁路，无需 stall |
| Load | MEM→WB 边沿后的 WB 周期，经 WB 组合逻辑格式化 | 若紧邻消费者在 EX 需要，停 1 拍后同一 WB 周期经 WB→EX 旁路 |

旁路匹配至少应满足：

```text
producer.valid && producer.reg_we && producer.rd != x0
&& consumer.use_rsN && producer.rd == consumer.rsN
```

Load-use stall 还必须确认生产者确实是尚未能提供结果的 Load。

### 7.2 不同 Load 相关的处理

| Load.rd 与紧邻下一条匹配的位置 | 值首次需要 | 旧实现 | 当前 RTL（WB→MEM） |
|---|---|---|---|
| 任意合法 `rs1` | EX | 1 stall | 仍 1 stall |
| OP/Branch 的 `rs2` | EX | 1 stall | 仍 1 stall |
| Store 的 `rs2`，且 `rs1` 不匹配 | MEM | 1 stall | 0 stall |
| Store 的 `rs1`，`rs2` 不匹配 | EX | 1 stall | 仍 1 stall |
| Store 的 `rs1`、`rs2` 都匹配 | 地址 EX、数据 MEM | 1 stall | 仍 1 stall，由地址决定 |
| 未使用原始字段碰巧相等 | 不消费 | `use_rs*` 后 0 | 0 |

### 7.3 三个必须分清的例子

```assembly
lw x5, 0(x0)
sw x5, 4(x0)       # 只依赖 Store 数据
```

- Store 确实 `use_rs2=1`；
- 不能为了少 stall 而把它伪装为 `use_rs2=0`；
- 有 WB→MEM 晚旁路后，Store 在 MEM 可以取得同拍 WB 的 x5，因此可以 0 stall。

```assembly
lw x5, 0(x0)
sw x1, 0(x5)       # 依赖 Store 地址
```

- `rs1=x5` 必须在 EX 计算地址；
- Load 数据当时尚未可用，所以仍必须停 1 拍。

```assembly
lw x5, 0(x0)
sw x5, 0(x5)       # 地址、数据双依赖
```

- 数据可以晚旁路；
- 地址不能晚到，因此整体仍停 1 拍。

实现 WB→MEM 晚旁路时，需要新增 WB→MEM 数据路径。MEM 写数据选择应要求：Store 有效、`memory_we=1`、WB 写回有效、`wb.rd!=0` 且 `wb.rd==store.rs2`。当前 `wb_ex_bus_t` 没有独立 `valid`，而是通过 `mem_wb_bus.valid` 门控后的 `we` 隐式表示有效；实现时可以继续使用这个已门控写使能，也可以增加显式 `valid`，但不能使用未经过 valid 门控的 `we`。Store 请求等待或级间寄存器保持时，还必须保证只写一次。

## 8. 分族易错点

### 8.1 算术、逻辑和比较

- ADD/ADDI/SUB 以模 `2^32` 回绕，不报告有符号溢出；
- SLT/SLTI、BLT/BGE 使用二补码有符号比较；
- SLTU/SLTIU、BLTU/BGEU 使用无符号比较；
- SLTIU 的立即数先符号扩展，再作为无符号值；
- SLL/SRL/SRA 只使用 `rs2[4:0]`；
- SLLI/SRLI/SRAI 的 `[24:20]` 是 shamt，不是 `rs2`；
- SRL/SRLI 左侧补 0，SRA/SRAI 左侧复制原符号位；
- 合法 opcode 不等于合法指令，必须完整检查 funct3/funct7。

### 8.2 U 型和构造常数

- LUI：直接得到 `{imm20,12'b0}`；
- AUIPC：加的是**本条 AUIPC 的 PC**，不是 `pc+4`；
- `li` 不是一条硬件指令，可能展开为 ADDI，也可能展开为 LUI+ADDI；
- 由于低 12 位 ADDI 会符号扩展，汇编器拆分 32 位常数时可能给高 20 位加 1，不能只机械切成上下两段。

### 8.3 Jump 和 Branch

- JAL：目标=`本条 PC + J_imm`，link=`本条 PC + 4`；
- JALR：目标=`(rs1 + sext(I_imm)) & ~1`，不是 PC 相对；
- JALR 是先相加，再清结果 bit 0；
- Branch 目标基于本条 Branch 的 PC；
- Branch 没有 rd，也没有条件码寄存器；
- RISC-V 没有架构可见 delay slot；taken redirect 后年轻指令必须被 flush；
- BGT/BLE 等通常由交换 BLT/BGE 操作数形成伪指令。

### 8.4 Load、Store、小端与对齐

当前 RAM 是小端：低地址对应数值的低字节。例如把 `0x11223344` 写到地址 0：

```text
addr 0 -> 0x44
addr 1 -> 0x33
addr 2 -> 0x22
addr 3 -> 0x11
```

自然对齐要求：

| 访问 | 自然对齐 |
|---|---|
| LB/LBU/SB | 任意字节地址 |
| LH/LHU/SH | `addr[0]=0` |
| LW/SW | `addr[1:0]=00` |

规范允许执行环境决定未对齐访问是被支持还是产生异常。当前 RTL 既没有未对齐 trap，也不能正确完成所有跨字访问，因此当前测试和软件必须只依赖自然对齐访问。

### 8.5 FENCE 和环境指令

- FENCE 约束其他 hart、设备或协处理器可观察到的内存/I/O顺序，不等同于简单“清空流水线”；
- `FENCE.I` 不在基础 RV32I 中；
- ECALL/EBREAK 应产生精确 trap，不是 NOP；
- 当前核尚未实现它们。

## 9. 当前 RTL 与标准 RV32I 的差异

当前核已具备 37 条普通计算、控制转移和访存指令的数据通路，但不能称为完整 RV32I，主要限制如下：

1. FENCE、ECALL、EBREAK 未实现；
2. 未知 opcode 当前近似成为有效、无普通副作用的 NOP；
3. 非法 JALR funct3 当前仍会写 link 并产生 redirect；
4. 非法 Load funct3 会发起 RAM 读并可能把默认值 0 写入 rd；非法 Store funct3 会拉高 `memory_we`，当前 RAM 的 case 可能不写，但未来外存或 MMIO 接口会有风险；
5. OP-IMM 的移位未严格检查完整 funct7；
6. OP 未命中合法 `{funct7,funct3}` 时，可能误用默认 ADD 并写 rd，例如 MUL 编码可能被当成 ADD；
7. 没有非法指令、指令地址错位、Load/Store 地址错位或访问异常；
8. ROM/RAM 只使用低地址索引，高地址会别名；
9. 当前 RTL 信号叫 `use_rs1/use_rs2`，项目文档旧措辞常写 `uses_rs1/uses_rs2`，后续宜统一命名。

RV32I 非特权规范把保留指令编码的行为留给平台/执行环境决定，并不无条件要求所有保留 opcode 都产生 illegal-instruction。为了让本项目行为可预测，同时防止未知编码静默产生副作用，建议为**本核支持的 ISA 配置**明确采用以下策略：

```text
默认：所有副作用关闭，legal=0
按照每个指令族自己的完整合法规则匹配：legal=1，并设置 use/写回/访存/redirect
不属于本核已声明支持集合的编码：保持无普通副作用，以 valid illegal 指令进入 trap
```

“每个指令族自己的规则”很重要：OP/OP-IMM 需要严格匹配 funct 字段；JALR、Branch、Load、Store 需要检查合法 funct3；FENCE 则必须遵守基础规范对其保留字段的忽略和兼容处理要求。

## 10. 手工读机器码的方法

### 10.1 通用步骤

1. 看 `[6:0]`，确定大类和格式；
2. 看 `funct3`，必要时再看 `funct7`；
3. 只按该格式解释 `rd/rs1/rs2`，不要无条件把固定位置都当寄存器；
4. 按 I/S/B/U/J 规则拼立即数并符号扩展；
5. 写出准确语义方程；
6. 标出 `use_rs1/use_rs2`；
7. 再问源值在哪一级需要、结果在哪一级产生，判断旁路或 stall。

### 10.2 例：`addi x6,x0,5`

```text
machine = 0x00500313
opcode  = 0010011 -> OP-IMM
funct3  = 000     -> ADDI
rd      = 00110   -> x6
rs1     = 00000   -> x0
imm12   = 000000000101 -> 5
```

所以：

```text
x6 = x0 + 5
use_rs1=1, use_rs2=0
```

原始 `[24:20]=00101` 是立即数的一部分，不能解释成 `rs2=x5`。

### 10.3 例：稳定自环

```assembly
jal x0, 0
```

机器码为：

```text
0x0000006f
```

它不读取 GPR，丢弃 link，并不断 redirect 回自身，适合作为定向测试程序的稳定结尾。

## 11. 常用伪指令

| 伪指令 | 真指令展开 |
|---|---|
| `nop` | `addi x0,x0,0` |
| `mv rd,rs` | `addi rd,rs,0` |
| `not rd,rs` | `xori rd,rs,-1` |
| `neg rd,rs` | `sub rd,x0,rs` |
| `seqz rd,rs` | `sltiu rd,rs,1` |
| `snez rd,rs` | `sltu rd,x0,rs` |
| `j label` | `jal x0,label` |
| `jr rs` | `jalr x0,0(rs)` |
| `ret` | `jalr x0,0(x1)` |
| `beqz rs,label` | `beq rs,x0,label` |
| `bnez rs,label` | `bne rs,x0,label` |

`li`、`la`、`call` 可能根据数值、地址、重定位方式展开成一条或多条指令，不能把它们记成固定的一条机器指令。

## 12. ABI 寄存器别名

这些名字是软件约定，只有 `x0=0` 是硬件 ISA 语义。

| 寄存器 | ABI 名 | 常见角色 |
|---|---|---|
| x0 | zero | 常数 0 |
| x1 | ra | 返回地址 |
| x2 | sp | 栈指针 |
| x3 | gp | 全局指针 |
| x4 | tp | 线程指针 |
| x5–x7 | t0–t2 | 临时寄存器 |
| x8 | s0/fp | 保存寄存器/帧指针 |
| x9 | s1 | 保存寄存器 |
| x10–x17 | a0–a7 | 参数/返回值 |
| x18–x27 | s2–s11 | 保存寄存器 |
| x28–x31 | t3–t6 | 临时寄存器 |

## 13. 当前归档测试对应的知识点

| 知识点 | 归档测试 |
|---|---|
| 基础 ALU、LUI、AUIPC | Test 06 |
| 六种 Branch、有/无符号比较 | Test 05、07 |
| JAL/JALR、link、目标低位 | Test 03、09 |
| Load/Store 宽度与符号扩展 | Test 04、12 |
| 小端 byte lane、SB/SH | Test 08、12 |
| 最新值旁路优先级 | Test 10 |
| 同步 RAM 与 Load-use | Test 11、12 |
| taken redirect 与错误路径副作用抑制 | Test 02、03、07、09、10、11、12 |

## 14. 主动回忆清单

不看上文，尝试回答：

1. 为什么 I 型 `[24:20]` 不能无条件当 `rs2`？
2. 为什么 Store 必须 `use_rs2=1`，但纯 Load→Store-data 依赖仍可能不 stall？
3. `sw x5,12(x6)` 中谁是地址基址，谁是写数据？它们分别在哪一级首次需要？
4. SLTIU 的立即数在无符号比较前怎样扩展？
5. SRA 和 SRL 的区别是什么？寄存器移位量使用几位？
6. AUIPC 使用本条 PC 还是 `pc+4`？
7. JALR 的目标怎样计算？为什么清 bit 0 后仍可能不满足当前核的 4 字节对齐？
8. LB/LBU、LH/LHU 的区别是什么？
9. 为什么 `rd=x0` 应排除 RAW 生产者，但 `lw x0,...` 仍不能跳过访存？
10. 为什么只判断 opcode 不能完成严格合法译码？
11. FENCE、FENCE.I 和 CSR 指令分别属于什么范围？
12. 当前同步 RAM 下，ALU→ALU 为什么不 stall，而 Load→ALU 要停一拍？

能稳定回答这些问题，就已经具备继续设计 decoder、hazard、晚旁路和精确异常所需的 RV32I 指令基础。
