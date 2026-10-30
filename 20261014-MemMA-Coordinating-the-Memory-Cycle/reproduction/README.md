# 复现计划 · MemMA: Coordinating the Memory Cycle through Multi-Agent Reasoning and In-Situ Self-Evolution

> 一切复现动作都要能顺着本文件 + `runs/` 记录回查。
> **定级结论见下"复现价值裁定"——本篇定为「中」，执行最小验证。**

## 复现价值裁定（按 AGENTS.md §4.3）

- **级别：中**
- **判定三问**：
  1. 有没有**可训练 / 可推导 / 可独立测量**的核心？→ **有**。核心是"记忆周期协调"这一机制：去/留 Meta-Thinker 的战略指导、去/留探针-修复环，都能带来可独立测量的 ACC 差异（Table 1 的单调台阶、Fig.3 的消融），且**不依赖训练**。
  2. 复现所需资源是否**可及**？→ **部分可及**。无 GPU 门槛（不训练参数，纯 LLM 调用，本机 CPU 已实测跑通，见下）；只需 **2 把 key**（OpenAI + Anthropic），**探针 QA 已随官方仓库预生成**（`data/memory_rl_train_locomo_conv_26.parquet`，76 条），**不需要 Opus、不需要自建探针管线**；数据为公开的 LoCoMo。
  3. 复现能否产出**独立于论文的结论**？→ **能**，但主要体现在"台阶是否成立 / 探针风格是否真是瓶颈"这类机制性结论上，不是逐位复刻数字。
- **动作：最小验证**——只跑通机制、不追论文数字，偏差如实标注。
- **执行结果（20261015）**：管线端到端跑通（两库构建 + 三档各 152 QA），但 **❌ 论文的三档单调台阶未复现**，且绝对值差约 10 倍（ACC）。**已如实结论为"最小验证未通过"，不进入后续 Table 2/3 与消融。** 根因**未完成归因**（三个候选原因见下）。总花费 **≈23.3 元**（超出预估 2.3 倍，用户中途充值约 10 元）。

### 为何不判「高」

完整复现要覆盖 LoCoMo 的 152 QA 子集 + 多后端对照 + 消融 + 探针模型对照，API 成本与调用量成倍放大，且论文**未报告 token/延迟成本**，难以规划预算。故不做全量复刻。

### 为何不判「低」

MemMA **不训练任何参数**，方法载体是 7 张 prompt（Table 12–18）+ 一套协调协议，**本机可跑通**，且核心机制（前向战略指导、后向就地修错）可被独立测量——不属于"无可训练/可推导核心"的阅读型。

## 复现目标（最小验证）

- **复现范围**：只做 **Table 1 的动机性预实验**（§3.3, p.3）——三档逐步加强：
  1. **Static**：构造 + 一次性 top-30 检索；
  2. **Unguided Active**：+ 迭代查询改写（无战略指导）；
  3. **Strategic Active**：+ Meta-Thinker 统筹构造与检索。
- **核心指标**：三档的 F1 / B1 / ACC（LoCoMo 子集，GPT-4o-mini 后端）。
- **判定"最小验证成功"的标准**：能否复现 `Static 52.60 → Unguided Active 54.60 → Strategic Active 59.21`（**ACC 单调上升**）。**若这个台阶复现不出来，后面的主结果/消融都不用做。**

## 环境（详见 `env/`）

- 隔离方案：**venv 独立虚拟环境** `env/.venv`（本机未安装 conda/uv，退而用 Python 标准库 venv；环境随论文目录走，删掉论文目录即彻底干净）。
- 解释器：Python **3.12.8**（官方示例用 conda + 3.11；此处 3.12，实测依赖全部装通）。
- 关键依赖（完整冻结清单见 `env/requirements-lock.txt`）：`torch 2.14.1+cpu`、`transformers 5.19.0`、`sentence-transformers 6.1.0`、`openai 3.31.0`、`anthropic 1.13.0`、`pandas 3.0.6`、`pyarrow 26.0.0`。
- **CPU-only 关键步骤**：先 `pip install torch --index-url https://download.pytorch.org/whl/cpu`，**再** `pip install -r requirements.txt`（顺序反了会拉 CUDA 版）。实测 `torch.cuda.is_available() = False`，`--help` 与全依赖导入均正常。
- 硬件要求：本机即可（i7-10510U + Intel UHD + 15.7 GB RAM，**无需 GPU**）；瓶颈是 **API 额度**而非算力。
- 网络：本机 **GitHub 不通**（`github.com:443` 连接失败），PyPI 与国内镜像通；仓库经 `ghfast.top` 镜像 zip 获取（**无 `.git`，未锁定 commit**）。HuggingFace 亦不通，已配 `HF_ENDPOINT=https://hf-mirror.com`。

### 运行配置（统一走 DeepSeek，模型 `deepseek-flash`）

- 两把 key 用**同一个** DeepSeek key；模型统一 **`deepseek-flash`**（= DeepSeek-V4.1-Flash，1M 上下文）；端点：`https://api.deepseek.com`（OpenAI 兼容）+ `https://api.deepseek.com/anthropic`（Anthropic 兼容）。
- **关键坑**：仓库脚本**不读 `.env`**（代码里没有 `load_dotenv`），官方示例导出的 `OPENAI_API_BASE` 在 `scripts/*.py` 里**根本没人读**。因此：
  - 配置留档在 `code/memma/.env`（含密钥，已被 gitignore）；
  - 运行时用 **`reproduction/code/run_deepseek.ps1`**：它解析 `.env` 注入环境变量，再把参数原样转发给脚本；
  - 仍需在命令行显式传 `--model deepseek-flash --base_url https://api.deepseek.com`（脚本只认 CLI 参数与 SDK 原生变量）。
- **冒烟验证（各 1 次调用）**：OpenAI 兼容端点 **通过**；Anthropic 兼容端点 **通过**，但返回内容首块是 `ThinkingBlock`、正文在 `TextBlock` —— **直接取 `content[0].text` 的 `*_claude` 脚本会挂**，走那条路前需先确认代码是否过滤块类型。

### 前置阻塞（进小样本段之前）· 均已解决

- ~~数据集缺位~~ —— **已解决**：经 `ghfast.top` 镜像取到 `code/memma/data/locomo10.json`（2,805,274 字节，10 样本）。
- ~~embedding 首次下载~~ —— **已解决**：`all-MiniLM-L6-v2` 经 `hf-mirror.com` 预下成功，评测运行时正常加载（实测 `Loaded MemoryBank with 12 entries`）。
- ~~meta-thinker 结构化输出兼容~~ —— **已解决**：真因是 `max_tokens` 截断（非模型不吐标签），已打 2 处补丁并复验；见下「✅ 保真度问题」。
- **（20261015 新发现，未解决）构造期 Meta 指导 95% 为空** —— 同类截断问题的**漏网之处**，导致 Strategic 档构造侧指导缺席；见下「⚠️ 保真度问题（新）」。

## 步骤

1. 仓库与隔离环境 —— **已完成**：经 `ghfast.top` 镜像取仓库到 `code/memma/`，`env/.venv` + `env/requirements-lock.txt`（见上"环境"）。
2. 准备 **LoCoMo** 评测子集（论文用 conv-26：19 session / 419 轮；剔除对抗子集后 **152 QA**）。
3. 固定 **Answer Agent 与 LLM judge = GPT-4o-mini**（否则增益无法归因，务必别搞混）。
4. 依次跑 Static / Unguided Active / Strategic Active 三档，记录 F1 / B1 / ACC。
5. 结果落 `results/`，命令与环境落 `runs/<时间戳>/`，偏差写回本文件"实际结果与偏差记录"。

## 数据与权重

- 来源：LoCoMo（公开；论文用 conv-26 子集）。
- 存放位置：`data/`（大文件不入版本库）。
- 无需模型权重（无训练）。

## 预期结果

<!-- 论文报告的结果，作为对照基线 -->

| 档位 | F1 | B1 | ACC |
| --- | --- | --- | --- |
| Static | 22.64 | 17.24 | 52.60 |
| Unguided Active | 23.49 | 18.36 | 54.60 |
| Strategic Active | 24.78 | 17.73 | 59.21 |

（若最小验证通过，再考虑扩展：主结果 Table 2、后端可插拔 Table 3、消融 Fig.3、探针模型对照 Table 9–11。）

## 实际结果与偏差记录

| 日期 | 实验 | 结果 | 与论文偏差 | 备注 |
| --- | --- | --- | --- | --- |
| 20261014 | 零成本段：环境自检（无 API） | CPU-only 装通；`--help` 正常；全依赖导入 OK（`cuda=False`）；预生成探针 parquet 可读（76 行） | 不适用 | 未花 API；详见"踩坑与结论" |
| 20261014 | 成本探针 · 构建（1 样本 × 1 会话，DeepSeek） | 12 条记忆 / 151.7s / 花费 **0.03 元**（19.03→19.00） | 不适用（只测成本） | 见"成本探针"节 |
| 20261014 | 成本探针 · 评测（conv-26，categories 1 = 32 QA，Strategic） | ACC 0.1875 / 花费 **0.23 元**（19.00→18.77） | **无效对照**：记忆库仅 12 条（只建了 1 会话），准确率无意义 | 见"成本探针"节；暴露 meta-thinker 检索环早退 |
| 20261014 | 标签/截断探针（flash vs v4-pro × 800 vs 4000） | 两模型 @4000 均 **0/6 截断**；v4-pro @800 达 4/6 空响应 | 定位真因：**推理模型下 `max_tokens` 太小被截断**，非标签遵循 | 花费 0.77 元（v4-pro 贵）|
| 20261014 | 补丁后复验（同 32 QA，改动 2 处 `max_tokens`） | 轮次 37→**91**、正交查询 4→**61**；花费 **0.53 元**（18.00→17.47） | 检索环恢复迭代，Strategic 不再伪单轮 | 补丁属对官方快照偏离，见"保真度问题"节 |
| 20261015 | 构建 `bank_plain`（conv-26，全 19 会话） | **213 条记忆** / 1605s / 花费 **2.41 元** | 不适用（只建库） | 无异常；详见 [runs/20261015-1406-build-memory-banks.md](reproduction/runs/20261015-1406-build-memory-banks.md) |
| 20261015 | 构建 `bank_strategic`（+ 构造期 Meta 指导） | **130 条记忆** / 2945s | 记忆条数比 `bank_plain` **少 39%**，**原因未归因**（见"构造指导为空"节） | 花费与 Static 评测合并 7.26 元，未拆分 |
| 20261015 | **Static 档评测**（152 QA） | F1 **0.0443** / B1 **0.0316** / ACC **0.0658** | 论文 22.64 / 17.24 / 52.60 → **ACC 差约 10×** | 花费 ≈1 元（估算，与上条合并计量） |
| 20261015 | **Unguided 档评测**（152 QA） | F1 **0.0474** / B1 **0.0348** / ACC **0.0395** | 论文 23.49 / 18.36 / 54.60；**ACC 比 Static 更低**（非单调） | 花费 **≈3.45 元**（≈0.023 元/QA） |
| 20261015 | **Strategic 档评测**（152 QA） | F1 **0.0414** / B1 **0.0287** / ACC **0.0592** | 论文 24.78 / 17.73 / 59.21；**台阶未复现** | 花费 **10.03 元**（≈0.066 元/QA）；详见 [runs/20261015-1756-three-tier-eval.md](reproduction/runs/20261015-1756-three-tier-eval.md) |

### 三档台阶复现结论（20261015）

| 档 | 实测 ACC | 实测 F1 | 论文 ACC | 论文 F1 |
| --- | --- | --- | --- | --- |
| Static | 0.0658（6.58%） | 0.0443 | 52.60 | 22.64 |
| Unguided Active | 0.0395（3.95%） | 0.0474 | 54.60 | 23.49 |
| Strategic Active | 0.0592（5.92%） | 0.0414 | 59.21 | 24.78 |

- **❌ 台阶未复现**：论文 ACC 单调 +6.61，实测 6.58 → 3.95 → 5.92（非单调，全距仅 2.63）；**绝对值差约 10 倍**（ACC）/ **约 5 倍**（F1）。
- 三档间差异（F1 全距 0.006、B1 全距 0.006）**与单次运行噪声同量级**，不足以支持"单调台阶"。
- 依 §"复现目标"事先写明的判据——**"若这个台阶复现不出来，后面的主结果/消融都不用做"**——**不进入 Table 2/3、Fig.3 等后续复现**。
- **归因未完成**：至少三个未排除的候选原因 ——(a) **构造指导 95% 为空**（已确证，见下节）；(b) **后端模型不同**（论文 GPT-4o-mini vs 本复现 `deepseek-flash`）；(c) **记忆库规模/质量与论文不一致**。**当前数据不足以区分三者。**

## 踩坑与结论

### 零成本段（20261014）· 环境自检

- **GitHub 被墙**：`github.com:443` 在沙箱内外均连不上，`git clone` 失败（与既往 `git push` 失败同源）。绕法：经 `ghfast.top` 镜像下 zip。**代价**：拿到的是快照、**无 `.git`，没能锁定 commit**，若要严格溯源需补记版本。
- **本机无 conda / uv / mamba**，只有系统 Python 3.12。故弃官方 conda 路线，改用 `python -m venv`：环境落在 `env/.venv`，随论文目录走、可整体删除，不污染全局（符合 AGENTS.md §5 精神）。
- **CPU-only 装法有顺序要求**：先装 `torch --index-url .../whl/cpu`，再 `pip install -r requirements.txt`；反了会拉 CUDA 版。实测全部装通，`cuda=False`，`--help` 与全部依赖导入均正常。**结论：CPU-only 可行。**
- **nltk 数据（已解决）**：脚本启动会从 `raw.githubusercontent.com` 下 `punkt`，起初被代理的 SSRF 防护拒绝。解法：置 `NLTK_ALLOW_PROXIED_URLOPEN=1`（已写入 `.env`）后，`punkt` 与 `punkt_tab` 均已下到 `%APPDATA%\nltk_data`。**注意新版 nltk 的 `word_tokenize` 需要 `punkt_tab`，而脚本只自动下 `punkt`，故已手动补齐。**
- **`lightmem` 疑为占位包**：PyPI 上的 `lightmem==0.0.0` 仅 10 KB，几乎肯定不是 README 所述的 LightMem 后端。**LightMem 后端需另找官方仓库**；本次最小验证走 Single-Agent 路径，不受影响。
- **transformers 大版本跃迁**：装成 `5.19.0`（约束是 `>=4.57`，即 5.x）。代码按 4.x 写，导入无碍，但**运行时 API 行为可能有差异**，是后续跑分时的潜在风险点。

### 成本探针（20261014）· DeepSeek 单价与预算外推

**运行配置**：模型统一 `deepseek-flash`（= DeepSeek-V4.1-Flash），OpenAI 兼容端点 `https://api.deepseek.com`；余额经 `GET /user/balance` 实测。

**实测单价**（余额 2 位小数，故为量级估计）：

| 项 | 规模 | 花费 | 单价 |
| --- | --- | --- | --- |
| 构建 | 1 样本 × 1 会话（12 条记忆，151.7s） | 0.03 元 | **≈0.03 元/会话** |
| 评测（补丁前） | 32 QA（Strategic，`qr_max_turns 5`） | 0.23 元 | **≈0.0072 元/QA**（约 105 次 LLM 调用 → ≈0.0022 元/调用） |
| 评测（补丁后） | 32 QA（同配置，检索环真正跑起来） | 0.53 元 | **≈0.0166 元/QA**（约 216 次调用 → ≈0.0025 元/调用） |
| 标签探针 | 37 次调用（含 `v4-pro` 高推理输出） | 0.77 元 | ≈0.021 元/调用（**`v4-pro` 显著更贵**，单次可烧 3717 completion tokens）|

评测 32 QA 的调用构成（补丁后）：91 次可答性检查 + 61 次正交查询 + 32 次作答 + 32 次 judge；每 QA 轮次分布 1/2/3/4/5 轮 = 10/2/10/4/6，**均值 2.81 轮**。

**外推**（conv-26 = 19 会话 / 152 QA，三档合计；以**补丁后**为准）：

| 情形 | 构建（3 档） | 评测（152 QA × 3 档） | 合计 | 余额 17.47 元够否 |
| --- | --- | --- | --- | --- |
| **补丁后基准**（每 QA 0.0166 元；Unguided≈Strategic×0.6，Static≈2 调用/QA） | ≈1.7 元 | ≈8 元 | **≈10 元** | **够，余量约 1.7×** |
| **悲观**（全量记忆库 12→30 条、prompt 变长 1.7×，且多档重跑） | ≈2.5 元 | ≈20 元 | **≈22 元** | **不够** |

**结论**：以实测每 QA 0.0166 元、均值 2.81 轮外推，**跑完一轮最小验证约 10 元，17.47 元够用**；但没有重跑余量，且若中途要换档重测就会吃紧。**先别再动模型/预算（`v4-pro` 明显更贵）**，直接进三档跑分。

**全量实跑实测（20261015，余额法）**——上表外推**低估了约 2.3 倍**：

| 项 | 规模 | 实测花费 | 单价 |
| --- | --- | --- | --- |
| `bank_plain` 构建 | 19 会话（213 条记忆，1605s） | **2.41 元** | **≈0.127 元/会话**（探针外推 0.03 元的 **4.2 倍**） |
| `bank_strategic` 构建 + Static 评测 | 19 会话（130 条）+ 152 QA | **7.26 元**（两项未拆分；估算 Strategic 构建 ≈6.2 元、Static ≈1 元） | — |
| Unguided 评测 | 152 QA（`qr_max_turns 5`） | **≈3.45 元** | **≈0.023 元/QA** |
| **Strategic 评测** | 152 QA（meta-thinker 开） | **10.03 元** | **≈0.066 元/QA**（**Unguided 的约 3 倍**） |

- **合计：今日总花费 ≈23.3 元**（16.62 + 充值约 10 − 3.20）。**远超外推的 10 元。**
- 实测中余额一度降到 **5.39 元**，**用户中途充值约 10 元**才够跑完 Strategic 档。
- **Strategic 单价为何最高**：130 条记忆库使每次调用 prompt 显著变长，叠加每题多轮 meta-thinker + 正交查询。
- **教训**：小样本探针的系统性偏差来源已明确——探针只跑 1 会话、记忆库仅 12 条，而全量库随会话累积使检索上下文迅速膨胀，prompt 长度与成本非线性增长。**长链路任务的成本必须按"末端规模"外推，不能用首段样本外推。** 详见 [20261015-1406-build-memory-banks.md](reproduction/runs/20261015-1406-build-memory-banks.md) 与 [20261015-1756-three-tier-eval.md](reproduction/runs/20261015-1756-three-tier-eval.md)。

### ✅ 保真度问题（已定位并修复）· 真因是 max_tokens 截断，不是"模型不会吐标签"

- **现象**：评测探针 32 QA 中，29 次 `NOT_ANSWERABLE` 里有 **25 次**触发 `[Turn 0] No orthogonal query generated, stopping`，Strategic 档退化成"单轮"。
- **排查路径（按"模型 → 容错 → 约束"顺序）**：
  1. **换模型（无效，反而更糟）**：把 Meta-Thinker 换成 `deepseek-v4-pro` 直打同一份 v4 prompt，检索环可继续率 **2/6**，远低于 flash 的 5/6；`finish_reason=length` 占 **4/6**，且这 4 次的 `content` 长度都是 **0**。
  2. **定真因（截断）**：`check_answerability` 只给 `max_tokens=800`（[L2899-2904](reproduction/code/memma/scripts/run_memma_self_refine_single.py#L2899-L2904)），而 v4 prompt 要求的长结构化输出（decision + reason + key_gaps + missing_speaker + time_need + retrieval_guidance 五段）很容易超；**推理模型的 reasoning token 也计入 `completion_tokens`**（实测 `reasoning_tokens=285`），把 800 吃光后可见正文一个都不剩 → 正则解析不到闭合标签 → `key_gaps`/`retrieval_guidance` 为空 → 早退。
  3. **对照实验（决定性）**：同一批 6 题、同一 prompt，仅改 `max_tokens`：

     | 配置 | `finish=length` | 检索环可继续 |
     | --- | --- | --- |
     | flash @ 800 | 1/6 | 5/6 |
     | flash @ 4000 | **0/6** | 5/6（第 2 题是**正确**的 ANSWERABLE） |
     | v4-pro @ 800 | **4/6（全空响应）** | 2/6 |
     | v4-pro @ 4000 | **0/6** | 5/6 |

- **补丁（最小改动，2 处，已加 `[REPRO PATCH]` 注释）**：
  - `check_answerability`：`max_tokens` **800 → 4000**
  - `generate_orthogonal_query`：`max_tokens` **200 → 1500**（该调用要求 JSON 输出，200 在推理模型下必被吃空）
- **复验（同一批 32 QA）**：

  | 指标 | 补丁前 | 补丁后 |
  | --- | --- | --- |
  | Meta-Thinker 轮次总数 | 37 | **91（2.81 轮/QA）** |
  | 正交查询成功生成 | 4 | **61** |
  | "No orthogonal query" 中断 | 25 | 20 |

  检索环真正迭代起来，Strategic 档不再是伪单轮。**结论：Table 1 台阶有了可复现的前提。**
- **⚠️ 偏离记录**：以上 2 处为对**官方仓库快照**的修改（快照本身无 `.git`、未锁 commit）。这是复现所需的最小改动，需与论文原文交叉核对是否改变方法语义——按代码看仅影响"输出预算"，不改 prompt 与流程，故不改变方法本体。

### ⚠️ 保真度问题（新，20261015）· 构造期 Meta 指导约 95% 为空

**这是本次"台阶未复现"的重要解释变量，务必与上面的"截断"问题区分开。**

- **现象**：`bank_strategic` 构建共发起 **419 次**构造指导调用（`META_THINKER_CONSTRUCTION_PROMPT`），其中 **397 次（约 95%）返回空字符串**；仅 22 次有内容，形如：

  ```
  FACTS:
  - [Melanie] Melanie said "Bye" to Caroline.
  - [Melanie] Melanie told Caroline to have fun.
  ```

- **证据**：日志 `results/main/logs/memma_single_agent_20261015_141410.log` 中，`Meta-Thinker Construction Guidance:` 之后**紧跟空行**即代表 guidance 为空（源码 `logger.debug(f"Meta-Thinker Construction Guidance:\n{guidance}")`）。统计：该标记出现 **419** 次，其中仅 **22** 次下一行非空。
- **机制（⚠️ 推断，未单独验证）**：该调用给 `max_tokens=300`（[L3587](reproduction/code/memma/scripts/run_memma_self_refine_single.py#L3587)），而 `deepseek-flash` 是推理模型、reasoning token 计入 `completion_tokens`；300 被推理吃光后可见正文为空。**与已验证的 REPRO PATCH #1/#2 属同一类问题**（对照实验已证明 flash@800 截断、@4000 不截断）。
- **后果**：`meta_section` 仅在 guidance 非空时才拼进 prompt（[L366-L371](reproduction/code/memma/scripts/run_memma_self_refine_single.py#L366-L371)）→ **约 95% 的构造轮次里，`bank_strategic` 的 prompt 与 `bank_plain` 完全相同**。故本复现的 "Strategic Active" **实际只是"查询侧带 meta-thinker、构造侧几乎无指导"**。
- **对"记忆裁剪"的更正**：`bank_plain` 213 条 vs `bank_strategic` 130 条（-39%），**不能归因为"指导导致裁剪"**（指导基本为空）。更可能是 `temperature=0.3` 的采样差异在 ~340 次串行依赖调用中逐级放大；**每条件仅运行一次，无法与随机噪声区分**。
- **处置裁定（20261015 拍板）· 仅标注口径，不重建**：接受现状，把本复现的 Strategic 档明确记为"**查询侧指导生效、构造侧指导缺席**"，并在结论中声明该档**不等于**论文意义上的 Strategic Active。
  - 放弃的另一条路是"抬 `max_tokens` 到 1500–2000（新增 REPRO PATCH #6）后重建重跑（6–10 元）"。放弃理由：官方快照本就是 300，改它属保真度取舍；且即便修好构造指导，也无从保证台阶必然成立——问题已从"能否跑对"退化为"值不值得再花这笔钱"。
- **影响**：导致"台阶未复现"的归因**无法排除本项**——即**不能断言是"方法无效"，还是"我们没把它跑对"**。本复现的结论应读作："在**构造侧指导缺席**的部署下，三档台阶未出现"，而非对整个 MemMA 方法的否证。

### 仍待评估的风险（非阻塞）

- **judge 静默失败**：[evaluate_llm_judge](reproduction/code/memma/scripts/run_memma_self_refine_single.py#L547-L575) 无 `max_tokens`（走 API 默认），且**解析异常一律返回 0**。若某次 judge 输出被截断/非 JSON，ACC 会被静默拉低。跑分时需抽查 judge 失败率。

## 对官方快照的偏离清单（REPRO PATCH）

官方仓库快照**无 `.git`、未锁 commit**。以下为复现所做的最小改动，均带 `[REPRO PATCH]` 注释：

| # | 位置 | 改动 | 原因 |
| --- | --- | --- | --- |
| 1 | `check_answerability` | `max_tokens` 800 → **4000** | 推理模型下被截断，检索环早退（见"保真度问题"节）|
| 2 | `generate_orthogonal_query` | `max_tokens` 200 → **1500** | 同上；该调用要求 JSON 输出 |
| 3 | `LLMClient.__init__` | 新增 `max_retries=6` | 长任务（构建 ~340 次调用）经 HTTP 代理遇瞬时断连，默认重试 2 次不够，一次抖动即整体失败 |
| 4 | `LLMClient.get_completion` | `.content` → `.content or ""` | 截断时可能为 `None`，避免下游 `.strip()` 崩 |
| 5 | `evaluate_llm_judge` | `OpenAI(..., max_retries=6)`；`.content` 兜底 | 同上，且避免 judge 静默失败 |

> 判定：以上仅影响"输出预算 / 网络重试 / 空值兜底"，**不改 prompt、不改流程**，故不改变方法本体。

## 断点与续跑（2026-10-15）· 已全部解除

**✅ 阻塞已解除**：DeepSeek 上游过载于 2026-10-15 13:33 恢复（健康探测 `ok 3/3`，延迟 0.6–1.1s），原先列出的三条恢复命令**逐条跑通**。

**当天完成清单**

| 步骤 | 结果 | 用时 | 退出码 |
| --- | --- | --- | --- |
| 构建 `bank_plain`（213 条） | ✅ | 1605s | 0 |
| 构建 `bank_strategic`（130 条） | ✅ | 2945s | 0 |
| 评测 Static（152 QA） | ✅ | ≈15 min | 0 |
| 评测 Unguided（152 QA） | ✅ | ≈30 min | 0 |
| 评测 Strategic（152 QA） | ✅ | ≈115 min | 0 |

**当日结论**：❌ **台阶未复现**——详见上方「三档台阶复现结论（20261015）」节。

**已跑通的命令（留档，便于重跑）**

```powershell
# 1) 构建 Static/Unguided 共用库（全 19 会话，无构造指导）
.\run_deepseek.ps1 scripts\run_memma_self_refine_single.py --dataset data\locomo10.json `
  --memory-dir "<repr>\results\main\bank_plain" --output_dir "<repr>\results\main\build_plain" `
  --build_memories --model deepseek-flash --base_url https://api.deepseek.com `
  --max_samples 1 --self_refine_source none

# 2) 构建 Strategic 库（加构造期 Meta 指导）
#    同上，--memory-dir 换 bank_strategic、--output_dir 换 build_strategic，
#    并追加 --enable_construction_meta_guidance

# 3) 三档评测（--categories 1,2,3,4 = 152 QA；memory-dir 指向各自库）
.\run_deepseek.ps1 scripts\run_memma_self_refine_single.py --dataset data\locomo10.json `
  --memory-dir "<repr>\results\main\bank_plain" --output_dir "<repr>\results\main\eval_static" `
  --model deepseek-flash --base_url https://api.deepseek.com --max_samples 1 `
  --disable_meta_thinker --qr_max_turns 0 --categories "1,2,3,4"
#    Unguided  : 同上，换 --output_dir eval_unguided，flag 改 --disable_meta_thinker --qr_max_turns 5
#    Strategic : 同上，换 --memory-dir bank_strategic、--output_dir eval_strategic，flag 改 --qr_max_turns 5
```

**复盘：「卡在会话 1」为何不是代码问题（留档）**

- **症状**：构建在会话 1 首次 `MemoryManagerAgent.query` 处**僵死**，CPU 不涨、日志不动。
- **定位**：`py-spy dump` 抓栈显示卡在 `ssl.read → httpx2.iter_bytes`（**响应体读不完**）；TCP 为 CloseWait + Established；`timeout=120` 不触发（httpx 的 read 超时是"每次读"而非总时长）。
- **排除**：最小脚本复现成功；把 system prompt 换成一句平凡话**同样失败** → 与请求内容无关。绕开沙箱直连结果相同 → 与沙箱代理无关。
- **定因**：健康探测 `deepseek-flash` **0/6**、`deepseek-v4-pro` **0/3**，报 `503 Service is too busy` / `APITimeoutError` → **上游过载**（外部原因）。服务恢复后**同一命令一次跑通**。

## 何时值得重启（升级为完整复现）

- 官方仓库补齐了可复现的完整 pipeline 与示例数据，且 API 成本可规划（论文补报成本）；
- 或出现**更便宜的探针生成替代方案**（§G 已证明探针风格是瓶颈，若能换成开源/小模型探针且不掉点，全量复现的门槛显著下降）。