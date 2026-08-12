# 项目路线

Updated: 2026-08-12

## 近期队列

1. 用 `uses_rs1/uses_rs2` 消除 Load-use 假 stall，并做专项验证。
2. 写一个可重复运行 Vivado/XSim 测试的 Tcl 流程，减少手工替换和漏测。
3. 清理指令文件绝对路径、未驱动端口和冗余总线字段。
4. 决定下一项架构实验：请求/响应式内存边界，或最小异常/CSR/trap 流程。

一次只推进一个能够“实现—测试—归档”的小闭环。

## 里程碑

### M1：可信 RV32I 顺序核基线（当前）

- [x] valid、flush、forwarding
- [x] 同步读 RAM
- [x] 一周期 Load-use stall
- [x] Test 01–12 定向测试归档
- [ ] 精确源寄存器使用信息
- [ ] 自动化综合回归
- [ ] 可移植的仿真入口

### M2：软件可见的 RISC-V 模型

- RV32I 规范完整性和非法指令处理
- 对齐异常、CSR、异常、中断和最小 trap 流程
- C/ELF/ABI 到机器码的完整路径
- 再讨论 RV64I、M/A/C、特权级与虚拟内存

### M3：高性能机制的小型实验

```text
性能计数/CPI
-> Cache 与可变延迟
-> 分支预测
-> Rename / RAT / Free List / PRF
-> Dispatch / Issue / wakeup-select
-> ROB / Commit / 精确异常
-> LQ / SQ / forwarding / replay
```

### M4：香山表达语言与工程基础

- Scala/Chisel 硬件语义
- Decoupled、Queue 和随机 backpressure
- FIRRTL 与生成 RTL
- LazyModule、Diplomacy 和 TileLink

### M5：固定版本的香山源码

- 在 Linux/WSL 固定 `kunminghu-v3` commit 和配置
- 完成官方构建、最小镜像和 Difftest
- 建立 System/Tile/Core 到 Frontend/Backend/MemBlock 的源码地图

### M6：事件路径追踪与低风险修改

- 标量 ALU、分支 redirect、Load hit/replay、DCache miss、Store commit、精确异常
- 保存源码位置、关键周期、信号、日志或波形证据
- 完成 assertion、日志或性能计数器等低风险修改并回归

## 阶段原则

- 不把当前五个流水模块机械扩建成香山结构。
- 不在未固定 commit 和配置前断言香山的具体类名、宽度或队列深度。
- 固定延迟 stall 不能替代未来 Cache miss 所需的请求/响应和 replay。
- 每个阶段必须留下代码、测试或动态证据，不能只留下概念笔记。
