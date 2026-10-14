# VISTA: A Visual Harness for Reasoning in an Interactive World

> 论文索引卡片 · 开工日 20261013 · 目录 `20261013-VISTA-A-Visual-Harness-for-Reasoning-in-an-Interactive-World`

## 速览

| 项 | 内容 |
| --- | --- |
| 标题 | VISTA: A Visual Harness for Reasoning in an Interactive World |
| 作者 | Qiushi Han*, Keya Hu*, Linlu Qiu*, Cathy Wu, Kaiming He（MIT，* 共同一作） |
| 来源 | https://arxiv.org/abs/2610.02200 |
| 年份 / 会议 | 2026 / arXiv preprint (cs.AI) |
| 主题标签 | multimodal, agent, visual-harness, long-horizon-memory, vlm, arc-agi-3 |

## 进度

- [x] 原文 PDF 就位（`paper/original.pdf`）
- [x] 元数据填写（`paper/metadata.yaml`）
- [x] PDF 渲染页面图（`paper/extracted/pages/`，23 页）
- [x] 多模态精读（`reading/summary.md`）
- [x] 全文翻译（`reading/translation.md`）
- [x] 公式整理（`reading/formulas.md`）
- [x] 图表存档（`reading/figures/`）
- [x] 浓缩提纲（`OUTLINE.md`）
- [x] 登记总索引（根目录 `CATALOG.md`）
- [x] 复现价值评估（`OUTLINE.md` / `reproduction/README.md`）——**裁定：不复现**
- [ ] 隔离环境建立（`reproduction/env/`）——**不适用（已裁定不复现）**
- [ ] 复现跑通并记录（`reproduction/`）——**不适用（已裁定不复现）**

> **复现裁定（20261013）：不复现。** 本论文为"阅读型"论文——无训练参数、无新架构、无可推导理论，harness 本身是纯工程；且头牌结果绑死闭源模型（Claude Opus 5.0 / GPT-5.6 Sol）与其 CLI + API key，本地拿不到 100.00；本机亦无 NVIDIA GPU（i7-10510U + Intel UHD + 15.7 GB RAM），全开源路线 GLM-5.3 Flash **320B** 跑不动。裁定理由与"何时值得重启"详见 [`reproduction/README.md`](./reproduction/README.md)。当前状态：**已精读，裁定不复现**。

## 一句话结论

用一个极简的"视觉原生" agent harness（原始图像观测 + 无损视觉记忆 + 主动视觉检查），把多模态模型**已有**的推理能力释放出来——在 ARC-AGI-3 上把 Claude Opus 5.0 的 RHAE 从 40.68 拉到满分 100.00，且比首次游玩人类少用 57.4% 动作。

## 相关链接

- 原文：https://arxiv.org/abs/2610.02200
- 代码仓库：https://github.com/joshhhhhan/VISTA
- 项目主页：https://vista-research.github.io/
- 其他：ARC-AGI-3 基准 [4] arXiv:2603.24621