# 运行记录 · 全量记忆库构建（2026-10-15 13:33–15:03）

## 目的

为 Table 1 三档评测准备两个记忆库（conv-26，全 19 会话）：

- `bank_plain`：**无**构造期 Meta 指导 → 供 **Static** 与 **Unguided** 共用（动机实验中这两档构造侧一致）
- `bank_strategic`：**有**构造期 Meta 指导（`--enable_construction_meta_guidance`）→ 供 **Strategic** 使用

两者都关闭自演化（`--self_refine_source none`），与论文 §3.3 动机性预实验口径一致。

## 环境

- 解释器：`reproduction/env/.venv`（Python 3.12.8，CPU-only，`torch 2.14.1+cpu`）
- 模型：`deepseek-flash`（= DeepSeek-V4.1-Flash）
- 端点：`https://api.deepseek.com`（OpenAI 兼容）
- 入口：`reproduction/code/run_deepseek.ps1`
- 数据集：`code/memma/data/locomo10.json`，`--max_samples 1` → conv-26（Caroline / Melanie）
- 知晓的偏差：`--mm_max_turns` 取默认 1（与论文构建轮数设置的一致性**未核实**）
- **前置条件**：DeepSeek 上游恢复（13:33 探活 `ok 3/3`，延迟 0.6–1.1s）

## 命令

```powershell
# 1) bank_plain（Static / Unguided 共用）
.\run_deepseek.ps1 scripts\run_memma_self_refine_single.py `
  --dataset data\locomo10.json `
  --memory-dir "<repr>\results\main\bank_plain" `
  --output_dir "<repr>\results\main\build_plain" `
  --build_memories --model deepseek-flash --base_url https://api.deepseek.com `
  --max_samples 1 --self_refine_source none

# 2) bank_strategic（加构造期 Meta 指导）
.\run_deepseek.ps1 scripts\run_memma_self_refine_single.py `
  --dataset data\locomo10.json `
  --memory-dir "<repr>\results\main\bank_strategic" `
  --output_dir "<repr>\results\main\build_strategic" `
  --build_memories --model deepseek-flash --base_url https://api.deepseek.com `
  --max_samples 1 --self_refine_source none --enable_construction_meta_guidance
```

## 结果

| 库 | 记忆条数 | 用时 | 退出码 | 日志 |
| --- | --- | --- | --- | --- |
| `bank_plain` | **213** | 1605.44s（≈27 min） | 0 | `results/main/logs/memma_single_agent_20261015_133922.log` |
| `bank_strategic` | **130** | 2945.04s（≈49 min） | 0 | `results/main/logs/memma_single_agent_20261015_141410.log` |

产物：

- `results/main/bank_plain/conv-26/memory_bank.json`
- `results/main/bank_strategic/conv-26/memory_bank.json`（约 1.6 MB）

逐会话累积（plain）：10 → 22 → 33 → 47 → 57 → 68 → 84 → … → 209 → 213
逐会话累积（strategic）：10 → … → 102 → … → 130

## 花费（余额法，`GET /user/balance`）

| 时点 | 余额 | 区间花费 | 覆盖内容 |
| --- | --- | --- | --- |
| 构建前 | 16.62 | — | — |
| `bank_plain` 后 | 14.21 | **2.41 元** | 19 会话 → ≈**0.127 元/会话** |
| 后续（合并计） | 6.95 | **7.26 元** | `bank_strategic` 构建 **+** Static 152 QA 评测 |

> ⚠️ 上表第 3 行两项**未能拆分**（两次读数之间同时跑了这两个任务）。按评测调用量反推，Static 约占 1 元、`bank_strategic` 约 6.2 元（**估算值，非实测**）。

## 观察（与预期不符，待解释）

1. **构造期 Meta 指导让记忆更少**：213 条 → 130 条（-39%），自会话 2 起分叉。

   | 会话 | 1 | 2 | 3 | 4 | 5 | … | 15 | 17 | 19 |
   | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
   | `bank_plain` | 10 | 22 | 33 | 47 | 57 | … | 188 | 203 | **213** |
   | `bank_strategic` | 10 | 19 | 21 | 28 | 33 | … | 102 | 120 | **130** |

   > **⚠️ 归因更正（同日 17:56 补）**：初稿曾推断"构造期 Meta 指导在做更强的裁剪/合并"。**该推断已被推翻**——查证发现构造指导调用 **419 次中 397 次（95%）返回空字符串**，因此 `bank_strategic` 在绝大多数轮次的构造 prompt 与 `bank_plain` **完全相同**；差异**不能归因于指导**。更可能是 `temperature=0.3` 采样差异在 ~340 次串行依赖调用中逐级放大，**每条件仅运行一次，无法与噪声区分**。详见 `reproduction/README.md`「⚠️ 保真度问题（新，20261015）」。**该现象目前仍属"未归因"，不可当作论文行为的证据。**
2. **构建成本比探针外推高 4 倍**：探针（20261014）测得 0.03 元/会话，实跑 0.127 元/会话。原因推断：探针只跑 1 个会话、记忆库还很小（12 条），而全量库随会话累积检索上下文膨胀（`--mm_max_turns 1` 下每次仍带全部已有记忆）。→ **小样本探针会系统性低估成本**。
3. **带构造指导的库贵得多**：`bank_plain` 2.41 元 vs `bank_strategic` 估算 ≈6.2 元（约 **2.6 倍**），主要来自 **419 次额外的构造指导调用**。（注：6.2 元为合并计量下的估算值，见上表脚注。）
4. **冷启动导入很慢**：`transformers` → `torch` 导入链在本机耗时约 **5–6 分钟**（`py-spy` 抓栈显示卡在 `importlib.metadata.packages_distributions()` 与 `sympy` 导入），非挂死。**判断"是否僵死"时要先扣掉这 6 分钟。**

## 偏差 / 异常

- **无 Python 异常**，两个构建退出码均为 0（`Successful: 1, Failed: 0`）。
- 日志中大量 `NativeCommandError` 是 PowerShell 包装 Python stderr 的噪声（见 `run_deepseek.ps1` 注释），非真错误。
- **首次尝试（13:33 前）曾"卡在会话 1"**：经查为 DeepSeek 上游过载（响应体读不完、`py-spy` 显示卡在 `ssl.read → httpx2.iter_bytes`），**不是代码问题**；服务恢复后同一命令一次跑通。详见 `reproduction/README.md`「断点（2026-10-15）」。