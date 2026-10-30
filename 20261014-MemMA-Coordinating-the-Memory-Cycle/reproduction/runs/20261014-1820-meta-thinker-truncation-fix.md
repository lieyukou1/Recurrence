# 运行记录 · Meta-Thinker 检索环早退的定位与修复（2026-10-14 18:00–18:20）

## 目的

成本探针暴露：Strategic 档 32 QA 中 25/29 次 `NOT_ANSWERABLE` 直接 `No orthogonal query generated, stopping`，检索环退化成单轮。按"换模型 → 加容错 → 强约束"的顺序排查。

## 结论（先说结果）

**真因不是"模型不会吐标签"，而是 `max_tokens` 太小被截断**——推理模型的 reasoning token 也计入 `completion_tokens`，把预算吃光后可见正文为空。

## 步骤与证据

### 1. 换模型（路 1）—— 无效，反而更糟

用仓库真实的 v4 answerability `system prompt` + 真实记忆库，直打两个模型 × 6 题（`probe_meta_thinker_tags.py`）：

| 配置 | `finish_reason=length` | 检索环可继续 |
| --- | --- | --- |
| deepseek-flash @ 800 | 1/6 | 5/6 |
| deepseek-flash @ 4000 | 0/6 | 5/6 |
| deepseek-v4-pro @ 800 | **4/6（content 长度全为 0）** | 2/6 |
| deepseek-v4-pro @ 4000 | 0/6 | 5/6 |

- `finish_reason=length` 时 `choices[0].message.content == ""`。
- usage 样例：`completion_tokens=525`，其中 `completion_tokens_details.reasoning_tokens=285`；`prompt_cache_hit_tokens=1152`。
- ⇒ 路 1（换 `v4-pro`）**否定**：它是更重的推理模型，同等预算下更容易被吃空，且更贵。

### 2. 定位真因（截断）—— 代码位置

| 位置 | 原值 | 用途 | 问题 |
| --- | --- | --- | --- |
| `check_answerability` [L2899-2904](../code/memma/scripts/run_memma_self_refine_single.py#L2899-L2904) | `max_tokens=800` | 可答性检查，v4 prompt 要求 5 段长输出 | 800 常被截断，`key_gaps`/`retrieval_guidance` 闭合标签缺失 → 解析为空 |
| `generate_orthogonal_query` [L3045-3050](../code/memma/scripts/run_memma_self_refine_single.py#L3045-L3050) | `max_tokens=200` | 生成正交查询（要求 JSON） | 200 在推理模型下必被吃空 |
| `LLMClient.get_completion` [L840-L858](../code/memma/scripts/run_memma_self_refine_single.py#L840-L858) | — | 统一出口 | **不检查 `finish_reason`**，截断结果被静默当正常返回 |

### 3. 打补丁（最小改动，2 处）

```
check_answerability      : max_tokens  800 -> 4000   # [REPRO PATCH]
generate_orthogonal_query: max_tokens  200 -> 1500   # [REPRO PATCH]
```

### 4. 复验（同 32 QA，`--categories 1`，`qr_max_turns 5`，flash）

| 指标 | 补丁前 | 补丁后 |
| --- | --- | --- |
| Meta-Thinker 轮次总数 | 37 | **91（2.81 轮/QA）** |
| 正交查询成功生成 | 4 | **61** |
| "No orthogonal query" 中断 | 25 | 20 |
| 花费 | 0.23 元 | 0.53 元 |

每 QA 轮次分布（补丁后）：1/2/3/4/5 轮 = 10/2/10/4/6。

结果文件：`results/cost_probe/eval_strategic_c1_patched/results_20261014_181912.json`。

## 偏差与残留风险

- **对官方快照的偏离**：上述 2 处 `max_tokens` 为本次修改（快照无 `.git`、未锁 commit）。仅改"输出预算"，不动 prompt 与流程，判为不改变方法本体。
- **judge 静默失败**：`evaluate_llm_judge` 无 `max_tokens`，解析异常一律返回 0；若 judge 输出被截断会静默拉低 ACC。跑分时需抽查失败率。
- 本轮探针的 ACC（0.125/0.1875）**无意义**——记忆库只有 1 个会话共 12 条，多数题本就无据可答。

## 下一步

进最小验证三档跑分（Static / Unguided / Strategic），每档需先构建全量记忆库（19 会话）。预算外推 ≈10 元，余额 17.47 元。