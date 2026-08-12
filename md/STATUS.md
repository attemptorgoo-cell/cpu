# 当前状态

Updated: 2026-08-12

## 一句话状态

同步读 RAM 与一周期 Load-use stall 已完成；Test 11 专项测试和 Test 12 综合回归均在 Vivado 通过并完整归档。

## 已完成的可信基线

- 单发射、顺序执行、五级 RV32I 主体整数流水线。
- valid/bubble、EX redirect、错误路径 flush。
- MEM/WB 到 EX 的数据旁路，以及 WB 到 ID 的 read-through。
- 同步读数据 RAM。
- Load-use 检测：保持 PC/IF/ID、向 ID/EX 注入一拍 bubble。
- LW/LB/LBU/LH/LHU 与 SW/SB/SH。
- JAL/JALR 和六种条件分支。
- 12 组定向测试已经归档；当前活动 Test 12 是存储与 Load-use 综合回归。

最新证据：Test 12 全部架构状态检查通过，并观察到精确的 10 次一周期 Load-use stall。

## 当前测试入口

- 活动机器码：`vFile/verilog/verilog/inst_data.hex`
- 活动自检：`vFile/verilog/verilog/test.sv`
- 测试清单：`vFile/verilog/verilog/tests/README.md`
- 最新专项归档：Test 11
- 最新综合归档：Test 12

当前环境没有可直接调用的 Vivado、XSim、Icarus Verilog 或 Verilator；最终动态验证由用户在 Vivado 完成。

## 下一步

近期只做一个小闭环：

1. decoder 产生 `uses_rs1` 和 `uses_rs2`。
2. Load-use 检测只比较指令真正使用的源寄存器。
3. 增加“字段相等但不是依赖”的假 stall 测试。
4. 运行该专项测试和当前 Test 12 综合回归。

## 已知限制

- 当前 stall 仍可能因未使用的 `rs1/rs2` 位域产生假停顿。
- 没有一键运行全部归档测试的脚本。
- 测试程序仍通过 IF 中的绝对路径加载。
- 没有外部内存接口、Cache、异常、CSR、中断或对齐异常。
- RAM 与 ROM 只有 4 KiB 索引窗口，高地址可能产生别名。

## 新对话交接语句

可以直接说：

> 继续 CPU 项目。先读 AGENTS.md、md/README.md 和 md/STATUS.md；今天继续 uses_rs1/uses_rs2 与假 stall 测试。

如果任务不是近期工作，再按 `md/README.md` 的导航读取相应统括文档。
