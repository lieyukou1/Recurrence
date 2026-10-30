# CATALOG — 论文总索引

> 本工作区所有论文的**唯一总入口**。当论文变多、无法靠记忆检索时，从这里找。
>
> **更新规则**（详见 [AGENTS.md](./AGENTS.md) §4）：
> 1. 论文**开工时**，先在下方「待归类（阅读中）」登记一行（占位）。
> 2. AI 把论文**读明白、产出该论文目录下的 `OUTLINE.md` 之后**，再按**唯一主分类**归位到对应表格，并补全条目。
> 3. **禁止未读先分类**；分类拿不准就先留在「待归类」。
>
> **状态图例**：`计划中` → `阅读中` → `已精读` → `复现中` → `已复现` → `已归档`
>
> **主分类**（唯一，8 选 1）：模型与架构 / 训练与对齐 / 推理与加速 / Agent 与应用 / 多模态与生成 / 系统与基础设施 / 理论与可解释性 / 数据与评测
> **标签**：小写英文、连字符分词、单数形式，逗号分隔，仅用于横向检索；**优先从 [AGENTS.md](./AGENTS.md) §4.1 的受控词表取词**。
>
> 条目格式：`开工日 | 论文（链接目录与提纲） | 一句话结论 | 状态 | 标签`

---

## 待归类（阅读中）

> 已开工但尚未读明白、未定主分类的论文先放这里。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
| <!-- 示例：20261013 | [Attention Is All You Need](./20261013-Attention-Is-All-You-Need/) · [提纲](./20261013-Attention-Is-All-You-Need/OUTLINE.md) | 提出纯注意力 Transformer，抛弃循环与卷积 | 已精读 | transformer, attention | --> |  |  |  |  |

---

## 1. 模型与架构

> 新模型、网络结构、预训练范式。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

---

## 2. 训练与对齐

> 训练目标、数据、微调、RLHF/对齐。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

---

## 3. 推理与加速

> 量化、蒸馏、KV cache、并行、编译、serving。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

---

## 4. Agent 与应用

> Agent 框架、工具调用、多智能体、RAG、工作流。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
| 20261013 | [VISTA: A Visual Harness for Reasoning in an Interactive World](./20261013-VISTA-A-Visual-Harness-for-Reasoning-in-an-Interactive-World/) · [提纲](./20261013-VISTA-A-Visual-Harness-for-Reasoning-in-an-Interactive-World/OUTLINE.md) | 视觉原生 agent harness（原图观测+无损视觉记忆+主动视觉检查），把多模态模型既有推理能力释放，ARC-AGI-3 上 RHAE 达满分 100 | 已精读 | multimodal, agent, visual-harness, long-horizon-memory, arc-agi-3 |
| 20261014 | [MemMA: Coordinating the Memory Cycle through Multi-Agent Reasoning and In-Situ Self-Evolution](./20261014-MemMA-Coordinating-the-Memory-Cycle/) · [提纲](./20261014-MemMA-Coordinating-the-Memory-Cycle/OUTLINE.md) | 把长期记忆看成"构建→检索→使用"闭环：前向由 Meta-Thinker 统筹记忆编辑与检索改写，后向在记忆提交前用自演化探针 QA 修错；不改存储后端，LoCoMo ACC 75.66→81.58、LongMemEval-S 82.0→94.0 | 已精读 · **最小验证未通过**（Table 1 三档台阶未复现：实测 ACC 6.58/3.95/5.92 vs 论文 52.60/54.60/59.21，非单调且差约 10 倍；根因未归因） | agent, memory, multi-agent, long-horizon-memory |

---

## 5. 多模态与生成

> 视觉/语音/视频、扩散、生成模型。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

---

## 6. 系统与基础设施

> 分布式、存储、调度、硬件、工程。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

---

## 7. 理论与可解释性

> 理论分析、缩放律、可解释性。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

---

## 8. 数据与评测

> 数据集、基准（benchmark）、评估方法、eval harness。

| 开工日 | 论文 | 一句话结论 | 状态 | 标签 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |