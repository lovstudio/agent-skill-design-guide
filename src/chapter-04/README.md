# 第 4 章：Skill 质量模型 — 如何定义和衡量「高质量」

![质量五维度 — 天平上的五颗宝石](../assets/images/chapters/ch04-quality-model.png)


> "Not everything that counts can be counted, and not everything that can be counted counts."
> — William Bruce Cameron

在第 2-3 章中，我们已经了解了 Skill 的架构和规范。但掌握规范只是入门——就像知道 Python 语法不等于写得出优雅的代码，符合 SKILL.md 格式不等于写出了高质量的 Skill。

本章是全书的理论核心。我们将回答一个根本问题：**什么是「高质量」的 Skill，如何系统地衡量它？**

我们将提出一个五维度质量模型，结合业界首个 Skill 基准测试 SkillsBench 的实证数据，以及 agentskills.io 平台的评审标准，构建一套从理论到实践的完整质量评估框架。最后，我们用 `lovstudio:fill-form` 的真实迭代历程作为案例，展示质量模型如何指导 Skill 的持续改进。

---

## 4.1 为什么需要质量模型

你可能会问：Skill 不就是一段给 AI 的指令吗，有什么「质量」可言？

这个问题的答案藏在 SkillsBench（arXiv: 2602.12670）的一组数据中：研究者对 86 个任务、7 种 Agent-模型配置进行了 7,308 次执行轨迹测试，发现 **curated Skills 平均提升 pass rate 16.2 个百分点，但其中 16 个任务反而出现了负面效果**。更惊人的是，**模型自己生成的 Skills 平均 pass rate 比不用 Skill 还低 1.3 个百分点**。

这说明三件事：

1. **Skill 质量差异巨大**——好的 Skill 能让小模型追平大模型的表现，差的 Skill 反而拖后腿
2. **质量不是自动涌现的**——即使是最强的 LLM 也无法可靠地自动生成高质量 Skill
3. **我们需要一套标准来定义、衡量和追踪 Skill 质量**——否则改进就是盲人摸象

## 4.2 质量五维度模型

经过对 30+ 个 Skill 的设计、迭代和生产使用经验总结，结合 SkillsBench 的实证研究和 agentskills.io 的评审标准，我们提出 **Skill 质量五维度模型（Five-Dimension Quality Model, 5DQM）**：

| 维度 | 英文名 | 核心问题 | 衡量方式 |
|------|--------|---------|---------|
| **D1 触发准确率** | Trigger Precision | description 能否在正确场景被精准激活？ | 触发命中率 / 误触率 |
| **D2 首次执行成功率** | First-Run Success Rate | 用户首次调用能否得到预期结果？ | 端到端成功率 |
| **D3 Token 效率** | Token Efficiency | 完成任务消耗的 token 数是否合理？ | token/任务 比值 |
| **D4 可维护性** | Maintainability | 他人能否理解、修改、扩展？ | 代码/指令可读性评估 |
| **D5 可组合性** | Composability | 能否与其他 Skill 无缝协作？ | 组合调用成功率 |

这五个维度不是随意拼凑的，它们覆盖了 Skill 生命周期的三个关键阶段：

- **激活阶段**（D1）：Agent 是否能在正确的时机选择正确的 Skill
- **执行阶段**（D2, D3）：Skill 是否能高效地完成任务
- **演化阶段**（D4, D5）：Skill 是否能持续迭代和与生态协作

下面逐一展开。

### D1：触发准确率（Trigger Precision）

触发准确率回答的是：**用户表达了某个意图，Agent 是否选择了正确的 Skill？**

这个维度看似简单，实则是 Skill 质量的第一道门槛。如果触发不准确，后面四个维度都无从谈起——用户说"帮我填个表"，结果 Agent 激活了一个生成 PDF 的 Skill，一切就偏了。

触发准确率由两个指标构成：

- **召回率（Recall）**：应该触发时是否触发了？
- **精确率（Precision）**：触发了的是否都是正确的？

影响触发准确率的核心要素是 `description` 字段。agentskills.io 的规范明确指出：**name 和 description 是 Agent 在触发决策时唯一能看到的元数据**。这意味着 description 的每一个词都在参与一场隐式的"语义检索竞赛"——Agent 用用户的 prompt 去匹配所有已安装 Skill 的 description，得分最高的被激活。

高质量 description 的三个原则：

**原则一：用第三人称描述能力，而非功能列表。** 不要写"converts Markdown to PDF"，而要写"Use this skill when the user wants to generate a styled PDF document from Markdown content"。前者是 feature spec，后者是 routing signal。

**原则二：包含触发词和负向触发词。** `lovstudio:fill-form` 的 description 中明确列出了"填表、填写表格、fill form、fill template、申请表、登记表"等触发词。更高级的做法是加入负向触发词："Do NOT use this skill for creating new form templates from scratch — use lovstudio:any2docx instead."

**原则三：控制长度在 1024 字符以内。** agentskills.io 规范限制 description 不超过 1024 字符。这不是任意限制——过长的 description 会稀释关键语义信号，降低匹配精度。

> **实践建议**：在你的 Skill 安装环境中同时安装 10+ 个 Skill，然后用 20 个不同的自然语言 prompt 测试触发准确率。记录每个 prompt 触发了哪个 Skill，计算召回率和精确率。目标：召回率 > 90%，精确率 > 95%。

### D2：首次执行成功率（First-Run Success Rate）

首次执行成功率回答的是：**用户第一次调用这个 Skill，能否得到一个可用的结果？**

注意关键词是"首次"和"可用"：

- **首次**：不是"反复调试后终于跑通"，而是"开箱即用"。SkillsBench 的 pass rate 定义就是严格的一次性成功或失败的二值判定（binary success），每个任务跑 5 次取平均。
- **可用**：不是"没报错"，而是"结果符合预期"。一个 PDF 转换 Skill 跑完没报错但生成了空白页面，那就是失败。

影响首次执行成功率的三大杀手：

**杀手一：依赖缺失。** 用户机器上没有 `python-docx`、没有 `pandoc`、Node.js 版本太低。解法：在 `compatibility` 字段明确声明所有依赖，在 SKILL.md 的 workflow 第一步加入依赖检测逻辑。

**杀手二：交互设计缺陷。** Skill 假设用户会提供某些信息，但实际上用户没提供，导致脚本参数缺失或出错。解法：遵循 "scan → pre-fill → ask only what you don't know" 的交互三步法（我们将在第 5 章深入展开）。

**杀手三：边界情况未处理。** 输入文件是 `.doc` 而非 `.docx`、文件路径含中文或空格、模板中的表格结构非标准。解法：在 SKILL.md 的 Limitations 段落明确列出已知限制，在脚本中对常见边界情况做 graceful degradation。

> **量化方法**：准备 10 个不同复杂度的真实测试用例（包含 3 个 edge case），在全新环境中执行。成功 8 个以上算 L3 优秀，成功 6 个以上算 L2 好用，低于 6 个需要回炉重造。

### D3：Token 效率（Token Efficiency）

Token 效率回答的是：**完成同样的任务，这个 Skill 消耗了多少 token？**

为什么 token 效率重要？三个理由：

1. **成本**：每个 token 都是钱。一个 SKILL.md 写了 2000 行的 Skill，每次激活就要吃掉大量 context window
2. **注意力稀释**：SkillsBench 的数据明确显示，"comprehensive" Skills（详尽型）比 "detailed" Skills（适度详细型）的表现差 21.7 个百分点。过长的指令不仅浪费 token，还会让 Agent 迷失在无关信息中
3. **组合上限**：context window 是有限的。如果一个 Skill 占掉 5000 token，那能同时加载的其他 Skill 就少了

Token 效率的核心原则是 agentskills.io 提出的：**"Add what the agent lacks, omit what it knows."** 你不需要解释什么是 PDF、HTTP 怎么工作、数据库迁移是什么意思——Agent 已经知道这些。你需要写的是：项目特定的约定、领域特定的流程、非显而易见的边界情况、以及要使用的具体工具和 API。

agentskills.io 规范给出了明确的数字指导：

- SKILL.md 主体 <= 500 行、<= 5000 token
- 详细参考材料放 `references/` 目录，按需加载（progressive disclosure）
- 加载条件要具体："Read `references/api-errors.md` if the API returns a non-200 status code"，而非笼统的"see references/ for details"

> **度量公式**：Token Efficiency = 任务完成所需总 token / 任务复杂度基准值。可以用同类任务在无 Skill 模式下的 token 消耗作为基准。如果加了 Skill 后 token 消耗反而增加 50% 以上但成功率提升不到 10%，说明 SKILL.md 需要瘦身。

### D4：可维护性（Maintainability）

可维护性回答的是：**三个月后，另一个人（或你自己）能否快速理解、修改、扩展这个 Skill？**

Skill 和软件代码一样，写完那一刻就开始腐化。依赖库升级、Agent 行为变化、用户需求演进——都会让一个曾经好用的 Skill 逐渐失效。可维护性决定了 Skill 的长期生命力。

可维护性的四个评估维度：

| 子维度 | 好的信号 | 坏的信号 |
|-------|---------|---------|
| **结构清晰** | Workflow 步骤编号明确，每步有独立职责 | 指令散落各处，逻辑交叉 |
| **命名规范** | `--template`、`--output`、`--scan` 语义一目了然 | `--t`、`--o`、`--s` 或 `--arg1` |
| **版本追踪** | frontmatter 有 `version` 字段，CHANGELOG 记录变更 | 无版本号，不知道当前是哪个版本 |
| **关注点分离** | SKILL.md 管流程，scripts/ 管实现，references/ 管参考 | 所有逻辑都堆在 SKILL.md 里 |

agentskills.io 的验证检查（validation checks）中包含了若干可维护性相关的硬性要求：

- name 字段 1-64 字符，仅限小写字母、数字和连字符
- name 必须与父目录名完全一致
- frontmatter 必须包含有效的 YAML schema
- license 字段必须存在

这些看起来是"格式检查"，实则是可维护性的基线保障——没有标准命名和结构的 Skill，在生态中就是一座孤岛。

### D5：可组合性（Composability）

可组合性回答的是：**这个 Skill 能否作为更大流程的一个环节，与其他 Skill 无缝协作？**

这是最容易被忽视、但对生态价值最高的维度。单个 Skill 解决单个问题，Skill 组合解决复杂工作流。

举个例子：`lovstudio:proposal` 这个提案生成 Skill 的 workflow 是：

1. 调用 `lovstudio:illustrate` 生成配图
2. 用 Markdown 编排正文
3. 调用 `lovstudio:any2pdf` 转换为带封面的 PDF

如果这三个 Skill 中任何一个的输入输出格式不兼容，或者对文件路径的约定不一致，整个管线就会断裂。

可组合性的三个核心要求：

**要求一：输入输出契约清晰。** 每个 Skill 接受什么格式的输入、产出什么格式的输出，必须在 SKILL.md 中明确声明。这就像函数签名——没有清晰的类型声明，调用方就无法安全地传递数据。

**要求二：副作用可控。** Skill 对文件系统、环境变量、全局状态的修改必须是可预测的。一个好的 Skill 默认把输出写到与输入同目录下，用可预测的命名规则（如 `<name>_filled.docx`），不会意外覆盖已有文件。

**要求三：错误传播合理。** 当 Skill 作为管线的一环失败时，它应该给出清晰的错误信息，让调用方（Agent 或上游 Skill）能据此决策——是重试、跳过、还是回退。

> **测试方法**：设计一个 3-Skill 管线，让目标 Skill 作为中间环节。如果管线一次跑通，说明可组合性良好；如果需要人工调整中间产物的格式或路径，说明有改进空间。

---

## 4.3 SkillsBench：业界首个 Skill 质量基准

2025 年 2 月，SkillsBench（arXiv: 2602.12670）发布，成为业界首个系统评估 Agent Skill 质量的基准测试。它的意义不仅在于提供了一组数据，更在于确立了 Skill 质量评估的方法论范式。

### 实验设计

SkillsBench 包含 86 个任务、覆盖 11 个专业领域（软件工程、金融、医疗、能源、机器人等），每个任务在三种条件下评估：

| 条件 | 说明 |
|-----|------|
| **No Skills** | Agent 仅接收任务描述，无 Skill 辅助 |
| **Curated Skills** | 提供人工精心编写的 Skill，包含示例和资源 |
| **Self-Generated Skills** | Agent 先自行生成 Skill，再用于任务 |

每种条件下每个任务执行 5 次，使用 pass rate（二值成功率平均）作为主要指标，辅以 Hake 公式计算 normalized gain：

```
g = (pass_skill - pass_vanilla) / (1 - pass_vanilla)
```

### 核心发现

**发现一：Curated Skills 显著提升表现，但领域差异极大。**

| 领域 | 提升幅度 |
|-----|---------|
| Healthcare | +51.9 pp |
| Finance | +28.3 pp |
| Energy | +22.1 pp |
| 平均 | +16.2 pp |
| Software Engineering | +4.5 pp |

Healthcare 领域提升最大，因为医疗流程高度标准化、步骤依赖强、领域知识密集——这恰恰是 Skill 最擅长的场景。Software Engineering 提升最小，因为 Agent 本身在编码任务上已经有较强的基线能力。

**发现二：Moderate-length Skills 表现最佳。**

| Skill 类型 | Pass Rate 变化 |
|-----------|--------------|
| Detailed（适度详细） | +18.8 pp |
| Comprehensive（详尽） | -2.9 pp |

这个发现直接印证了我们 D3（Token 效率）的论点：**过长的 Skill 不仅无益，反而有害**。包含 2-3 个聚焦模块的 Skill 显著优于面面俱到的长篇文档。"Comprehensive" 类型的 Skill 实际上让 Agent 表现下降了 2.9 个百分点——信息过载导致了认知过载。

**发现三：自生成 Skill 无法替代人工 Skill。**

Self-Generated Skills 的平均 pass rate 比 No Skills 基线还低 1.3 个百分点。研究者的结论是：**"effective Skills require human-curated domain expertise"**。模型能消费好的 Skill，但无法可靠地生产好的 Skill。

这个发现有深刻的含义——它意味着 Skill 设计是一门需要专业训练的技能，不是"让 AI 写个 Skill"就能解决的。这也是本书存在的理由。

### SkillsBench 的质量准入门槛

SkillsBench 对纳入基准的 Skill 执行了六项质量控制：

1. **Human-authored**：必须由人类编写，禁止 LLM 生成
2. **Generality**：Skill 必须覆盖一类任务，而非某个特定实例
3. **Deterministic verification**：使用程序化验证器（非人工判断）
4. **Structural validation**：自动化结构校验
5. **Human review**：人工审核数据有效性、任务真实性、oracle 质量、反作弊
6. **Leakage prevention**：防止 Skill 内容直接泄漏答案

这六项质量控制本身就构成了一个评审清单，值得每个 Skill 作者参考。

---

## 4.4 agentskills.io 评审标准

agentskills.io 是 Anthropic 官方支持的 Skill 发布平台。它的评审标准从平台运营者的视角定义了"可上架"的质量底线。

### 结构验证（Structural Validation）

| 检查项 | 要求 |
|-------|------|
| SKILL.md 行数 | <= 500 行 |
| Frontmatter | 有效 YAML |
| name 字段 | 1-64 字符，小写字母+数字+连字符，与目录名一致 |
| description 字段 | <= 1024 字符，第三人称描述 |
| license 字段 | 必须存在 |
| metadata | 包含 author、version、tags |

### 内容质量标准

agentskills.io 的 best practices 文档提出了三个层次的内容质量要求：

**层次一：Task Realism（任务真实性）**。Skill 必须解决真实存在的问题，而非为了技术展示而虚构的需求。判断标准：是否有真实用户会在真实场景中触发这个 Skill？

**层次二：Functional Viability（功能可行性）**。Skill 的指令是否能被 Agent 正确执行？步骤是否完整、无歧义？依赖是否可获取？这直接对应我们的 D2（首次执行成功率）。

**层次三：Anti-cheating（反作弊）**。Skill 是否在合理地引导 Agent 工作，而非直接塞入答案？一个好的 Skill 教的是方法（procedure），而非结果（answer）。agentskills.io 明确区分了两种模式：

```markdown
<!-- 反面：直接给答案（specific answer） -->
Join the `orders` table to `customers` on `customer_id`,
filter where `region = 'EMEA'`, and sum the `amount` column.

<!-- 正面：教方法（reusable method） -->
1. Read the schema from `references/schema.yaml` to find relevant tables
2. Join tables using the `_id` foreign key convention
3. Apply any filters from the user's request as WHERE clauses
4. Aggregate numeric columns as needed
```

### 上下文花销的最佳实践

agentskills.io 特别强调了"上下文花销"（context spending）的概念：一旦 Skill 被激活，它的全部 SKILL.md 内容会加载到 Agent 的 context window 中，与对话历史、系统上下文和其他活跃 Skill 竞争注意力。

核心原则可以归结为一句话：**"Would the agent get this wrong without this instruction? If the answer is no, cut it."**

这个原则的实践操作是：对 SKILL.md 中的每一段内容，问自己"如果删掉这段，Agent 会做错吗？"如果答案是"不会"，那就删。如果不确定，测试一下。如果整个任务不加 Skill Agent 也能做好，那这个 Skill 可能根本不需要存在。

---

## 4.5 质量等级定义：从 L1 到 L4

基于五维度模型和上述评审标准，我们定义四个质量等级：

| 等级 | 名称 | D1 触发准确率 | D2 首次成功率 | D3 Token 效率 | D4 可维护性 | D5 可组合性 |
|-----|------|-------------|-------------|-------------|-----------|-----------|
| **L1** | 可用 | 基本能触发 | > 50% | SKILL.md < 800 行 | 有 frontmatter | 独立运行 |
| **L2** | 好用 | 召回 > 80% | > 70% | < 500 行 | 版本追踪、结构清晰 | 输入输出格式标准化 |
| **L3** | 优秀 | 召回 > 90%，精确 > 95% | > 85% | < 300 行，progressive disclosure | 他人可独立维护 | 可无缝参与管线 |
| **L4** | 卓越 | 含负向触发词，零误触 | > 95%，含 edge case | < 200 行核心 + references | CHANGELOG、自动化 lint | 标准化 I/O 契约，错误传播 |

几个要点：

- **L1 → L2 的跃迁**是最重要的：从"能跑"到"好用"，需要的是对 description 的打磨和对失败场景的处理
- **L2 → L3 的跃迁**需要引入 progressive disclosure 和结构化的测试
- **L3 → L4 的跃迁**往往需要多轮真实用户反馈的迭代。SkillsBench 的数据表明，即使是专业团队编写的 Skill，也只有少数能达到 L4
- 大多数活跃的 Skill 处于 **L2-L3** 之间，这是投入产出比最高的区间

---

## 4.6 案例：lovstudio:fill-form 的质量跃迁

让我们用一个真实案例来验证五维度模型的实用性。`lovstudio:fill-form` 是一个填写 Word 表格模板的 Skill，从 v0.1 到 v1.1 经历了多次迭代。我们复盘它在五个维度上的演进。

### v0.1 — L1 可用

最初版本的 fill-form 是一个简单的 wrapper：

- **D1 触发准确率**：description 只写了"fill Word form templates"，在用户说"帮我填表"时不稳定触发
- **D2 首次成功率**：约 40%。依赖 `python-docx` 但没有自动安装检测；只支持标准的 label-value 双列表格，遇到合并单元格就出错
- **D3 Token 效率**：SKILL.md 约 60 行，效率尚可
- **D4 可维护性**：无版本号、无 CLI Reference
- **D5 可组合性**：输出路径硬编码为当前目录，无法被其他 Skill 可靠调用

**判定：L1。能跑，但不好用。**

### v0.5 — L2 好用

经过几轮用户反馈后的改进：

- **D1**：description 加入了中英文触发词（"填表、填写表格、fill form、fill template、申请表、登记表"），触发稳定性显著提升
- **D2**：引入 `--scan` 模式先扫描模板字段，加入了 `.doc` → `.docx` 的自动转换（macOS textutil），成功率提升到约 65%
- **D3**：SKILL.md 增长到约 90 行，增加的都是必要的 workflow 说明
- **D4**：加入 `version` 字段和 CLI Reference 表格
- **D5**：输出路径改为 `<template_dir>/<name>_filled.docx`，遵循可预测的命名规则

**判定：L2。大多数常规场景好用，但 edge case 处理不够。**

### v0.8 — L3 优秀

关键突破——引入"交互三步法"：

- **D1**：description 扩展到完整的语义描述，包含 "Use this skill when..." 引导句和多个触发场景枚举。精确率达到 95%+
- **D2**：workflow 改为 Scan → Pre-fill → Ask only what you don't know 的三步法。Agent 先从 user memory 和 context files 中自动填充已知字段，只问用户真正缺失的信息。首次成功率提升到约 85%
- **D3**：SKILL.md 约 120 行。通过 `--data-file` 参数支持 JSON 文件输入，避免了 shell escaping 问题（长文本在命令行传参时经常出错）
- **D4**：Limitations 段落明确声明了 `.doc` 格式的表格丢失问题；CLI Reference 表格完整
- **D5**：输出路径规则支持智能判断——如果模板在临时目录，自动建议保存到用户文档目录

**判定：L3。绝大多数场景首次成功，有明确的限制声明。**

### v1.1（当前版本）— 接近 L4

当前版本在 L3 基础上的精细打磨：

- **D1**：description 包含中英双语触发词，并明确描述了适用场景（"table-based fields, CJK font support"），category 标注为 "Content Processing"
- **D2**：三种字段检测策略——table-based（主要）、merged rows（合并单元格）、paragraph fallback（无表格时的兜底）。支持 `--font` 和 `--font-size` 定制。首次成功率估计 > 90%
- **D3**：SKILL.md 120 行，核心 workflow 约 70 行。每行都有实际价值，无冗余解释
- **D4**：版本号 `1.1.0`、MIT license、完整 metadata（author, tags）、结构化的 CLI Reference
- **D5**：输入 `.docx`，输出 `_filled.docx`，路径规则明确，可作为管线中间环节

**判定：接近 L4。差距在于缺少自动化 lint 和标准化的错误传播机制。**

### 跃迁复盘

| 版本 | 等级 | 最大瓶颈 | 关键改进动作 |
|-----|------|---------|------------|
| v0.1 | L1 | D2 首次成功率低 | 加入依赖检测、基础错误处理 |
| v0.5 | L2 | D1 触发不稳定 | 丰富 description 触发词 |
| v0.8 | L3 | D2 交互设计 | 引入 Scan → Pre-fill → Ask 三步法 |
| v1.1 | ~L4 | D5 错误传播 | 多策略字段检测、路径智能判断 |

这个案例揭示了一个规律：**每次质量跃迁的瓶颈维度都不同**。v0.1 到 v0.5 是 D2 和 D1 交替提升；v0.5 到 v0.8 的关键突破来自 D2 的交互设计革新；v0.8 到 v1.1 的精打细磨则集中在 D5 的可组合性。

五维度模型的价值正在于此：它帮你定位当前的瓶颈维度，避免在已经足够好的维度上过度投入。

---

## 4.7 质量模型的使用指南

### 何时使用

五维度模型适合三个场景：

1. **新 Skill 设计评审**：在开始编码前，用五维度清单审视设计方案。最常见的问题是 D1（description 没写好）和 D2（缺少 edge case 处理）
2. **版本迭代规划**：用模型定位当前瓶颈维度，集中火力在投入产出比最高的改进点
3. **Skill 对比选型**：当两个 Skill 功能类似时，用五维度逐一对比，做出理性选择

### 快速评估 Checklist

如果你没有时间做完整的五维度分析，这个 10 项速查清单可以覆盖 80% 的质量问题：

- [ ] description 是否包含 "Use this skill when..." 引导句？
- [ ] description 是否包含 3+ 个触发词/短语？
- [ ] SKILL.md 是否 <= 500 行？
- [ ] workflow 步骤是否有编号且职责单一？
- [ ] 是否有 `--scan` 或等效的"先看后做"机制？
- [ ] 依赖是否在 compatibility 中明确声明？
- [ ] 输出路径是否可预测、可配置？
- [ ] Limitations 是否明确声明？
- [ ] frontmatter 是否包含 version 和 license？
- [ ] 是否能作为管线的一环被调用？

---

## 4.8 本章小结

本章我们建立了 Skill 质量评估的理论框架：

1. **五维度模型**（触发准确率、首次执行成功率、Token 效率、可维护性、可组合性）提供了系统的质量分析视角
2. **SkillsBench** 用 7,308 条执行轨迹告诉我们：好的 Skill 平均提升 16.2pp，但过长的 Skill 反而降低表现；模型无法自动生成高质量 Skill
3. **agentskills.io 评审标准** 定义了从结构验证到内容质量的上架底线
4. **L1-L4 质量等级**给出了从"可用"到"卓越"的清晰进阶路径
5. **fill-form 案例**展示了五维度模型如何指导实际的迭代决策

在下一章，我们将深入 D1（触发准确率）和 D2（首次执行成功率）最核心的影响因素——Instruction 设计，探讨如何用精确的语言让 AI 理解你的意图。

---

**参考文献**

- SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks. arXiv:2602.12670, 2025.
- agentskills.io Skill Specification & Best Practices. https://agentskills.io/specification
- agentskills.io Best Practices for Skill Creators. https://agentskills.io/skill-creation/best-practices
