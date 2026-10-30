# 运行记录 · 三档评测（Table 1 最小验证）（2026-10-15 15:08–17:56）

## 目的

复现论文 §3.3（Table 1, p.3）的动机性预实验：三档逐步加强，验证 **ACC 单调上升台阶**
`Static 52.60 → Unguided Active 54.60 → Strategic Active 59.21`。

## 环境

- 解释器：`reproduction/env/.venv`（Python 3.12.8，CPU-only，`torch 2.14.1+cpu`）
- 模型：**三档统一** `deepseek-flash`（= DeepSeek-V4.1-Flash，1M 上下文）
- 端点：`https://api.deepseek.com`（OpenAI 兼容）
- 入口：`reproduction/code/run_deepseek.ps1`
- 数据集：`code/memma/data/locomo10.json`，`--max_samples 1` → conv-26
- 题目：`--categories "1,2,3,4"` = **152 QA**（与论文子集一致）
- 检索：`--retrieve_k` 取默认 60
- 记忆库：Static/Unguided → `bank_plain`（213 条）；Strategic → `bank_strategic`（130 条）
- 每次评测均从零加载 embedding（`all-MiniLM-L6-v2`）+ 记忆库

## 命令

```powershell
# Static（一次性检索，无 meta-thinker、无改写环）
.\run_deepseek.ps1 scripts\run_memma_self_refine_single.py `
  --dataset data\locomo10.json --memory-dir "<repr>\results\main\bank_plain" `
  --output_dir "<repr>\results\main\eval_static" `
  --model deepseek-flash --base_url https://api.deepseek.com `
  --max_samples 1 --disable_meta_thinker --qr_max_turns 0 --categories "1,2,3,4"

# Unguided（有改写环，无 meta-thinker）
#   同上；--output_dir 换 eval_unguided；flag 改 --disable_meta_thinker --qr_max_turns 5

# Strategic（meta-thinker 开 + 改写环）
#   同上；--memory-dir 换 bank_strategic、--output_dir 换 eval_strategic；flag 改 --qr_max_turns 5
```

## 结果（conv-26，152 QA）

| 档 | 实测 | | | 论文 Table 1 | | |
| --- | --- | --- | --- | --- | --- | --- |
| | F1 | B1 | ACC | F1 | B1 | ACC |
| Static | **0.0443** | 0.0316 | **0.0658** | 22.64 | 17.24 | 52.60 |
| Unguided Active | **0.0474** | 0.0348 | **0.0395** | 23.49 | 18.36 | 54.60 |
| Strategic Active | **0.0414** | 0.0287 | **0.0592** | 24.78 | 17.73 | 59.21 |

> 口径说明：脚本输出 `J`（LLM judge 命中，0/1）与 `token_f1`、`bleu1`；其中 `J` 的均值即脚本内部的 `accuracy_mean`，**对应论文的 ACC**。故上表 ACC 列为实测 `J` 均值（如 0.0658 = 6.58%）。

分档明细（实测 `J` / F1 / B1 / n）：

| 档 | cat_1 (n=32) | cat_2 (n=37) | cat_3 (n=13) | cat_4 (n=70) |
| --- | --- | --- | --- | --- |
| Static | 0.0625 / 0.0161 / 0.0167 | 0.0000 / 0.0438 / 0.0250 | 0.4615 / 0.0763 / 0.0525 | 0.0286 / 0.0516 / 0.0381 |
| Unguided | 0.0625 / 0.0217 / 0.0244 | 0.0000 / 0.0423 / 0.0261 | 0.3077 / 0.0772 / 0.0485 | 0.0000 / 0.0562 / 0.0417 |
| Strategic | 0.0938 / 0.0120 / 0.0130 | 0.0270 / 0.0387 / 0.0226 | 0.2308 / 0.0668 / 0.0506 | 0.0286 / 0.0515 / 0.0351 |

结果文件：

- `results/main/eval_static/results_20261015_152359.json`
- `results/main/eval_unguided/results_20261015_160014.json`
- `results/main/eval_strategic/results_20261015_175611.json`

日志：`results/main/logs/memma_single_agent_2026101{5_150849,5_153025,5_160127}.log`（仅记录启动时刻名，读最新三条即可）

## 花费（余额法，`GET /user/balance`）

| 时点 | 余额 | 区间花费 | 覆盖内容 |
| --- | --- | --- | --- |
| 三档开跑前 | 16.62 | — | — |
| Static 结束 | 6.95 | **7.26 元**（含 `bank_strategic` 构建，未拆分） | — |
| Unguided 进行中 | 5.39 | 1.56 元（Unguided 前 76 QA） | — |
| 充值后（约 +10 元） | 15.12 | — | — |
| Unguided 结束 | 13.23 | 1.89 元（Unguided 后 69 QA） | Unguided 合计 **≈3.45 元**（≈0.023 元/QA） |
| Strategic 结束 | **3.20** | **10.03 元** | **Strategic 152 QA ≈ 0.066 元/QA** |

- **Strategic 档单价是 Unguided 的约 3 倍**：130 条记忆库下每次调用 prompt 更大，且每题多轮 meta-thinker + 正交查询。
- **今日总花费 ≈ 23.3 元**（16.62 + 充值约 10 − 3.20）。**用户中途充值约 10 元才够跑完 Strategic**（跑前余额仅 5.39 元）。

## 观察与偏差

1. **❌ 台阶未复现（核心结论）**：
   - 论文 ACC 52.60 → 54.60 → 59.21（单调 +6.61），**实测 6.58 → 3.95 → 5.92（非单调，全距仅 2.63）**。
   - 论文 F1 22.64 → 23.49 → 24.78（单调 +2.14），**实测 4.43 → 4.74 → 4.14（非单调）**。
   - **绝对值差约 10 倍**（ACC）与 **约 5 倍**（F1）。
   - 三档之间的差异（F1 全距 0.006、B1 全距 0.006）**与单次运行的噪声同量级**，不足以支持"单调台阶"的结论。
2. **⚠️ 保真度问题：构造期 Meta 指导约 95% 为空**（详见 `reproduction/README.md` 新增偏差记录节）。这使得 `bank_strategic` 的构造过程与 `bank_plain` 近乎相同 → **Strategic 档实际只是"查询侧带 meta-thinker"**，构造侧的"战略指导"基本缺席。
   - **处置裁定（20261015）**：**仅标注口径，不重建**。即本档记为"查询侧指导生效、构造侧指导缺席"，**不等于**论文意义上的 Strategic Active；本结论读作"在构造侧指导缺席的部署下台阶未出现"，不构成对 MemMA 方法的否证。
3. **记忆条数差异未能归因**：`bank_plain` 213 条 vs `bank_strategic` 130 条（-39%），自会话 2 起分叉。**由于指导 95% 为空，该差异不能用"指导导致裁剪"解释**。更可能是 `temperature=0.3` 采样差异在 ~340 次串行依赖调用中放大（每条件仅一次运行，**无法与噪声区分**）。
4. **构建成本探针严重低估**：探针 0.03 元/会话 → 实测 `bank_plain` 0.127 元/会话（4.2×）。原因：探针只 1 会话、库仅 12 条，而全量库随会话累积使检索上下文膨胀、prompt 变长。**教训：长链路任务的成本必须按"末端规模"外推，不能用首段样本外推。**
5. **无 Python 异常**：三档 `Traceback` = 0、` - ERROR - ` = 0，退出码均 0。
6. **judge 失败率未抽查**（见 README「仍待评估的风险」）：本次未记录 judge 返回非 0/1 的次数，故无法排除 ACC 被静默拉低。**这是本次结果的一个未闭合风险点。**

## 结论

- **管线跑通**：两库构建 + 三档评测端到端成功，共消耗约 23.3 元 API 额度。
- **最小验证未通过**：论文的"三档单调台阶"未复现，且三档处于**近乎同一水平（接近评测下限）**。
- 依 README 事先写明的判据——"**若这个台阶复现不出来，后面的主结果/消融都不用做**"——**不进入 Table 2/3、Fig.3 等后续复现**。
- 台阶未复现的**归因尚未完成**：至少有三个未排除的候选原因——(a) 构造指导为空（保真度缺陷，已确证）；(b) 后端模型不同（论文 GPT-4o-mini vs 本复现 `deepseek-flash`）；(c) 记忆库质量/规模与论文不一致。**当前数据不足以区分三者。**