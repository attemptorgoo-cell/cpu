# 协作与记录流程

## 每天开始

建议每天新开一个对话。新对话只需先读取：

1. `AGENTS.md`
2. `md/README.md`
3. `md/STATUS.md`

随后只读取当天任务需要的统括文档和代码。不要默认加载全部历史日志。

## 工作中

- 用户亲手写关键 RTL；Codex 优先解释时序、审查代码并承担验证资产维护。
- 开始修改前查看 `git status` 和相关 diff，保留用户未提交内容。
- 一个测试聚焦一个新行为；大改后再运行一份综合回归。
- Vivado 日志在对话中只需概括为“测试名、通过/失败、关键计数”。完整终端输出不写入每日记录。

## 当前 Vivado 仿真方式

当前阶段优先使用 Vivado GUI 的 **Run Behavioral Simulation**：

```text
点击 Run Behavioral Simulation
-> Vivado 编译 SystemVerilog
-> elaboration 建立 test 顶层模型
-> 启动 XSim
-> test.sv 自动检查寄存器、RAM 和 stall
-> 控制台打印 PASS/FAIL
```

对于“一个活动测试、点击一次即可得到自检结果”的当前工作流，GUI 已经足够直接，不要求额外使用 Tcl。Tcl 自动化推迟到确实需要以下能力时再做：

- 一次自动运行 Test 01–16 等多组归档测试；
- 避免反复替换 hex 和预期检查；
- 在命令行或 CI 中无人值守运行；
- 让另一台电脑复现同一批处理流程。

Tcl 负责自动组织测试流程，不替代 `test.sv` 中的功能检查。

## 测试完成

测试归档的具体约束以根目录 `AGENTS.md` 为准。简化流程为：

```text
生成活动 .hex 和 test.sv 检查
-> 用户在 Vivado 运行
-> 通过
-> 归档同名 .hex + .svh + tests/README 条目
-> 更新 md/STATUS.md
```

只有三件套齐全才算归档完成。

## 每天结束

1. 新建或更新 `md/daily/YYYY-MM-DD.md`。
2. 只记录今日完成、验证、关键决定、未解决问题和明日第一步。
3. 更新 `md/STATUS.md`，使它成为新对话的当前事实入口。
4. 若优先级改变，再更新 `md/ROADMAP.md`。
5. 提交前运行 `git status`，确认 RTL、活动测试和归档文件都在预期范围内。

## Git 上传与本机代理

```powershell
git status
git add -A
git commit -m "描述本次修改"
git push origin main
```

当前机器曾使用以下本地代理配置；只有代理实际监听相同端口时才需要设置：

```powershell
git config --global http.proxy http://127.0.0.1:10090
git config --global https.proxy http://127.0.0.1:10090
```

每日记录应短小。推荐格式：

```markdown
# YYYY-MM-DD

## 今日完成
- ...

## 验证
- Test N：通过，关键计数 ...

## 决定
- ...

## 明日第一步
- ...
```

## 文档维护原则

- `STATUS.md` 只保留现在，不累积历史。
- `daily/` 只保留当天摘要，不复制设计长文。
- 架构稳定知识写入 `ARCHITECTURE.md`。
- 优先级和阶段写入 `ROADMAP.md`。
- 测试的汇编和期望状态只在测试 README 中维护一份。
