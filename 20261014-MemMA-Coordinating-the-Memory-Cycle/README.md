# MemMA: Coordinating the Memory Cycle through Multi-Agent Reasoning and In-Situ Self-Evolution

> 论文索引卡片 · 开工日 20261014 · 目录 `20261014-MemMA-Coordinating-the-Memory-Cycle`

## 速览

| 项 | 内容 |
| --- | --- |
| 标题 | MemMA: Coordinating the Memory Cycle through Multi-Agent Reasoning and In-Situ Self-Evolution |
| 作者 | Minhua Lin, Zhiwei Zhang, Hanqing Lu, Hui Liu, Xianfeng Tang, Qi He, Xiang Zhang, Suhang Wang（Penn State / Amazon / Microsoft） |
| 来源 | [arXiv 2603.18718v2](https://arxiv.org/abs/2603.18718) · [代码](https://github.com/ventr1c/memma) |
| 年份 / 会议 | 2026 · arXiv preprint (cs.AI) |
| 主题标签 | agent, memory, multi-agent, long-horizon-memory |

## 进度

- [x] 原文 PDF 就位（`paper/original.pdf`）
- [x] 元数据填写（`paper/metadata.yaml`）
- [x] PDF 渲染页面图（`paper/extracted/pages/`，24 页）
- [x] 多模态精读（`reading/summary.md`）
- [x] 全文翻译（`reading/translation.md`）
- [x] 公式整理（`reading/formulas.md`）
- [x] 图表存档（`reading/figures/`，4 张）
- [x] 浓缩提纲（`OUTLINE.md`）
- [x] 登记总索引（根目录 `CATALOG.md`）
- [x] 复现价值评估（`OUTLINE.md` / `reproduction/README.md`）——定为 **中**
- [x] 隔离环境建立（`reproduction/env/`，venv + 冻结清单）
- [x] 复现跑通并记录（`reproduction/`）——**最小验证未通过**（见下）

## 复现结果（20261015）

管线端到端跑通（两库构建 + 三档各 152 QA，共约 23.3 元 API 额度），但**论文的三档单调台阶未复现**：

| 档 | 实测 ACC | 论文 ACC |
| --- | --- | --- |
| Static | 6.58% | 52.60 |
| Unguided Active | 3.95% | 54.60 |
| Strategic Active | 5.92% | 59.21 |

- 论文单调 **+6.61**，实测**非单调**（全距仅 2.63），且**绝对值差约 10 倍**。
- 依事前判据「台阶复现不出来，后面都不用做」→ **不进入 Table 2/3、Fig.3 等后续复现**。
- **根因未完成归因**，至少三个候选未排除：(a) 构造期 Meta 指导 **95% 为空**（已确证）；(b) 后端模型不同（论文 GPT-4o-mini vs 本复现 `deepseek-flash`）；(c) 记忆库规模/质量与论文不一致。
- **口径标注（20261015 裁定）**：对 (a) **仅标注、不重建** —— 本复现的 Strategic 档记为"查询侧指导生效、构造侧指导缺席"，**不等于**论文意义的 Strategic Active；结论读作"在构造侧指导缺席的部署下台阶未出现"，非对方法的否证。
- 详录：[runs/20261015-1756-three-tier-eval.md](./reproduction/runs/20261015-1756-three-tier-eval.md)

## 一句话结论

把长期记忆从"构建 / 检索 / 使用"三个孤立子程序重新看成一个**需要前后向共同调度的闭环**——前向由 Meta-Thinker 统筹记忆编辑与检索改写，后向在记忆**提交前**就地合成探针 QA 验证并修复；不改存储后端，LoCoMo ACC 75.66 → **81.58**、LongMemEval-S 82.0 → **94.0**。机制清晰、无 GPU 门槛，定级 **中**，走最小验证（先复现 Table 1 的 `52.60 → 54.60 → 59.21` 台阶）。

## 相关链接

- 原文：<https://arxiv.org/abs/2603.18718>
- 代码仓库：<https://github.com/ventr1c/memma>
- 其他：详见 [OUTLINE.md](./OUTLINE.md) 与 [reading/summary.md](./reading/summary.md)