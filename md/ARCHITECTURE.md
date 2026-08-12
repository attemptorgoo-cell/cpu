# 当前 RTL 架构

Updated: 2026-08-12

## 总体数据流

```text
IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
```

四组 packed struct 流水总线定义在 `package.sv`，顶层寄存器和各级实例位于 `cpu.sv`。指令以 `valid` 表示有效或气泡；这不是模块间的 ready/valid 握手。

## 模块职责

| 文件 | 当前职责 |
|---|---|
| `cpu.sv` | 实例化五级流水，保存四组级间寄存器，产生 Load-use stall，处理 flush/stall/advance |
| `IF.sv` | PC、内部指令 ROM、顺序取指、redirect 和 stall hold |
| `ID.sv` | 组合译码、寄存器堆读取、形成 ID/EX 组合总线 |
| `decoder.sv` | RV32I 主体整数、分支、跳转和访存译码 |
| `EX.sv` | ALU、分支/JAL/JALR 解析、MEM/WB 到 EX 的旁路 |
| `MEM.sv` | 数据 RAM 地址与写数据，普通 ALU 结果的 MEM 到 EX 旁路，同步读数据送往 WB |
| `ram.sv` | 1024×32 内部 RAM，同步读、同步写、SB/SH/SW lane 写入 |
| `WB.sv` | Load 对齐及符号/零扩展，Load/ALU 结果选择，寄存器堆写回和 WB 到 EX 旁路 |
| `regFiles.sv` | 2 读 1 写寄存器堆、x0 保护、WB 同拍 read-through |
| `test.sv` | 当前活动程序的自检 testbench |

## 冒险处理

数据相关主要依靠：

```text
MEM -> EX forwarding       普通 ALU 结果
WB  -> EX forwarding       ALU 和同步 RAM Load 结果
WB  -> ID read-through     同拍写回与译码读取
```

同步读 RAM 的紧邻 Load-use 过程为：

```text
周期 T:   Load 在 EX，消费者在 ID，检测到相关
周期 T+1: Load 进入 MEM，ID/EX 插入 bubble，消费者与 PC 保持
周期 T+2: Load 在 WB，消费者进入 EX，经 WB->EX 取得结果
```

当前 stall 比较 ID 指令的 `rs1/rs2` 与 EX 中有效 Load 的 `rd`，并排除 `rd=x0`。下一项改进是由 decoder 提供 `uses_rs1/uses_rs2`，避免把未实际使用的指令字段误认为依赖。

## 控制相关

分支和 JAL/JALR 在 EX 解析。redirect 后清空 IF/ID 和 ID/EX 两条年轻指令，旧指令继续排空。IF 控制采用 redirect、stall、正常前进的互斥优先级。

Load-use stall 时：

- PC 和 IF 输出保持；
- IF/ID 保持消费者；
- ID/EX 注入无效 bubble；
- Load 正常进入 EX/MEM；
- MEM/WB 正常前进。

## 存储器模型

- 指令 ROM：IF 内部 1024 个 32 位字，通过 `pc[11:2]` 索引。
- 数据 RAM：MEM 内部 1024 个 32 位字，同步读写。
- 地址高位不会产生异常，未对齐访问也没有 trap。
- 当前没有请求/响应、等待状态、Cache 或外部总线协议。
- IF 的 `$readmemh` 仍使用本机绝对路径，工程可移植性尚待处理。

## 可见清理项

- `cpuOutput` 顶层端口尚未驱动。
- 尚无 `uses_rs1/uses_rs2` 精确源寄存器元数据。
- 尚无非法指令、异常、CSR、中断和对齐检查。
- 当前 Test 12 是活动综合回归，具体内容见测试目录的 README。
