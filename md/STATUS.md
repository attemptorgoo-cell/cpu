# 当前状态

Updated: 2026-08-16

## 一句话状态

decoder 已显式产生 `use_rs1/use_rs2`；Load-use 检测区分 EX 需要的源与 Store 写数据，并通过 WB→MEM 晚旁路消除了纯 `Load.rd -> Store.rs2` 停顿。Test 14–16 均在 Vivado 通过。

## 已完成的可信基线

- 单发射、顺序执行、五级 RV32I 主体整数流水线。
- valid/bubble、EX redirect、错误路径 flush。
- MEM/WB 到 EX 的数据旁路、WB 到 ID 的 read-through，以及 Load 数据的 WB→MEM Store-data 晚旁路。
- 同步读数据 RAM。
- Load-use 检测：EX 消费者相关时保持 PC/IF/ID、向 ID/EX 注入一拍 bubble；纯 Store.rs2 相关不再停顿。
- decoder 产生 `use_rs1/use_rs2`，并随 ID/EX 总线进入顶层 hazard 判断。
- LW/LB/LBU/LH/LHU 与 SW/SB/SH。
- JAL/JALR 和六种条件分支。
- 16 组定向测试已经归档；当前活动程序是已再次通过的 Test 16 post-forwarding Load/Store 综合回归。

最新证据：Test 14 通过，精确产生 2 次地址依赖 stall 和 6 次 Store commit；Test 15 的非匹配非零值与匹配零值边界均通过，0 stall、4 次 Store commit；Test 16 再次通过，保持 Test 12 的全部寄存器/RAM 结果，并将 stall 从 10 次精确降为 9 次。

## 当前测试入口

- 活动机器码：`vFile/verilog/verilog/inst_data.hex`
- 活动自检：`vFile/verilog/verilog/test.sv`
- 测试清单：`vFile/verilog/verilog/tests/README.md`
- 最新专项归档：Test 15
- 最新综合归档：Test 16

当前环境没有可直接调用的 Vivado、XSim、Icarus Verilog 或 Verilator；最终动态验证由用户在 Vivado 完成。

## 下一步

先做一个不改变架构语义的工程清理小闭环：去掉 IF 中的本机绝对指令路径，处理未驱动的 `cpuOutput`，并审查已不需要或命名范围过窄的总线字段。完成后再从“请求/响应式数据内存边界”和“最小精确异常/trap”中选择下一项架构实验。

## 已知限制

- 还没有一键运行全部归档测试的脚本；当前仓库中也没有找到已纳入版本控制的 `test.tcl` 或 Vivado `.xpr`。
- 测试程序仍通过 IF 中的绝对路径加载。
- 没有外部内存接口、Cache、异常、CSR、中断或对齐异常。
- RAM 与 ROM 只有 4 KiB 索引窗口，高地址可能产生别名。

## 新对话交接语句

可以直接说：

> 继续 CPU 项目。先读 AGENTS.md、md/README.md 和 md/STATUS.md；use_rs 与 WB→MEM Store-data 晚旁路已完成，今天先做可移植性和接口清理。

如果任务不是近期工作，再按 `md/README.md` 的导航读取相应统括文档。
