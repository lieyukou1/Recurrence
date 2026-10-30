# 提纲 · MemMA: Coordinating the Memory Cycle through Multi-Agent Reasoning and In-Situ Self-Evolution

> 本文件是该论文的**浓缩提纲（"户口页"）**：短小、可直接用于快速回顾，也是根目录 [CATALOG.md](../CATALOG.md) 条目的取材来源。
> 详细精读见 [reading/summary.md](./reading/summary.md)。

| 项 | 内容 |
| --- | --- |
| 主分类 | Agent 与应用 |
| 标签 | agent, memory, multi-agent, long-horizon-memory |
| 来源 | [2603.18718](https://arxiv.org/abs/2603.18718) · [代码](https://github.com/ventr1c/memma) |
| 开工日 | 20261014 |

## 一句话结论

把长期记忆从"构建 / 检索 / 使用"三个孤立子程序重新看成一个**需要前后向共同调度的闭环**：前向用 Meta-Thinker 统筹记忆编辑与检索改写，后向在记忆**提交前**就地合成探针 QA 验证并修复；不改存储后端，即可把 LoCoMo ACC 从 75.66 提到 **81.58**、LongMemEval-S 从 82.0 提到 **94.0**。

## 核心贡献

1. **提出 memory cycle effect 的问题框架**（§3.2）：显式拆出两条依赖——前向（construction 约束 retrieval 约束 utilization）与后向（utilization 的失败信号稀疏且延迟），并归纳为两个挑战：**strategic blindness**（Myopic Construction + Aimless Retrieval）与 **sparse and delayed feedback**。
2. **前向路径 Reasoning-Aware Coordination**（§4.1）：planner-worker 架构，Meta-Thinker 只做战略推理（该存什么、缺什么、何时停），Memory Manager / Query Reasoner 只做低层执行，用战略目标指挥局部动作。
3. **后向路径 In-Situ Self-Evolving Memory Construction**（§4.2）：每个 session 结束即合成 J=5 个探针 QA、就地验证、证据锚定修复、语义整合（SKIP/MERGE/INSERT），把延迟的终局信号改造成立即的局部监督信号。
4. **存储后端无关（backend-agnostic）**：可包在 LightMem / A-Mem / Single-Agent 外层，三种后端上都涨（§5.3）。
5. **过程级证据**（Table 4）：construct gap closure 达 **59/64 = 92.2%**，直接验证"上游修错"确实发生。

## 方法一句话

不改存储、不训练任何参数——只用 **Meta-Thinker 统筹四个角色的 LLM 调用** 做前向规划，并在记忆定稿前用 **自演化探针 QA** 做后向修错，把记忆当成一个需要协同的闭环来管。

## 关键结果

- **LoCoMo**（GPT-4o-mini 后端）：ACC 75.66 → **81.58**；Multi-Hop ACC 65.62 → **78.12**。
- **泛化**：LongMemEval-S 82.0 → **94.0**；SWE-bench-Verified-mini Pass Rate 62.0 → **76.0**（当"轨迹记忆控制器"）。
- **消融**：迭代检索 MemMA/R 跌幅最大（84.87 → 70.39）> 探针修复 MemMA/E（→ 73.68）> 构造指导 MemMA/C（→ 83.55）。
- **探针生成模型敏感**（§G）：只换探针模型，ACC 从 74.34 变到 76.97 —— 探针**风格**（而非模型强弱）决定修复质量。

## 复现价值

- 复现状态：**最小验证已执行（20261015）· 未通过**
- 复现价值级别：**中** —— 机制清晰、**无 GPU 门槛**（不训练任何参数，四角色 + 探针 + 判定全是 LLM 调用，纯 CPU 可跑），可做**最小验证**；但完整复现需四类模型调用（含 Claude-Opus-4.5 当探针生成器）、LoCoMo 单条历史约 115K token 级，有 API 成本与额度约束，不适合追求逐位复刻。
- 值不值得复现：值得，但只做**最小验证**——先只跑 **Table 1 的动机性预实验**（Static / Unguided Active / Strategic Active 三档，看能否复现 `52.60 → 54.60 → 59.21` 这个单调台阶）。这是全文成本最低、信息量最高的实验；**台阶复现不出来，后面都不用做**。详见 [reproduction/README.md](./reproduction/README.md)。
- **执行结果（20261015）**：台阶**未复现**——实测 ACC 为 6.58% / 3.95% / 5.92%（论文 52.60 / 54.60 / 59.21），**非单调**且**绝对值差约 10 倍**。按事前判据**终止后续复现**。**根因未完成归因**：候选包括 (a) 构造期 Meta 指导 95% 为空（已确证）、(b) 后端模型由 GPT-4o-mini 换为 `deepseek-flash`、(c) 记忆库规模/质量差异；**现有数据不足以区分**。