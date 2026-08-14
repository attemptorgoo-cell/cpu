# 文档导航

本目录保存跨对话需要延续的项目信息。文档记录结论和决策，不复制完整聊天过程、冗长仿真输出或临时推理。

## 新对话的最小阅读顺序

1. 根目录 `AGENTS.md`：协作边界与测试归档规则。
2. `md/STATUS.md`：已经完成什么、现在停在哪里、下一步是什么。
3. 按任务读取下表中的相关文档。

除非需要追溯某项决策，否则不必阅读全部每日记录。

## 统括文档

| 文件 | 内容 | 何时更新 |
|---|---|---|
| [PROJECT.md](PROJECT.md) | 项目定位、目标与范围 | 项目方向改变时 |
| [STATUS.md](STATUS.md) | 当前可信基线、限制、下一步 | 每个工作日结束或里程碑完成时 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 当前 RTL 结构、控制和数据通路 | RTL 架构改变时 |
| [RV32I_INSTRUCTIONS.md](RV32I_INSTRUCTIONS.md) | RV32I 编码、语义、源操作数使用级与当前实现矩阵 | ISA 覆盖或相关微架构契约改变时 |
| [ROADMAP.md](ROADMAP.md) | 近期任务和长期阶段 | 优先级或阶段改变时 |
| [XIANGSHAN.md](XIANGSHAN.md) | 当前小核到香山的机制映射 | 开始或完成一个新机制时 |
| [WORKFLOW.md](WORKFLOW.md) | 每日对话、验证和归档方法 | 工作方式改变时 |
| [daily/](daily/README.md) | 按日期保存的简短工作记录 | 每个实际工作日结束时 |

旧版单文件交接说明保存在 [archive/HANDOFF-2026-08-12.md](archive/HANDOFF-2026-08-12.md)，仅用于追溯，不代表当前状态，也不应在新对话中默认读取。

## 信息的权威来源

- 协作规则：根目录 `AGENTS.md`
- 当前进度：`md/STATUS.md`
- RTL 事实：当前 `.sv` 文件
- 已验证行为：`vFile/verilog/verilog/tests/` 中完整的 `.hex`、`.svh` 和 `README.md` 三件套
- 某日发生过什么：`md/daily/YYYY-MM-DD.md`

若文档与代码冲突，以代码和最新 Vivado 证据为准，并及时修正文档。
