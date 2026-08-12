# RV32I 五级流水线 CPU

这是一个使用 SystemVerilog 编写的单发射、顺序执行 RV32I 五级流水线实验核。当前基线已经完成同步读 RAM、一周期 Load-use stall、数据旁路、跳转冲刷以及自检式定向测试。

## 文档入口

- [文档导航](md/README.md)
- [当前状态](md/STATUS.md)
- [近期路线](md/ROADMAP.md)
- [RTL 架构](md/ARCHITECTURE.md)
- [每日记录](md/daily/README.md)
- [测试归档](vFile/verilog/verilog/tests/README.md)

开始一次新的协作对话时，先阅读 `AGENTS.md`、`md/README.md` 和 `md/STATUS.md`。一般不需要读取全部历史日志。

## 主要目录

```text
.
|-- AGENTS.md                         协作与测试维护规则
|-- md/                               项目文档与每日交接
`-- vFile/verilog/verilog/            RTL、活动程序和 testbench
    |-- cpu.sv                        CPU 顶层
    |-- IF.sv ... WB.sv              五级流水模块
    |-- inst_data.hex                 当前活动测试程序
    |-- test.sv                       当前活动自检
    `-- tests/                        已通过测试的归档
```

## Git 提交

```powershell
git status
git add .
git commit -m "描述本次修改"
git push origin main
```

如需代理，请按本机代理端口单独配置，不在仓库中保存个人环境配置。
