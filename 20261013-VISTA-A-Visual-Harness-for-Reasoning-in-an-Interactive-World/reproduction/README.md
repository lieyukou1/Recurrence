# 复现计划 · VISTA: A Visual Harness for Reasoning in an Interactive World

> 一切复现动作都要能顺着本文件 + `runs/` 记录回查。

---

## 复现裁定（20261013）：**不复现**

**结论：本论文判定为「阅读型」论文，不进入复现阶段。** `env/`、`code/`、`data/`、`runs/`、`results/` 保持空骨架。

### 为什么不复现

1. **无可复现的核心。** VISTA 无训练参数、无新架构、无可推导的理论结论。它的全部内容是**纯工程**：一个工具调用循环（`play` / `inspect` / `read_pixels` / `history`）+ 帧存档 + 两页 markdown 笔记（`GUIDE.md` / `WORKING.md`）+ 一个 prompt 模板。"复现"等于照着重搭一遍脚手架，得到的是工程细节，不是验证过的知识。

2. **复现不出它宣称的结论。** 头牌 RHAE **100.00** 绑死在两个闭源模型（Claude Opus 5.0 `xhigh` / GPT-5.6 Sol `max`）及其官方 CLI + ARC Prize API key 上。本地至多能把**机制**跑通，**分数拿不到 100**（论文自己给出的开源锚点：GLM-5.3 Flash 320B = 66.93）。因此产出只会是"我知道它怎么搭的"，而非"我验证了它的结论"——这与复现一个有可训练核心的方法论文（如 ResNet 能自己训出 76%）性质完全不同。

3. **硬件不匹配。** 本机无 NVIDIA GPU（i7-10510U + Intel UHD 集显 + 15.7 GB RAM），论文中最可行的全开源路线 GLM-5.3 Flash **320B** 权重无法本地运行。仅剩"客户端 + 云模型 API"路线，需 API key 与持续费用。

4. **时机过早。** 论文 2026-10-01 上线（裁定日仅 13 天），尚无第三方跨领域适配或拓展成果（详见"外部动态"）。此时投入复现的 ROI 低。

### 什么情况下值得重启

- 出现**第三方跨领域适配**（如 GUI / computer-use agent），且其开源实现可用开源 VLM 跑通最小管道；
- 本机获得 **GPU**，且目标从"追分数"转为"验证外置记忆机制在自建环境中的有效性"；
- 官方发布明显更轻量的复现路径（如免 CLI、纯 API、小模型 checkpoint）。

### 已提取的可迁移价值（不属于复现，转记于此备查）

- **设计模式**：外置记忆 + 模型主动检索 + **指针（笔记）与档案分离**——可直接套到 GUI / computer-use 场景，成本低。
- **评测严谨性**：own-baseline 消融（Fig.4）、**分数与 token 成本并列报告**（Fig.7）、"**harness 是乘数不是加数**"（评估 harness 前先看清基模能力）。
- **反面教材**：论文对**存储 / 带宽 / 历史增长下的检索退化**整段留白（§6 局限仅提模型能力与训练数据污染）。

### 外部动态（20261013 调研）

- 论文热度高但改造尚少：GitHub `joshhhhhan/VISTA` 约 491 stars / 31 forks，Semantic Scholar 引用 5，最后 push 2026-10-06（官方）；官方"拓展"仅限自跑的 4 个 benchmark（ARC-AGI-3 / GameWorld / AI GameStore / BabyVision）。
- 强相关的**同期并行**工作（非引用衍生）：**VidHarness**（arXiv:2609.38413，2026-09-29）——用 MCTS 自动演化 harness 做"cost-efficient long video understanding"，走"学出该看哪些帧"路线，正面绕开 VISTA 的"无损全存"承诺。
- ⚠️ 网上二手解读已有编造（如错报 VISTA 全称、错报 benchmark 列表、误称"未开源"），引用须回原文核对。

---

## 环境（未建立）

- 隔离方案：**不适用**（未进入复现阶段）。若日后重启，按 [AGENTS.md](../../AGENTS.md) §5 选型；官方要求 Linux x86_64 + Python 3.12 + Docker Engine + tmux，且强依赖 Codex CLI `0.145.0` 或 Claude Code `2.1.220`。

## 步骤

**不适用。**（若重启，参考官方 README 的 `--profile arc3 / gameworld / aigamestore / babyvision` 流程。）

## 数据与权重

- 未下载。若重启：ARC Prize platform API key、GameWorld / AI GameStore / BabyVision 环境文件。

## 预期结果（论文报告值，留作日后对照基线）

| 项目 | 论文值 |
| --- | --- |
| ARC-AGI-3（Claude Opus 5.0 xhigh） | RHAE **100.00**，7,302 动作（人类基线 17,135，少 57.4%） |
| ARC-AGI-3（GPT-5.6 Sol max） | RHAE **99.00** |
| 开源锚点（GLM-5.3 Flash 320B） | RHAE **66.93**（官方 baseline 1.89） |
| GameWorld | 成功率 63.3% / 进度 79.9% |
| AI GameStore | 几何均值 140.3 |
| BabyVision | 63.2% |

## 实际结果与偏差记录

| 日期 | 实验 | 结果 | 与论文偏差 | 备注 |
| --- | --- | --- | --- | --- |
| 20261013 | —（裁定不复现） | — | — | 本层未执行；裁定理由见上 |

## 踩坑与结论

- **结论**：VISTA 的价值在"读"不在"跑"；其全部阅读价值已由 `reading/` 四件套 + `OUTLINE.md` 承接完毕。
- **方法论教训（供全库复用）**：并非每篇论文都值得进入复现层。当一篇论文**没有可训练/可推导的核心**、且**头牌结果依赖不可及的闭源资源**时，应如实标注"复现价值低"并写明理由，而不是为了走完流程而空跑。