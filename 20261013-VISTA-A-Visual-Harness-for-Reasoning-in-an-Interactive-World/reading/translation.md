# 全文翻译 · VISTA: A Visual Harness for Reasoning in an Interactive World

> 逐段**中英对照**。学术术语保留英文原词并用括号标注。以原文为准，不自由发挥。
> 覆盖范围：Abstract 与正文 §1–§7（p.1–10）。**参考文献（p.11–14）不翻译**；附录 A.4（工具接口）、A.5（prompt）作要点翻译。
> 英文为据 p.1–10 页面图逐段誊录，中文为对应译文。

---

## Abstract / 摘要

**EN.** We show that multimodal models possess strong reasoning abilities and that an appropriate harness can unlock their potential to solve tasks across diverse interactive environments. We introduce VISTA, a visual harness that gives a general-purpose multimodal model long-horizon vision. VISTA allows the model to directly perceive the environment through visual observations and maintains a lossless visual memory that preserves past observations in their original form. The model can actively retrieve these observations and reorganize its visual input as it reasons. On ARC-AGI-3, VISTA improves Claude Opus 5.0's Relative Human Action Efficiency score from 40.68 to a perfect 100.00, with the model completing all 25 public games using 57.4% fewer actions than first-time human participants. VISTA's simple design also allows it to extend naturally to diverse visual environments with minimal adaptation. Across three additional benchmarks covering a diverse range of visual games and puzzles, it substantially outperforms baselines using the same underlying model with minimal harnesses. Our results highlight VISTA's potential as a general-purpose visual harness for advancing multimodal agents in complex visual environments.

**中.** 我们表明，多模态模型本身具备很强的推理能力，而一个恰当的 harness（外挂框架）可以释放它们跨多种交互式环境解题的潜力。我们提出 VISTA——一个视觉 harness，它为通用多模态模型赋予**长程视觉（long-horizon vision）**。VISTA 让模型通过视觉观测**直接感知环境**，并维护一份**无损视觉记忆（lossless visual memory）**，把过去的观测以其**原始形态**保存下来。模型可以在推理过程中**主动检索**这些观测并重组自己的视觉输入。在 ARC-AGI-3 上，VISTA 把 Claude Opus 5.0 的相对人类动作效率（Relative Human Action Efficiency, RHAE）分数从 40.68 提升到满分 100.00，且完成全部 25 个公开游戏所用的动作数比**首次游玩的**人类参与者少 57.4%。VISTA 的简洁设计还使它能够以**最小改动**自然地扩展到多样的视觉环境。在另外三个覆盖多样视觉游戏与谜题的基准上，它以同一底层模型、最小化的 harness，显著优于基线。我们的结果凸显了 VISTA 作为**通用视觉 harness**、推动多模态 agent 应对复杂视觉环境的潜力。

---

## 1. Introduction / 引言

**EN.** We live in a dynamic, high-dimensional world. As humans, we perceive our surroundings, reason about what we observe, and act based on our understanding and past experience. However, it remains unclear whether existing artificial intelligence (AI) systems have a similar ability to understand and interact robustly with the world, especially in unfamiliar environments.

**中.** 我们身处一个动态的、高维的世界。作为人类，我们感知周遭、对所观察到的内容进行推理，并基于我们的理解与过往经验采取行动。然而，现有的人工智能（AI）系统是否具备类似的能力——能否稳健地理解世界并与之交互，尤其是在**陌生环境**中——仍不清楚。

**EN.** To study this question, we use ARC-AGI-3, a suite of interactive visual games in which an agent needs to discover the rules and goals of unfamiliar worlds through interaction. This benchmark is typically approached as a language-based problem, with large language models (LLMs) receiving a textual or structured representation of the environment, as shown in Figure 1a. Building on this setup, a common strategy is to use code-based methods that construct a executable world model using symbolic programs.

**中.** 为研究这一问题，我们使用 ARC-AGI-3——一套交互式视觉游戏，agent 需要通过交互去**发现陌生世界的规则与目标**。该基准通常被当作**语言问题**来处理：让大语言模型（LLM）接收环境的文本或结构化表示，如图 1a 所示。在这套设定之上，一种常见策略是用**基于代码的方法**，通过符号程序构建一个**可执行的世界模型**。

**EN.** We instead reframe ARC-AGI-3 as a vision-based problem and address it using multimodal models. However, as illustrated in Figure 1b, existing vision-language models (VLMs) typically encode each image once into visual representations. These representations may not preserve the details needed as reasoning evolves. Moreover, earlier observations may be removed from the context or replaced by textual summaries to stay within the model's context limit. These limitations may constrain the models' reasoning capabilities during long-horizon interactions.

**中.** 我们则把 ARC-AGI-3 **重新表述为一个视觉问题**，并用多模态模型来解决。然而如图 1b 所示，现有的视觉-语言模型（VLM）通常把每张图**一次性编码**成视觉表征。这些表征可能无法保留推理推进过程中所需的细节。此外，为控制在模型上下文上限之内，早期观测可能被从上下文中**移除**，或被**替换成文本摘要**。这些限制可能在**长程交互**中制约模型的推理能力。

**EN.** To this end, we introduce VISTA, a visual harness that allows the model to actively reorganize its visual input during long-horizon interactions (Figure 1c). The model receives visual observations of the environment that preserve the appearance and spatial relations of objects. It develops its understanding of the environment through free-form language reasoning and uses this understanding to predict action outcomes and plan subsequent actions. Instead of relying solely on visual representations retained in the model's context, which may be compressed, lossy, and insufficient for subsequent reasoning, VISTA maintains a lossless visual memory. This memory stores every frame returned by the environment, including intermediate animation frames, in its original form. The model can retrieve observations from this memory through visual inspection, selecting frames to compare and spatial regions to examine at different levels of detail based on its current reasoning needs. Figure 2 shows two example agent trajectories with VISTA, illustrating how observation, reasoning, inspection, and action are interleaved.

**中.** 为此，我们提出 VISTA——一个视觉 harness，让模型在长程交互中**主动重组自己的视觉输入**（图 1c）。模型接收到的是保留物体外观与空间关系的视觉观测。它通过**自由形式的语言推理**建立对环境的理解，并据此预测动作结果、规划后续动作。模型上下文里保留的视觉表征可能被压缩、有损、不足以支撑后续推理；VISTA 不依赖于此，而是维护一份**无损视觉记忆**。这份记忆把环境返回的**每一帧**（包括中间的动画帧）都以原始形态保存。模型可以通过**视觉检查（visual inspection）**从记忆中检索观测：基于当前推理需要，选择要比较的帧、以及要以何种细节层级查看的空间区域。图 2 给出了两条 VISTA 的示例轨迹，展示观测、推理、检查、行动是如何交织进行的。

**EN.** With VISTA, Claude Opus 5.0 completes all 25 public ARC-AGI-3 games with a Relative Human Action Efficiency (RHAE) score of 100.00 with xhigh reasoning effort, using 57.4% fewer actions than the first-time human baseline. VISTA with GPT-5.6 Sol likewise completes all 25 games, achieving an RHAE score of 99.00 with max reasoning effort. To our knowledge, VISTA is the first vision-based system to achieve perfect or near-perfect performance on ARC-AGI-3 without program synthesis. For comparison, the organizers' official baselines, which also do not use programs, achieve RHAE scores of 40.68 with Opus 5.0 high and 13.33 with GPT-5.6 Sol max.

**中.** 借助 VISTA，Claude Opus 5.0 在 xhigh 推理档下完成全部 25 个公开 ARC-AGI-3 游戏，RHAE 分数达 100.00，所用动作比首次游玩的人类基线少 57.4%。GPT-5.6 Sol 搭配 VISTA 同样完成全部 25 个游戏，在 max 推理档下取得 RHAE 99.00。据我们所知，VISTA 是**首个在 ARC-AGI-3 上不借助程序合成即达到完美或近完美表现**的视觉系统。作为对比，同样不使用程序的官方基线在 Opus 5.0 high 下 RHAE 为 40.68、在 GPT-5.6 Sol max 下为 13.33。

**EN.** The simplicity of VISTA also allows it to extend naturally to other visual environments with minimal adaptation. We apply the same visual harness to 34 browser games from GameWorld, 10 browser games from AI GameStore, and 39 visual tracking problems from BabyVision. Together, these benchmarks cover a wide range of games and visual reasoning tasks that require skills such as complex reasoning, spatial navigation, and strategic planning. GPT-5.6 Sol with VISTA substantially outperforms baselines that use the same model with minimal harnesses. It also outperforms the novice human baseline on GameWorld and the human median baseline on AI GameStore. Overall, these results demonstrate VISTA's effectiveness across diverse visual environments and highlight visual harness design as an important direction for improving multimodal agents.

**中.** VISTA 的简洁性还使它能够以最小改动自然扩展到其他视觉环境。我们把同一套视觉 harness 应用到 GameWorld 的 34 个浏览器游戏、AI GameStore 的 10 个浏览器游戏，以及 BabyVision 的 39 个视觉追踪问题上。这些基准共同覆盖了广泛的游戏与视觉推理任务，所需能力包括复杂推理、空间导航与策略规划。GPT-5.6 Sol 搭配 VISTA 显著优于"同模型 + 最小 harness"的基线；它还在 GameWorld 上超过**新手人类基线**，在 AI GameStore 上超过**人类中位数基线**。总体而言，这些结果证明了 VISTA 在多样视觉环境中的有效性，并凸显**视觉 harness 设计**是改进多模态 agent 的一个重要方向。

---

## 2. Related Work / 相关工作

**EN.** *ARC-AGI benchmarks.* ARC-AGI-1 [14] and ARC-AGI-2 [15] are benchmarks designed to evaluate abstract reasoning over static input-output grids [16]. Approaches to these benchmarks often use pretrained large language models [1, 8, 9, 19, 26, 37], recurrent models [23, 50], or vision-based models [22]. ARC-AGI-3 [4] makes this setting interactive: an agent must explore novel environments, adapt continuously from its interactions, and take actions to achieve its goals [24]. Existing approaches to ARC-AGI-3 largely rely on program synthesis [11, 25, 39, 40, 62], in which agents perceive the environment through textual or symbolic representations and abstract it into programs that can be executed, verified, and searched over to guide actions. While effective on ARC-AGI-3, these approaches rely on constructing explicit programmatic abstractions of the environment. As environments become more visually complex, representing their states, transition dynamics, and goal conditions with explicit programs may become increasingly difficult. In contrast, VISTA operates directly on visual observations and reasons in natural language.

**中.** *ARC-AGI 基准。* ARC-AGI-1 [14] 与 ARC-AGI-2 [15] 是用于评估**静态输入-输出网格**上抽象推理的基准 [16]。针对这些基准的方法常使用预训练大语言模型 [1, 8, 9, 19, 26, 37]、循环模型 [23, 50] 或视觉模型 [22]。ARC-AGI-3 [4] 把这一设定变得**可交互**：agent 必须探索新环境、从交互中持续适应、并采取行动以达成目标 [24]。针对 ARC-AGI-3 的现有方法主要依赖**程序合成** [11, 25, 39, 40, 62]：agent 通过文本或符号表示感知环境，并将其抽象成可执行、可验证、可搜索的程序来指导行动。这类方法在 ARC-AGI-3 上有效，但依赖**显式的程序化抽象**。当环境在视觉上越来越复杂时，用显式程序去刻画其状态、转移动态与目标条件会越来越困难。相比之下，VISTA **直接在视觉观测上运行**，并用自然语言推理。

**EN.** *Computer-use agents.* Recent work has explored agents that interact with computers and graphical user interfaces to complete complex tasks. Existing approaches broadly differ in their observation space. Text-based approaches operate over structured representations of the interface, such as HTML, DOM trees, accessibility trees, or element identifiers, and use language models to reason over these representations and take symbolic actions. Vision-based computer-use agents interact directly with screenshots and take grounded actions such as clicks, mouse movements, and keyboard inputs. VISTA follows the vision-based paradigm: the agent reasons directly from visual observations rather than textual or symbolic representations of the environment. It focuses on a visual-centric harness for reasoning in interactive worlds and provides a simple interface for agents to observe and interact with the environment.

**中.** *计算机使用 agent（computer-use agents）。* 近期工作探索了与计算机和图形界面交互以完成复杂任务的 agent。现有方法主要在**观测空间**上不同。**基于文本**的方法在界面的结构化表示（如 HTML、DOM 树、无障碍树或元素标识符）上操作，用语言模型在这些表示上推理并采取符号动作。**基于视觉**的计算机使用 agent 则直接与**截图**交互，采取落到具体坐标的动作，如点击、鼠标移动、键盘输入。VISTA 遵循**基于视觉**的范式：agent 直接基于视觉观测推理，而非环境的文本或符号表示。它聚焦于一套**以视觉为中心的 harness**，用于在交互式世界中推理，并为 agent 提供观察和与环境交互的简单接口。

**EN.** *Game-playing agents.* Games have long served as testbeds for developing agents that learn to perceive, reason, and act in interactive environments. Classical approaches learn policies through reinforcement learning [31, 43, 44] or learn environment dynamics to support prediction and planning [21, 41]. While these methods provide general learning algorithms, they typically require training a separate agent for each game. More recently, foundation models have enabled more general-purpose agents that operate in richer game environments. Voyager uses a large language model together with structured Minecraft observations and an executable skill library [51], while JARVIS-1 incorporates visual observations and retrieves similar past experiences for planning in Minecraft [53]. Generalist agents such as SIMA and SIMA 2 [45, 46], Cradle [49], and Game-TARS [54] further operate directly from visual observations across multiple environments. A central challenge in these systems is retaining information over long interaction horizons: prior agents typically maintain only a bounded visual context or selectively store and compress past experiences. VISTA instead preserves the complete visual interaction history losslessly and allows the agent to actively revisit arbitrary previous frames and regions during reasoning.

**中.** *游戏 agent。* 游戏长期以来是开发 agent 的试验场，用于学习在交互环境中感知、推理与行动。经典方法通过**强化学习**学策略 [31, 43, 44]，或学习环境动态以支持预测与规划 [21, 41]。这些方法提供通用的学习算法，但通常需要**为每个游戏单独训练**一个 agent。近来，基础模型催生了能在更丰富游戏环境中运作的**通用 agent**。Voyager 用大语言模型结合结构化的 Minecraft 观测和可执行技能库 [51]；JARVIS-1 引入视觉观测并检索相似的过往经验来在 Minecraft 中规划 [53]。通用 agent 如 SIMA 与 SIMA 2 [45, 46]、Cradle [49]、Game-TARS [54] 更进一步，直接基于跨多个环境的视觉观测运作。这些系统的一个核心挑战是**在长交互时间跨度上保留信息**：此前的 agent 通常只维护**有界的**视觉上下文，或选择性地存储和压缩过往经验。VISTA 则**无损地**保留完整的视觉交互历史，并允许 agent 在推理中**主动重访**任意的历史帧与区域。

---

## 3. VISTA: A Visual Harness / VISTA：一个视觉 harness

**EN.** VISTA lets the model directly perceive the environment through visual inputs. However, existing multimodal systems typically encode visual observations once and discard the raw inputs. As the context fills, these representations may be removed or replaced by textual summaries, and the model may not control what is retained. More importantly, the model may not know at encoding time which visual information will matter later: a representation sufficient at one stage may omit details required in subsequent reasoning steps.

**中.** VISTA 让模型通过视觉输入**直接感知环境**。然而，现有多模态系统通常**一次性编码**视觉观测并丢弃原始输入。随着上下文填满，这些表征可能被移除或被文本摘要替换，而模型**无法控制**保留了什么。更重要的是，模型在编码时**并不知道哪些视觉信息之后会变得重要**：在某一阶段足够用的表征，可能遗漏后续推理步骤所需的细节。

**EN.** These limitations directly motivate the design of VISTA, which preserves original observations in a lossless visual memory and provides tools for the model to retrieve and inspect them during interaction. This allows the model to revisit visual evidence and reorganize its visual input as it reasons, without requiring all relevant information to be captured in the initial visual encoding and retained in the model's context.

**中.** 这些限制直接构成了 VISTA 的设计动机：它把原始观测保存在**无损视觉记忆**中，并为模型提供工具，在交互中检索与检查它们。这让模型得以在推理时**重访视觉证据、重组视觉输入**，而**无需**把全部相关信息都塞进初始视觉编码并留住上下文里。

### 3.1 Visual Harness Components / 视觉 harness 组件

**EN.** We introduce three key visual harness components: *visual observations*, which allows the agent to perceive the environment through rendered images; *lossless visual memory*, which preserves visual observations in their original form; and *visual inspection*, which allows the model to revisit visual evidence and examine details as needed. Together, these components provide the model with an explicit attention mechanism over the interaction history, allowing it to select which frames and regions to examine during reasoning.

**中.** 我们引入三个关键的视觉 harness 组件：*视觉观测（visual observations）*，让 agent 通过渲染图像感知环境；*无损视觉记忆（lossless visual memory）*，以原始形态保存视觉观测；*视觉检查（visual inspection）*，让模型按需重访视觉证据、细查细节。三者共同为模型提供了对交互历史的**显式注意力机制**，使其能在推理中选择要检查的帧与区域。

**EN.** *Visual observation.* The model receives visual observations from the environment (Figure 3a). These observations preserve the appearance and spatial relation of objects, allowing the model to use its learned visual priors to interpret and reason about the environment.

**中.** *视觉观测。* 模型从环境接收视觉观测（图 3a）。这些观测保留物体的外观与空间关系，使模型能够运用其习得的**视觉先验**来理解并推理环境。

**EN.** *Lossless visual memory.* The harness stores every frame returned by the environment, including intermediate animation frames, in its original form (Figure 3b). Each frame is indexed by turn and frame number and remains available throughout the interaction, independently of what is retained in the model's current context.

**中.** *无损视觉记忆。* harness 把环境返回的**每一帧**（包括中间动画帧）以原始形态保存（图 3b）。每一帧以 `turn` 与 `frame` 编号索引，在整个交互过程中都可用，**独立于**模型当前上下文里保留了什么。

**EN.** *Visual inspection.* Building on the visual memory, we provide the agent with tools to actively inspect visual information in space and across time (Figure 3c). In space, it can request an enlarged view of any rectangular region from the original frame, allowing it to examine fine-grained details that may be difficult to perceive in the full image. Across time, it can retrieve and inspect multiple frames from arbitrary earlier turns to revisit visual evidence, compare states, and replay how an action unfolded through its intermediate animation frames. At each turn, the model is free to decide whether to inspect its visual memory and which frames or regions to examine.

**中.** *视觉检查。* 在视觉记忆之上，我们给 agent 提供工具，去**在空间上和时间上**主动检查视觉信息（图 3c）。**空间上**，它可以请求对原始帧中任一矩形区域**放大查看**，从而细看整图中难以察觉的细节。**时间上**，它可以调取任意早期轮次的多帧来重访视觉证据、比较状态，并**回放**一个动作在其中间动画帧中如何展开。每一轮里，模型可自由决定是否检查视觉记忆、以及检查哪些帧或区域。

### 3.2 Pipeline / 流程

**EN.** In our pipeline, the model and the harness interact through a multi-turn conversation (Figure 2). The harness is purely mechanical and does not involve any trained model: it executes tool calls requested by the model, returns outputs such as images or pixel values, and reports errors for invalid requests. The model reasons over these outputs and issues its next request to the harness if needed.

**中.** 在我们的流程中，模型与 harness 通过**多轮对话**交互（图 2）。harness 是**纯机械**的、不涉及任何被训练的模型：它执行模型请求的工具调用，返回图像或像素值等输出，并对非法请求报错。模型在这些输出上推理，必要时向 harness 发出下一个请求。

**EN.** A single agent interacts with each game throughout the run. Each game turn may include multiple exchanges with the harness before the agent executes one game action (Figure 3d). At the start of a turn, the agent receives the current visual state and available actions. It can also consult two notes that it maintains: GUIDE.md, which records its understanding of the game and information that may remain useful across levels, and WORKING.md, which serves as a scratchpad for the current state. Through inspect, the agent can revisit earlier observations, including intermediate animation frames produced by its previous actions. It can also use read_pixels to examine pixel values within a selected region. Consulting the notes and using the inspection tools are optional and left to the agent's decision.

**中.** 整局中由**单个 agent** 与游戏交互。每个游戏轮次可能包含与 harness 的多次交换，然后 agent 才执行**一个**游戏动作（图 3d）。轮次开始时，agent 接收当前视觉状态与可用动作。它还可以查阅自己维护的两份笔记：`GUIDE.md` 记录其对游戏的理解、以及可能在各关卡间持续有用的信息；`WORKING.md` 作为当前状态的草稿本。通过 `inspect`，agent 可以重访更早的观测，包括其先前动作产生的中间动画帧；也可以用 `read_pixels` 检查选定区域内的像素值。查阅笔记与使用检查工具都是**可选**的，交由 agent 决定。

**EN.** The agent uses free-form language to reason and plan. It predicts the outcome of its planned action, revises its notes to reflect its updated understanding of the environment, and calls play to execute the chosen action and advance to the next game turn. When its context approaches the limit, the agent writes a concise handoff summary and resumes from the current state in a fresh context. Its notes (GUIDE.md, WORKING.md), visual memory, and action history remain available.

**中.** agent 用**自由形式的语言**推理与规划。它预测所规划动作的结果，更新笔记以反映其对环境的最新理解，并调用 `play` 执行所选动作、推进到下一个游戏轮次。当其上下文接近上限时，agent 写下**简明的交接摘要**，并在**新上下文**中从当前状态继续。其笔记（`GUIDE.md`、`WORKING.md`）、视觉记忆与动作历史依然可用。

**EN.** Every game uses the same interface and short prompt as in Appendix A.5. The available tools (e.g., inspect, read_pixels, and play), together with their pseudocode and corresponding descriptions are provided to the agent, as shown in Appendix A.4.

**中.** 每个游戏都用**相同的接口**与简短 prompt（见附录 A.5）。可用工具（如 `inspect`、`read_pixels`、`play`）连同其伪代码与相应说明一并提供给 agent，见附录 A.4。

---

## 4. VISTA on ARC-AGI-3 / VISTA 在 ARC-AGI-3 上的表现

### 4.1 Setup / 实验设置

**EN.** *Dataset.* ARC-AGI-3 [4] consists of interactive visual games whose rules and objectives are not provided explicitly. We evaluate on the 25 public games. At each step, the agent observes the current visual state, selects an available action, and uses the resulting observation to infer object roles, transition rules, hidden states, and possible goals. Each game contains multiple levels that share underlying mechanics while introducing new objects, layouts, or constraints. The agent therefore needs to retain and apply previously inferred knowledge across levels while continuously adapting its understanding through interaction. Figure 4 shows an example agent trajectory.

**中.** *数据集。* ARC-AGI-3 [4] 由交互式视觉游戏构成，其规则与目标**不显式给出**。我们在 25 个公开游戏上评估。每一步，agent 观察当前视觉状态、选择一个可用动作，并用由此得到的观测去推断**物体角色、转移规则、隐藏状态与可能目标**。每个游戏含多个关卡，关卡共享底层机制、同时引入新物体/布局/约束。因此 agent 需要**跨关卡保留并运用**此前推断出的知识，同时通过交互不断修正理解。图 4 给出一条示例轨迹。

**EN.** *Evaluation metrics.* Performance is measured by Relative Human Action Efficiency (RHAE) [6], which compares an agent's action efficiency with that of first-time human players. A completed level receives 100% credit when its action count matches the human baseline, up to 115% when it uses fewer actions, and partial credit when it uses more actions. Unfinished levels receive zero credit. Later levels receive greater weight, and each game score is capped by the weighted fraction of levels completed. See Appendix A.3 for details.

**中.** *评估指标。* 表现以**相对人类动作效率（RHAE）** [6] 衡量，它把 agent 的动作效率与**首次游玩的人类玩家**作比较。完成的关卡在动作数与人**基线持平**时得 100% 分，动作更少时最多到 115%，动作更多时得**部分分**；未完成的关卡得 0 分。越靠后的关卡权重越大，每个游戏的得分被**加权完成的关卡比例**封顶。细节见附录 A.3。

**EN.** *Models.* We instantiate VISTA with two general-purpose, closed-weight multimodal model backends commonly used in prior work. Each backend is evaluated independently under the same interaction protocol. We use Claude Opus 5.0 [3] run with extra-high reasoning effort through the Claude Code CLI and GPT-5.6 Sol [33] run with max reasoning effort through the Codex CLI.

**中.** *模型。* 我们为 VISTA 配备两个前人工作中常用的**通用、闭权重**多模态模型后端。每个后端在**相同的交互协议**下独立评估。我们使用 Claude Opus 5.0 [3]（经 Claude Code CLI，extra-high 推理档）与 GPT-5.6 Sol [33]（经 Codex CLI，max 推理档）。

### 4.2 Results / 结果

**EN.** Table 1 shows a system-level comparison on the 25 public ARC-AGI-3 games, unless otherwise noted. With Claude Opus 5.0, VISTA achieves a perfect RHAE score of 100.00, matching other state-of-the-art systems. It uses 7,302 actions in total, 57.4% fewer than the human reference of 17,135 actions.

**中.** 表 1 给出 25 个公开 ARC-AGI-3 游戏上的系统级对比（另有说明者除外）。使用 Claude Opus 5.0 时，VISTA 取得**满分 RHAE 100.00**，与其他 SOTA 系统持平。它总共用 **7,302** 个动作，比人类参考的 17,135 个**少 57.4%**。

**EN.** Most of the compared systems come from concurrent work. These systems typically represent observations as text-based numerical grids and often reason using a code-based world model: the agent abstracts the environment into symbolic programs that can be executed and checked during exploration. To our knowledge, VISTA is the first system to achieve perfect or near-perfect performance on ARC-AGI-3 without program synthesis. For comparison, the same model scores only 40.68 under the official implementation. In Figure 6, we also compare textual grids with our default image observations. We find that visual observations achieve comparable performance with fewer actions while using significantly fewer tokens.

**中.** 被比较的系统大多来自同期工作。这些系统通常把观测表示为**基于文本的数值网格**，并常用**基于代码的世界模型**推理：agent 把环境抽象成可在探索中执行与校验的符号程序。据我们所知，VISTA 是**首个在 ARC-AGI-3 上无需程序合成即达完美/近完美**的系统。作为对比，同一模型在官方实现下仅得 40.68。图 6 中我们还对比了文本网格与默认图像观测，发现**视觉观测以更少动作取得相当表现，同时显著减少 token**。

### 4.3 Ablations / 消融

**EN.** For all ablations, we use GPT-5.6 Sol with max reasoning effort and a 200K-token context limit as the default setting. The agent receives a 512 × 512 PNG image of the current rendered state, obtained by 8× nearest-neighbor upscaling of the official 64 × 64 frame.

**中.** 所有消融默认使用 GPT-5.6 Sol（max 推理档）与 **200K token** 上下文上限。agent 收到的是当前渲染状态的 **512×512 PNG**，由官方 64×64 帧经 **8× 最近邻上采样**得到。

**EN.** *Effects of VISTA components.* We compare GPT-5.6 Sol under progressively richer harness configurations in Figure 5. The official implementation uses textual grids and has a reported RHAE score of 13.33 with 10,619 actions [5, 34]. Replacing these textual grids with rendered PNG images (i) increases the score to 47.32, demonstrating the importance of visual observations. The low action count is partly due to runs reaching the action or time limit before completing the games, as suggested by the low completion rate in this configuration. Increasing the action and time limits improves the score to 51.66 (ii). In (iii), we introduce a minimal agent harness that maintains a continuous conversation and uses native compaction to continue beyond its context limit, improving the score to 65.82. Configuration (iv) adds two note files, GUIDE.md and WORKING.md, along with instructions encouraging the agent to build a compact and revisable model of the game, further improving the score to 70.05 (see the prompt in Appendix A.5). Finally, configurations (v)–(vi) introduce VISTA's key visual harness components: adding lossless visual memory and model-directed inspection (v) improves the score to 94.10, while exact pixel readout (vi), which provides numerical RGB values for selected pixels, completes the VISTA harness and increases the score to 99.00.

**中.** *VISTA 各组件的效果。* 图 5 中我们在逐步增强的 harness 配置下比较 GPT-5.6 Sol。官方实现用文本网格，报告 RHAE 为 13.33、10,619 个动作 [5, 34]。把这些文本网格换成渲染的 PNG 图像（i）把分数提到 **47.32**，说明**视觉观测的重要性**。动作数偏低，部分是因为在该配置下完成率低——多局在完成前就撞到了动作或时间上限。提高动作与时间上限（ii）把分数提到 **51.66**。（iii）我们引入一个**最小 agent harness**：维持连续对话，并用原生上下文压缩在超过上下文上限后继续，分数提到 **65.82**。（iv）加入两个笔记文件 `GUIDE.md` 与 `WORKING.md`，并指示 agent 建立一个**紧凑、可修正**的游戏模型，进一步提到 **70.05**（见附录 A.5 的 prompt）。最后，（v）–（vi）引入 VISTA 的核心视觉 harness 组件：加入**无损视觉记忆 + 模型导向的检查（model-directed inspection）**（v）把分数提到 **94.10**；再用**精确像素读取（exact pixel readout）**（vi）为选定像素提供数值 RGB 值，补全 VISTA harness，把分数提到 **99.00**。

**EN.** *Reasoning directly from images.* Prior approaches to ARC-AGI-3 commonly represent each frame as a textual grid, encoding observations as rows of integer color indices [11, 25, 39, 62]. In contrast, VISTA reasons directly from rendered images. We ablate this design choice by replacing VISTA's image observations with textual grids while keeping the rest of the harness unchanged. As shown in Figure 6, using textual grids maintains comparable performance but slightly increases the total number of actions. Textual grids are also substantially more token-intensive: a 64 × 64 grid requires roughly 4,000 tokens, compared with approximately 308 image tokens for our default 512 × 512 observation. Token usage per game is 71.9M with textual grids and 30.7M with image observations.

**中.** *直接从图像推理。* 此前针对 ARC-AGI-3 的方法通常把每一帧表示为**文本网格**，把观测编码为若干行整数颜色索引 [11, 25, 39, 62]。相比之下，VISTA **直接从渲染图像推理**。我们在保持 harness 其余部分不变的前提下，用文本网格替换 VISTA 的图像观测来消融这一设计：如图 6 所示，文本网格表现相当，但**动作总数略增**；且文本网格**明显更耗 token**——一个 64×64 网格约需 **4,000 token**，而默认 512×512 观测约 **308 image token**。每局 token 用量：文本网格 **71.9M**，图像观测 **30.7M**。

**EN.** *Effect of maximum context size.* We vary VISTA's maximum context size, which determines how much interaction history is retained before the agent compacts its history and resumes in a fresh context. As shown in Figure 7a, the default 200K setting achieves the highest RHAE of 99.00. Larger contexts are substantially more expensive: 780K consumes 105.7M tokens per game, compared with 30.7M at 200K. Reducing the context to 100K lowers RHAE by only 0.4 while roughly halving token usage, showing that the harness remains effective even with shorter contexts.

**中.** *最大上下文规模的影响。* 我们变化 VISTA 的最大上下文规模——它决定了 agent 在压缩历史、于新上下文继续之前，能保留多少交互历史。如图 7a，默认 **200K** 取得最高的 **RHAE 99.00**。更大的上下文**明显更贵**：780K 每局消耗 **105.7M token**，而 200K 为 30.7M。把上下文降到 **100K** 只让 RHAE 降 **0.4**，token 用量却近乎减半，说明 harness 在更短上下文下**依然有效**。

**EN.** *Effect of input image scale.* We vary the input image scale to study the trade-off between visual resolution and image token usage. The 2×, 4×, 8×, and 16× scales correspond to 128, 256, 512, and 1,024 pixels per side, requiring approximately 20, 77, 308, and 1,229 image tokens per frame, respectively. As shown in Figure 7b, 4× uses 75% fewer image tokens than the default 8× while achieving comparable performance. Reducing the scale to 2× degrades performance, while increasing it to 16× provides no additional benefit and costs more tokens per game, likely because the extra image tokens consume context without improving visual reasoning.

**中.** *输入图像尺度的影响。* 我们变化输入图像尺度，研究**视觉分辨率与 image token 用量**之间的权衡。2×、4×、8×、16× 分别对应每边 128、256、512、1024 像素，每帧约需 **20、77、308、1229** 个 image token。如图 7b，**4×** 比默认 8× 少用约 **75%** 的 image token，表现却相当。降到 **2×** 会掉点；升到 **16×** 无额外收益、每局更贵——很可能是因为多出来的 image token 只是**占了上下文但没有提升视觉推理**。

**EN.** *Results with an open-weight model.* We additionally evaluate VISTA with the open-weight backend GLM-5.3 Flash 320B [20, 63]. This gives a fully open-source and reproducible system. Figure 8 compares the RHAE scores of three configurations: the organizers' official implementation, which we ran with its minimal harness; VISTA without the visual harness, which removes only inspect and read_pixels tools; and full VISTA. VISTA achieves an RHAE score of 66.93, substantially outperforming the official baseline. These results further support VISTA's effectiveness across model backends.

**中.** *开源权重模型上的结果。* 我们还用开源权重后端 GLM-5.3 Flash 320B [20, 63] 评估 VISTA，从而得到一个**完全开源、可复现**的系统。图 8 对比三种配置的 RHAE：组织者的官方实现（我们以最小 harness 运行）、**去掉视觉 harness 的 VISTA**（仅移除 `inspect` 与 `read_pixels` 两个工具）、以及完整 VISTA。完整 VISTA 取得 **RHAE 66.93**，显著优于官方基线。这些结果进一步支持 VISTA 在**不同模型后端**上的有效性。

**EN.** *Effects of 3D rendering.* We evaluate VISTA under more challenging visual conditions by rendering the same games in 3D. As shown in Figure 9, the model achieves an RHAE score of 84.12 with 20,640 actions. Although VISTA requires substantially more interaction with these renderings than with the default 2D images, it still achieves strong performance and outperforms officials textual baselines by a large margin. These results demonstrate its robustness to more complex visual representations and its ability to generalize beyond 2D representations. As we further show in Section 5, VISTA remains effective across a broader range of visual environments, including 3D games.

**中.** *3D 渲染的影响。* 我们把同一批游戏渲染成 **3D** 以在更具挑战的视觉条件下评估 VISTA。如图 9，模型取得 **RHAE 84.12**、**20,640** 个动作。虽然相比默认 2D 图像，VISTA 在这些渲染上需要**多得多的交互**，它仍取得很强表现、并**大幅超过官方文本基线**。这些结果展示了它对更复杂视觉表征的**鲁棒性**，以及在 2D 表征之外泛化的能力。如 §5 进一步所示，VISTA 在包括 3D 游戏在内的更广泛视觉环境中**依然有效**。

### 4.4 Qualitative Analysis / 定性分析

**EN.** The key components of the VISTA harness are lossless visual memory and visual inspection, which allow the agent to revisit stored visual information at any point during interaction. These components provide a form of explicit attention over interaction history. Here, we show qualitative examples of how agents benefit from this re-attention mechanism. Figure 10a illustrates re-attention across space and time. The agent revisits earlier frames to recover information that is no longer visible in its current observation. In this example, it inspects frames from different points in the trajectory and integrates their information to reconstruct the overall map. Figure 10b illustrates re-attention to local visual details. The agent selectively zooms into a small region of a stored observation to determine a block's orientation, which is difficult to see clearly in the full 512 × 512 frame. Together, these examples illustrate two complementary forms of re-attention enabled by lossless visual memory: integrating visual evidence across the interaction history and inspecting local details at the granularity required by the current task.

**中.** VISTA harness 的关键组件是**无损视觉记忆**与**视觉检查**，它们让 agent 能在交互中的任意时刻重访已存的视觉信息。这些组件构成了一种对交互历史的**显式注意力**。这里，我们给出定性例子，展示 agent 如何从这种"再注意（re-attention）"机制中获益。图 10a 展示**跨空间与时间的再注意**：agent 重访更早的帧，恢复当前观测中已不可见的信息——在本例中，它检查轨迹上不同时刻的帧，并整合信息**重建整体地图**。图 10b 展示**对局部视觉细节的再注意**：agent 选择性地放大已存观测中的一小块区域，以判断某个方块的**朝向**——这在完整 512×512 帧里很难看清。两个例子共同说明无损视觉记忆带来的两种互补的再注意形式：**跨交互历史整合视觉证据**，以及**按当前任务所需的粒度细查局部细节**。

---

## 5. General Visual Environments / 通用视觉环境

**EN.** VISTA's general-purpose design allows us to naturally apply the same visual harness to other benchmarks with minimal adaptation. We evaluate VISTA on two interactive game benchmarks: GameWorld [35] and AI GameStore [60]. We also evaluate on a static visual reasoning benchmark, BabyVision [12], to examine the role of visual inspection without interaction with a dynamic environment. For each benchmark, we compare VISTA with the official implementation using the same model. We also report human performance and the best previously reported result as references. See Appendices A.3 and A.6 for details. Figure 11 shows an overview of these environments. Appendix Figure 14 shows example VISTA trajectories on both interactive and static tasks.

**中.** VISTA 的通用设计使我们能以最小改动把同一套视觉 harness 自然地应用到其他基准。我们在两个交互式游戏基准上评估 VISTA：GameWorld [35] 与 AI GameStore [60]；并在一个静态视觉推理基准 BabyVision [12] 上评估，以考察**在没有与动态环境交互时**视觉检查的作用。对每个基准，我们把 VISTA 与"使用同模型的官方实现"比较，并报告人类表现与此前最佳报告结果作为参考。细节见附录 A.3 与 A.6。图 11 概述这些环境；附录图 14 展示交互式与静态任务上的示例 VISTA 轨迹。

### 5.1 Setup / 设置

**EN.** *GameWorld.* GameWorld [35] contains 34 browser games with 170 tasks across five genres: arcade, platformer, puzzle, runner, and simulation. The agent receives only the official task prompt, available controls, and screenshots. We evaluate VISTA using the computer-use interface, through which the agent interacts with the games directly via keyboard and mouse actions. We report success rate (SR), defined as the fraction of the 170 tasks completed, and progress (PG), which also credits partial completion. Both metrics are computed by the benchmark's official evaluator.

**中.** *GameWorld。* GameWorld [35] 含 34 个浏览器游戏、170 个任务，横跨五类：街机、平台跳跃、解谜、跑酷、模拟。agent 只收到官方任务提示、可用控制与截图。我们用**计算机使用接口**评估 VISTA：agent 通过键盘与鼠标动作直接与游戏交互。我们报告**成功率（SR）**（170 个任务中完成的比例）与**进度（PG）**（也计入部分完成）。两项指标均由基准官方评估器计算。

**EN.** *AI GameStore.* AI GameStore [60] contains 10 public browser games. The agent receives only the public game description, controls, and visual observations. Through interaction, it must infer the game dynamics and determine how to achieve the objectives. Each game uses its own scoring system. Following the benchmark's official protocol, we normalize each raw score so that the corresponding published human median equals 100, then compute the geometric mean of the normalized scores across the ten games.

**中.** *AI GameStore。* AI GameStore [60] 含 10 个公开浏览器游戏。agent 只收到公开的游戏描述、控制与视觉观测。它必须通过交互推断游戏动态、确定如何达成目标。每个游戏有自己的评分系统。遵循基准官方协议，我们归一化每个原始分，使对应发布的**人类中位数等于 100**，再对十个游戏的归一化分取**几何均值**。

**EN.** *BabyVision.* BabyVision [12] contains 388 static visual reasoning tasks across 22 subclasses. Each task consists of a static image and a question. The agent perceives the image and can decide which visual regions to inspect and which pixels to read. We evaluate on the 39 questions from two Visual Tracking subtypes: 20 maze tasks and 19 connecting-lines tasks. We report accuracy across these tasks.

**中.** *BabyVision。* BabyVision [12] 含 22 个子类共 388 个静态视觉推理任务。每个任务由一张静态图像与一个问题构成。agent 感知图像，并可决定检查哪些视觉区域、读取哪些像素。我们在两个**视觉追踪**子类的 39 个问题上评估：20 个迷宫任务与 19 个连线任务，报告这些任务上的**准确率**。

### 5.2 Results / 结果

**EN.** Figure 11 shows our results. Across all three benchmarks, VISTA consistently outperforms the corresponding baselines with minimal harness. VISTA also exceeds the reported performance of fresh human players on GameWorld and AI GameStore. On BabyVision, where observations are static and no interaction history is involved, VISTA improves accuracy from 41.0% with the official implementation to 63.2%, highlighting the benefit of visual inspection, which allows the agent to selectively inspect regions within a single image.

**中.** 图 11 给出我们的结果。在全部三个基准上，VISTA 以最小 harness **一致优于**对应基线；它还在 GameWorld 与 AI GameStore 上**超过**所报告的新手人类玩家表现。在 BabyVision 上——观测是静态的、不涉及交互历史——VISTA 把准确率从官方实现的 **41.0%** 提到 **63.2%**，凸显**视觉检查**的收益：它让 agent 能在**单张图像内**选择性地检查区域。

---

## 6. Limitations / 局限性

**EN.** We acknowledge that the models' existing capabilities remain a key factor in this success, and VISTA provides a simple but effective way to elicit them. Its substantial gains over the baselines highlight visual harness design as a direction that complements model improvements. Additionally, because the models we use were released after the public benchmarks, we cannot rule out that those games were included in their training data. Evaluation on novel games, such as those in the private set of ARC-AGI-3 [4], would provide a stronger test of our system's generalization.

**中.** 我们承认，模型的**既有能力**仍是这一成功的关键因素，VISTA 只是提供了一种简单而有效的方式来**引出**它们。它相对基线的大幅增益凸显了**视觉 harness 设计**是一个与模型改进**互补**的方向。此外，由于我们使用的模型是在这些公开基准**发布之后**才发布的，我们**无法排除**这些游戏被包含在其训练数据中。在**新游戏**上评估——例如 ARC-AGI-3 私有集中的游戏 [4]——将为系统泛化能力提供更有力的检验。

---

## 7. Conclusion / 结论

**EN.** VISTA shows that a simple visual harness can unlock the potential of existing multimodal models to complete complex tasks in interactive visual environments. It provides the model with raw visual observations, preserves them in a lossless visual memory, and allows the model to revisit past visual experience at the original level of detail during interaction. We show that this simple design is sufficient for the agent to complete all 25 public ARC-AGI-3 games with a perfect score. The same harness extends naturally to other environments covering a diverse set of visual games and puzzles, with minimal adaptation. Overall, VISTA's simple design and strong performance across diverse benchmarks suggest its potential as a general-purpose harness for tasks beyond games. Future work could evaluate VISTA on more complex and realistic tasks, such as embodied tasks in environments that more closely resemble the physical world [10].

**中.** VISTA 表明，一个简单的视觉 harness 可以**释放**现有多模态模型在交互式视觉环境中完成复杂任务的潜力。它为模型提供原始视觉观测，把它们保存在**无损视觉记忆**中，并允许模型在交互中**以原始细节层级**重访过去的视觉经验。我们证明，这一简单设计足以让 agent 以**满分**完成全部 25 个公开 ARC-AGI-3 游戏。同一 harness 以最小改动自然扩展到覆盖多样视觉游戏与谜题的其他环境。总体而言，VISTA 的简洁设计与在多样基准上的强劲表现，表明它有潜力成为**游戏之外任务的通用 harness**。未来工作可在更复杂、更真实的任务上评估 VISTA，例如在更接近物理世界的环境中的具身任务 [10]。

---

## 附录要点翻译（摘要）

### A.4 Agent Tools / Agent 工具（p.17）

**EN (要点).** The agent accesses tools only through structured function calls; plain text generated by the model cannot trigger tool execution. In Claude Code, we expose these tools through an MCP server and disable all built-in tools, preventing direct shell or file-system access. In Codex, we register the same tools directly with the app. In both cases, the agent runs in a sandboxed container without access to environment credentials. A single host-side controller handles all tool calls. The controller maintains the environment connection, archived frames, GUIDE.md, and WORKING.md, and is the only component allowed to advance the game. It also enforces sequential interaction: a new play call is accepted only after the result of the previous action has been returned to the agent. Each returned image is labeled with its turn and frame index.

**中 (要点).** agent 仅通过**结构化函数调用**访问工具；模型生成的纯文本**无法触发**工具执行。在 Claude Code 中，这些工具经 **MCP server** 暴露，并**禁用所有内置工具**，以防直接访问 shell 或文件系统。在 Codex 中，同样的工具直接注册到 app。两种情况下，agent 都运行在**沙箱容器**中、**无法访问环境凭证**。一个**单进程 host-side controller** 处理所有工具调用：它维护环境连接、存档帧、`GUIDE.md` 与 `WORKING.md`，并且是**唯一**被允许推进游戏的组件；它还强制**串行交互**——只有在上一动作结果返回给 agent 后，新的 `play` 调用才会被接受。每张返回的图像都标注其 `turn` 与 `frame` 索引。

### A.5 Agent Prompts / Agent 提示词（p.18）

**EN (ARC-AGI-3, Prompt 1).** Complete the game with as few game actions as possible. Build and use a compact, revisable model of the game and its current state. Update it as new evidence changes what is supported. Before each 'play', briefly state what you expect to see. Afterward, briefly state all visible changes, expected or not. Keep concise, durable, revisable game understanding in 'GUIDE.md'; use 'WORKING.md' as a scratchpad when useful.

**中（ARC-AGI-3，Prompt 1）.** 以**尽可能少的游戏动作**完成游戏。建立并使用一个**紧凑、可修正**的游戏及其当前状态模型，并随新证据改变其可信内容而更新。每次 `play` 前，简要说明你**预期看到什么**；之后，简要说明**所有可见的变化**（无论是否预期）。把简明、持久、可修正的游戏理解写进 `GUIDE.md`；需要时把 `WORKING.md` 当草稿本。

> GameWorld / AI GameStore 用同一模板的 "Interactive world task"（把 `play` 换成 `act`，并原样纳入基准提供的任务提示）；BabyVision 用更短的 "Visual question task"（无持久笔记，保留 `inspect`/`read_pixels`，要求先收集证据再作答）。