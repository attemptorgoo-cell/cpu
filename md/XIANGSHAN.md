# 从当前小核理解香山

本文件记录机制映射，不表示当前 RTL 要一对一改名或扩建成香山。

## 结构映射

| 当前五级核 | 香山中的扩展方向 | 新问题 |
|---|---|---|
| `IF.sv` 和 EX redirect | Frontend、BPU、FTQ、ICache、ITLB、IBuffer | 宽取指、预测上下文、可变延迟和恢复 |
| `decoder.sv` 与架构寄存器堆 | Decode、Rename、RAT、Free List、PRF | 消除 WAR/WAW，保存推测版本 |
| 全局 stall 和固定旁路 | Dispatch、Issue Queue、busy table、wakeup/select | 让就绪指令越过未就绪指令 |
| `EX.sv` | 多执行块、写回网络、仲裁 | 不同延迟的多条指令并行执行 |
| redirect 后清两级 | FTQ/ROB/Rename checkpoint 和各队列 flush | 恢复更深、更宽的推测状态 |
| `MEM.sv` 与同步 RAM | LSU、LQ/SQ、DTLB、DCache、MSHR、replay | 翻译、依赖、miss、转发和重放 |
| `WB.sv` 直接写架构寄存器 | PRF 写回、ROB 完成、Commit | 区分执行完成、写回和软件可见 |
| 固定 packed struct | 参数化 Bundle、Decoupled、Diplomacy | 局部回压、不同宽度和配置生成 |

## 四条事件主线

### 普通整数指令

```text
C/ELF -> 机器码 -> 取指 -> 译码 -> Rename -> Dispatch
-> Issue -> Execute -> Writeback -> ROB -> Commit
```

### 分支误预测

```text
BPU 预测 -> FTQ 保存上下文 -> 错误路径流动
-> 执行发现错误 -> redirect 仲裁
-> Frontend/Backend flush -> Rename/ROB 恢复
-> 从正确 PC 重启并更新预测器
```

当前核的 EX redirect 和清空两条年轻指令是最小、非预测原型。

### Load miss 或 replay

```text
AGU -> 地址翻译 -> LQ/SQ 依赖检查 -> DCache
-> hit / miss / forwarding / replay
-> 写回并唤醒消费者 -> ROB 完成 -> Commit
```

当前一拍 Load-use stall只描述固定延迟同步 RAM，不能解释 Cache miss。

### 精确异常

```text
某级发现异常 -> 记录到指令/ROB 项
-> 年轻指令不能提交 -> 异常指令到 ROB 头
-> 更新 CSR、选择向量、redirect -> 清除推测状态
```

当前核尚无这条语义边界。

## 进入香山源码后的纪律

- 以 `kunminghu-v3` 为主要目标，并固定具体 commit、配置和工具版本。
- `nanhu` 只用于历史和概念对照，不把其文件名直接当作新版本事实。
- 不从源码第一行顺序阅读；从一条指令或一个事件路径进入。
- 每个模块只记录职责、父子关系、接口、关键状态、阻塞来源、恢复来源、配置参数和一条动态证据。
- 所有具体宽度、深度和实例必须回到固定源码与配置验证。

当前仓库尚未 checkout 或构建香山源码。
