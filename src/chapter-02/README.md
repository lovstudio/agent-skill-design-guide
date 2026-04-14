# 第 2 章：Skill 架构解剖 — Anthropic 官方规范深度解读

> "我写了一个 500 行的 SKILL.md，塞满了各种边界情况的处理指令。结果 Claude 在对话三轮之后就开始'忘'我的规则了。"

这是 Skill 新手最常踩的坑。你以为写得越详细，AI 执行得越好 -- 恰恰相反。Skill 设计的核心矛盾是：**你想教会 AI 的东西是无限的，而上下文窗口（Context Window）是有限的。**

Anthropic 在 2025 年底发布了一份 33 页的官方指南 *The Complete Guide to Building Skills for Claude*，随后又在 `platform.claude.com` 上线了完整的 Best Practices 文档。这些资料浓缩了 Anthropic 工程师在内部和社区数千个 Skill 上积累的经验。本章将这些散落在 PDF、文档站和 GitHub 仓库中的设计智慧，梳理为 **6 条核心设计原则**，并用真实案例逐一拆解。

如果说第 1 章回答了 "Skill 是什么"，本章要回答的是 "一个好 Skill 长什么样" -- 这是全书后续所有章节的理论地基。

---

## 2.1 SKILL.md 的三层结构

在深入原则之前，先建立一个关于 Skill 文件结构的整体心智模型。

每个 Skill 的入口是一个 `SKILL.md` 文件，它由三个层次组成：

```
┌─────────────────────────────────────────┐
│  Layer 1: YAML Frontmatter（元数据）      │  ← 永久加载到系统提示词
│  name, description, license, ...        │     ~100 tokens
├─────────────────────────────────────────┤
│  Layer 2: Markdown Body（指令正文）        │  ← Skill 被触发时加载
│  When to Use, Workflow, Gotchas, ...    │     目标 <500 行
├─────────────────────────────────────────┤
│  Layer 3: 外部文件（按需加载）              │  ← Claude 需要时才读取
│  references/, scripts/, examples/       │     不占上下文，直到被读
└─────────────────────────────────────────┘
```

这个三层结构对应一个关键概念：**渐进式披露（Progressive Disclosure）**。AI 助手启动时，只加载所有 Skill 的 Layer 1（名字和描述），大约每个 Skill 消耗 100 个 token。当用户的请求匹配某个 Skill 时，才加载 Layer 2 的完整指令。而 Layer 3 的参考文件、脚本、数据，只有在执行过程中确实需要时，Claude 才会通过文件系统去读取。

为什么要这么做？因为上下文窗口是**公共资源（Public Good）**。你的 Skill 要和系统提示词、对话历史、其他 Skill 的元数据、用户的实际请求共享这块有限的空间。一个设计不当的 Skill 会像一个占满整条路的大卡车 -- 让其他所有东西都没法通行。

理解了这个前提，我们来看 6 条原则。

---

## 2.2 原则 1：Description 是触发命脉

### 核心观点

用户永远不会 "手动选择" 要用哪个 Skill。Claude 的工作方式是：启动时读取所有已安装 Skill 的 `name` 和 `description` 字段，然后根据用户的请求自动判断该触发哪一个。

这意味着：**description 不只是一段介绍文字，它是 Skill 的触发器（Trigger）。**

如果你的 description 写得太模糊，Skill 会在不该触发时触发（误触发，False Positive）。写得太窄，该触发时又不触发（漏触发，False Negative）。当用户安装了 50 个甚至 100 个以上的 Skill 时，这个问题会被放大 -- Claude 必须从大量 description 中精准匹配。

### 官方规范要点

- description 字段最长 **1024 字符**
- 必须用**第三人称**（"Processes Excel files..."），不能用第一人称或第二人称
- 必须同时包含 **what**（这个 Skill 做什么）和 **when**（什么时候该用它）

### 实战案例

来看 `lovstudio:any2pdf` 的 description：

```yaml
description: >
  Convert Markdown documents to professionally typeset PDF files. Primary engine:
  reportlab (cover pages, frontispiece, back cover, bookmarks). Fallback engine:
  pandoc + XeLaTeX (better table handling, LaTeX-quality typesetting). Handles
  CJK/Latin mixed text, fenced code blocks, tables, blockquotes, clickable TOC,
  watermarks, headers/footers, and page numbers. Trigger when user mentions
  "markdown to PDF", "md2pdf", "any2pdf", "md转pdf", "报告生成", "导出pdf",
  or wants a professionally formatted PDF from markdown.
```

这段 description 做对了几件事：

1. **What -- 功能描述具体**：不是笼统的 "converts documents"，而是明确说了 Markdown 转 PDF、reportlab 引擎、pandoc 备选引擎。
2. **When -- 触发词显式列出**：把用户可能说的关键词（中英文都有）直接写进去。Claude 做字符串匹配时，"md转pdf" 这种中文触发词至关重要。
3. **能力边界清晰**：CJK 混排、代码块、表格、书签 -- 告诉 Claude 这个 Skill 能处理什么。

反面教材是这样的：

```yaml
# 反面教材 -- 不要这样写
description: Helps with documents
```

一个用户说 "帮我整理一下这份 Word 文档"，Claude 会不会触发这个 Skill？不知道。因为 "helps with documents" 什么都能匹配，又什么都匹配不上。

### 设计心法

写 description 时，想象你面前坐着一个分诊护士。她要在 3 秒内判断这个病人该送到哪个科室。你的 description 就是科室门口的牌子 -- 必须足够具体，让分诊护士一看就知道 "这个病人该来这里" 或 "这个病人不该来这里"。

---

## 2.3 原则 2：Body 控制在 500 行以内

### 核心观点

Anthropic 官方给出了一个明确的数字：**SKILL.md 正文（Body）应控制在 500 行以内**。超过这个阈值，就应该把内容拆分到独立文件中。

为什么是 500 行？这不是随意拍的数字。根据官方文档，5000 个 token 大约对应 500 行 Markdown。而一次对话中，Claude 需要在系统提示词、对话历史、工具定义、Skill 指令之间分配上下文窗口。如果一个 Skill 独占太多空间，对话进行几轮之后，Claude 就会开始 "遗忘" 早期的指令 -- 这就是本章开头那个 "500 行 SKILL.md 失效" 的根本原因。

### 默认假设：Claude 已经很聪明了

官方文档中有一句话值得反复品味：

> **Default assumption: Claude is already very smart.** Only add context Claude doesn't already have.

写 Skill 时，逐行审视每一段内容，问自己三个问题：

1. Claude 真的需要这个解释吗？
2. 我能假设 Claude 已经知道这个吗？
3. 这段话值得它占用的 token 吗？

举个例子，官方给出的正反对比：

**简洁版（约 50 tokens）：**
```markdown
## Extract PDF text
Use pdfplumber for text extraction:
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

**冗余版（约 150 tokens）：**
```markdown
## Extract PDF text
PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available for PDF processing, but
pdfplumber is recommended because it's easy to use and handles most cases well.
First, you'll need to install it using pip...
```

冗余版花了 100 多个 token 解释 "什么是 PDF" 和 "为什么选 pdfplumber" -- Claude 早就知道这些。这些 token 本可以留给更有价值的内容，比如 gotchas 和 edge case。

### 实战案例

`lovstudio:thesis-polish` 是一个纯指令 Skill，全文 112 行。它的信息密度很高：

- 20 行元数据（frontmatter）
- 10 行概述和触发条件
- 80 行工作流（5 个步骤，每步聚焦一个动作）

112 行就把 MBA 论文润色的完整流程讲清楚了。它没有花篇幅解释 "什么是学术写作" -- Claude 知道。它只告诉 Claude 那些**它不知道**的东西：评分维度是 ABCDE 五级、润色标准的 5 个子维度各有哪些具体要求、输出文件的命名规范。

再看 `lovstudio:any2pdf`，350 行。作为一个包含 14 种主题、双引擎、封面/扉页/封底/水印等复杂选项的混合型 Skill，350 行已经是精简后的结果。它把 14 种主题的详细配色方案放在了 `references/themes.md` 里，而不是塞在 Body 中。

### 设计心法

把 SKILL.md 想象成一本书的**目录和序言**，而不是正文。目录告诉读者去哪里找信息，序言建立核心概念。真正的细节在各个章节（外部文件）里。

---

## 2.4 原则 3：引用资料用 references/ 按需加载

### 核心观点

一个 Skill 不只是一个 Markdown 文件 -- 它是一个**文件夹**。SKILL.md 是入口，但 `references/`、`scripts/`、`examples/` 目录下的文件同样是 Skill 的一部分。关键区别在于：这些文件**不会自动加载到上下文窗口**。Claude 只在需要时才通过文件系统去读取它们。

这就是 Layer 3 的价值：**零上下文成本，直到被访问。** 你可以在 Skill 文件夹里放 50 页的 API 文档、1000 行的示例代码、完整的配色方案参考 -- 它们静静地躺在文件系统里，不占一个 token，直到 Claude 判断 "我现在需要这个信息" 才去读。

### 官方推荐的目录结构

```
my-skill/
├── SKILL.md              # 主指令（触发时加载）
├── FORMS.md              # 表单填写指南（按需加载）
├── reference.md          # API 参考（按需加载）
├── examples.md           # 使用示例（按需加载）
└── scripts/
    ├── analyze_form.py   # 工具脚本（执行，不加载）
    ├── fill_form.py      # 表单填充脚本
    └── validate.py       # 校验脚本
```

注意一个重要区别：

- **引用文件**（`.md`）：Claude **读取**其内容到上下文中
- **脚本文件**（`.py`、`.sh`）：Claude **执行**它们，只有输出进入上下文

这意味着一个 2000 行的 Python 脚本不会占用 2000 行的上下文 -- Claude 只是 `python scripts/md2pdf.py --input foo.md`，然后看输出结果。这是脚本 Skill 的天然优势。

### 避免嵌套引用

官方文档特别警告：**引用文件只保持一层深度。** 不要让 SKILL.md 指向 A.md，A.md 再指向 B.md，B.md 才有真正的信息。Claude 在处理多层引用时可能只用 `head -100` 预览文件而不是完整读取，导致信息丢失。

```
# 反面教材：链式引用
SKILL.md → advanced.md → details.md → 真正的信息

# 正确做法：扁平引用
SKILL.md → advanced.md
         → reference.md
         → examples.md
```

### 实战案例

`lovstudio:any2pdf` 的目录结构：

```
lovstudio-any2pdf/
├── SKILL.md                  # 350 行主指令
├── references/
│   └── themes.md             # 14 种主题的完整配色参数
├── scripts/
│   └── md2pdf.py             # 核心转换引擎（Python）
├── README.md                 # 人类阅读的文档
└── CHANGELOG.md              # 版本变更记录
```

SKILL.md 中是这样引用主题文件的：

> 用户选择主题后，从 `references/themes.md` 读取对应主题的配色参数，传入脚本。

Claude 不需要一开始就加载 14 种主题的全部配色代码。用户说 "用暖学术风格"，Claude 才去读 themes.md 中 `warm-academic` 的那一节。

对比 `lovstudio:thesis-polish`：

```
lovstudio-thesis-polish/
├── SKILL.md                  # 112 行，全部内容都在这里
└── README.md                 # 人类阅读的文档
```

纯指令 Skill 不需要外部文件 -- 112 行完全在 500 行限制之内，所有指令都在 Body 里。**不要为了 "看起来专业" 而强行拆文件。** 原则 3 的核心不是 "你必须用 references/"，而是 "当内容超标时，用 references/ 来卸载"。

---

## 2.5 原则 4：指令精确度匹配任务脆弱度

### 核心观点

这是 6 条原则中最微妙的一条。Anthropic 的原话是 **"Set appropriate degrees of freedom"** -- 设置恰当的自由度。

核心思想：**任务越脆弱，指令越精确；任务越灵活，指令越宽松。**

什么是 "脆弱任务"？就是那些一步走错、全盘皆输的操作。数据库迁移、文件格式转换、API 调用序列 -- 这些任务只有一条正确路径。

什么是 "灵活任务"？就是那些条条大路通罗马的操作。代码审查、文章润色、设计决策 -- 这些任务有多种合理的处理方式。

### 官方的桥与旷野比喻

Anthropic 用了一个很妙的类比：

> 把 Claude 想象成一个在路上探索的机器人。
>
> **窄桥，两边是悬崖**：只有一条安全的路。提供精确的护栏和严格的指令（低自由度）。例：数据库迁移必须按精确顺序执行。
>
> **空旷的原野，没有危险**：很多条路都能走到目的地。给出大方向，信任 Claude 找到最佳路线（高自由度）。例：代码审查由上下文决定最佳方案。

### 三级自由度光谱

| 自由度 | 适用场景 | 指令形式 | 示例 |
|--------|---------|---------|------|
| 高 | 多种方案均可，依赖上下文判断 | 文字指引 | 代码审查、文章润色 |
| 中 | 有优选模式，但允许变通 | 伪代码 / 带参数的脚本 | 报告生成、数据分析 |
| 低 | 操作脆弱、一致性关键 | 精确脚本、禁止修改 | 数据库迁移、文件格式转换 |

### 实战案例

**高自由度** -- `lovstudio:thesis-polish`：

```markdown
#### 4.2 论证逻辑标准
- 论点-论据-论证：每个观点必须有数据/文献/案例支撑
- 逻辑链条：前后段落之间有明确的逻辑递进关系
- 反驳预设：对可能的质疑提前回应
- 对比论证：与已有研究对比，凸显本文贡献
```

这里给出的是**标准**，不是**步骤**。Claude 需要根据每篇论文的具体内容，自行决定如何强化论证逻辑。你不能写一个脚本来做 MBA 论文润色 -- 这是一个本质上需要高自由度的任务。

**低自由度** -- `lovstudio:any2pdf` 中的脚本调用：

```markdown
Run exactly:
python scripts/md2pdf.py \
  --input report.md \
  --output report.pdf \
  --theme warm-academic
```

文件格式转换是脆弱任务。字体路径错了、编码不对、页面尺寸参数搞混 -- 任何一步出错都会导致 PDF 渲染失败。所以 any2pdf 把所有脆弱逻辑封装在 Python 脚本里，SKILL.md 只需要告诉 Claude "执行这个脚本"。Claude 不需要理解 reportlab 的 API，不需要手写 PDF 排版代码 -- 它只需要正确组装 CLI 参数。

**中等自由度** -- `frontend-design`（Anthropic 官方 Skill）：

```markdown
Before coding, understand the context and commit to a BOLD aesthetic direction:
- Purpose: What problem does this interface solve?
- Tone: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic...
- Constraints: Technical requirements (framework, performance, accessibility).
- Differentiation: What makes this UNFORGETTABLE?
```

这里给了方向（"commit to a BOLD aesthetic direction"），给了思考框架（Purpose, Tone, Constraints, Differentiation），但没有规定具体用什么颜色、什么字体。设计任务的自由度介于润色（高）和格式转换（低）之间 -- 有方法论，但最终决策取决于具体场景。

### 设计心法

写每一条指令时，问自己：**如果 Claude 不完全按我说的做，最坏情况是什么？**

- 如果最坏情况是 "产出不够完美但基本可用" -- 用高自由度
- 如果最坏情况是 "整个任务失败、数据丢失" -- 用低自由度
- 不确定？先用高自由度，等真实使用中发现问题再收紧

---

## 2.6 原则 5：Skill 是文件夹

### 核心观点

这条原则在前面已经多次暗示，但值得单独提出来强调：**一个 Skill 不是一个文件，而是一个文件夹。** `SKILL.md` 是入口，`scripts/`、`references/`、`examples/`、`data/` 都是 Skill 的组成部分。

Anthropic 的原话：

> A skill is a folder, not just a Markdown file. Treat the entire file system as a context-engineering tool.

"把整个文件系统当作上下文工程工具" -- 这句话揭示了 Skill 设计的本质。你不只是在写一份指令文档，你是在**设计一个信息架构**。哪些信息常驻上下文（frontmatter），哪些按需加载（body 中引用的文件），哪些通过执行获取（脚本输出）-- 这些决策构成了 Skill 的架构。

### 三种文件角色

| 角色 | 文件类型 | Claude 如何使用 | 上下文成本 |
|------|---------|---------------|----------|
| 指令 | SKILL.md | 触发时全文加载 | 高（每个 token 都算） |
| 参考 | references/*.md | 按需读取 | 中（读了才算） |
| 工具 | scripts/*.py | 执行后看输出 | 低（只有输出算） |

### 脚本的双重身份

官方文档特别指出，SKILL.md 中引用脚本时，必须明确告诉 Claude 是**执行**还是**阅读**：

- "Run `analyze_form.py` to extract fields"（执行 -- 常见用法）
- "See `analyze_form.py` for the extraction algorithm"（阅读 -- 作为参考）

大多数情况下应该选择执行。原因很简单：执行一个 2000 行的 Python 脚本，上下文成本可能只有几十个 token（脚本的输出）；而让 Claude 读取这 2000 行代码，上下文成本就是 2000 行。

### 预制脚本 vs 让 Claude 现写

即使 Claude 完全有能力写出同样的代码，预制脚本也有四个不可替代的优势：

1. **更可靠** -- 经过测试的代码比现场生成的代码出错率低
2. **省 token** -- 不需要在上下文中包含代码生成过程
3. **省时间** -- 跳过代码生成步骤
4. **保一致** -- 每次调用的行为完全一致

### 实战案例

`lovstudio:any2pdf` 的 `scripts/md2pdf.py` 是一个将近 2000 行的 Python 文件，处理了 CJK 字体切换、混排断行、代码块语法高亮、表格渲染、页眉页脚、水印叠加等大量复杂逻辑。如果让 Claude 每次都现场写这些代码，不仅浪费几千个 token，而且几乎不可能在一次生成中把所有边界情况都处理对。

把它封装成脚本后，SKILL.md 只需要说：

```markdown
python scripts/md2pdf.py --input report.md --output report.pdf --theme warm-academic
```

一行命令，所有复杂性都藏在脚本里。

---

## 2.7 原则 6：Execute-then-Revise — 一轮执行加修订

### 核心观点

Anthropic 官方文档中反复强调一个模式：**反馈循环（Feedback Loop）**。核心套路是 "执行 → 校验 → 修复 → 重复"。

> Run validator -> fix errors -> repeat. This pattern greatly improves output quality.

这不是什么新概念 -- 软件工程里叫 CI/CD，机器学习里叫 training loop。但在 Skill 设计中，很多人忽略了这一步：他们让 Claude 一次性生成结果，然后直接交付。加一个校验步骤，质量提升往往是戏剧性的。

### 两种反馈循环

**脚本驱动的循环**（适用于有工具脚本的 Skill）：

```
1. 执行脚本 → 2. 运行校验器 → 3. 如果有错，修复并回到 2 → 4. 校验通过，完成
```

**自审式循环**（适用于纯指令 Skill）：

```
1. 生成内容 → 2. 对照 checklist 自查 → 3. 如果有问题，修订并回到 2 → 4. 全部通过，完成
```

### 实战案例

`lovstudio:thesis-polish` 的 Step 2（诊断评估）和 Step 3（确认润色策略）就是一个内建的反馈循环：

```markdown
### Step 2: 诊断评估
通读全文后，先输出一份诊断报告...

### Step 3: 确认润色策略
Use AskUserQuestion to confirm strategy BEFORE polishing.
向用户展示诊断报告后，询问：
- 是否同意诊断？有无特殊要求？
- 论文的核心创新点是什么？
```

先诊断，再确认，然后才动手润色。这不只是 "礼貌地征求意见" -- 这是一个**校准步骤**。如果 Claude 的诊断偏了（比如把一篇创新性很强但语言粗糙的论文评为 "创新贡献 C"），用户在 Step 3 就能纠正，避免后续润色方向跑偏。

`lovstudio:any2pdf` 的反馈循环更加显式 -- 它要求用户在转换前通过 `AskUserQuestion` 确认所有设计选项：

```markdown
IMPORTANT: You MUST use the AskUserQuestion tool to ask these questions BEFORE
running the conversion. Do NOT list options as plain text — use the tool so the user
gets a proper interactive prompt.
```

这里的 "MUST" 和 "Do NOT" 都是低自由度指令（回扣原则 4）。为什么？因为跳过确认步骤直接转换 PDF 是一个**脆弱操作** -- 用户可能要的是 "期刊蓝" 主题但 Claude 默认用了 "暖学术"，生成的 PDF 全部要重来。

### 设计心法

问自己：**这个 Skill 的产出如果有问题，代价有多大？**

- 代价低（聊天回复、代码片段）-- 可以不加反馈循环
- 代价中（文档、报告）-- 加一个自审 checklist
- 代价高（PDF 排版、数据库操作、文件批量修改）-- 加校验脚本 + 人工确认

---

## 2.8 运行时模型：Skill 如何被加载、解析、执行

理解了 6 条原则之后，我们来看 Skill 在运行时的完整生命周期。这有助于把前面的抽象原则落地为具体的设计决策。

### 阶段 1：启动 -- 元数据预加载

Claude Code / Claude.ai / API 启动时，扫描所有已安装 Skill 的 `SKILL.md`，提取 YAML frontmatter 中的 `name` 和 `description` 字段，注入系统提示词。

此时，**Skill 的 Body 和外部文件都不会被加载。** 如果你安装了 50 个 Skill，系统提示词中大约增加 50 x 100 = 5000 个 token 的元数据。

这解释了为什么 description 如此重要（原则 1）-- 它是 Claude 唯一能看到的 "第一印象"。

### 阶段 2：匹配 -- Skill 选择

用户发送消息后，Claude 将消息内容与所有 Skill 的 description 进行语义匹配。如果某个 Skill 的 description 与用户意图高度相关，Claude 决定触发它。

这个过程是**隐式的** -- 用户不需要说 "用 any2pdf"。当用户说 "帮我把这份 Markdown 报告转成 PDF，用暖学术风格"，Claude 自动匹配到 `lovstudio:any2pdf`。

### 阶段 3：加载 -- Body 读取

Claude 通过文件系统读取被触发 Skill 的 SKILL.md 全文（包括 Body）。此时 Body 的内容进入上下文窗口。

这就是为什么 Body 要控制在 500 行以内（原则 2）-- 加载时刻的上下文消耗。

### 阶段 4：执行 -- 按指令工作

Claude 按照 Body 中的 Workflow 指令执行任务。执行过程中可能：

- **读取外部文件**：`references/themes.md`（按需加载，原则 3）
- **执行脚本**：`python scripts/md2pdf.py ...`（原则 5）
- **与用户交互**：`AskUserQuestion`（原则 6 的反馈循环）

### 阶段 5：校验与修订

如果 Skill 定义了反馈循环（原则 6），Claude 在初次执行后进行校验和修订。

整个过程的 token 消耗模型如下：

```
系统提示词 + 50 个 Skill 元数据 (~5000 tok)
+ 被触发 Skill 的 Body (~2000 tok)
+ 按需读取的 references (~500-2000 tok)
+ 脚本输出 (~100-500 tok)
+ 对话历史 (变化)
= 总上下文消耗
```

6 条原则的共同目标，就是让这个等式右边的数字尽可能小，同时让 Claude 获得足够的信息完成任务。

---

## 2.9 三种架构范式

有了原则和运行时模型的基础，我们可以将 Skill 分为三种架构范式。选择哪种范式，取决于任务的性质。

### 范式 1：纯指令 Skill

**代表案例**：`lovstudio:thesis-polish`

```
thesis-polish/
├── SKILL.md      # 112 行，全部逻辑在这里
└── README.md     # 给人类看的文档
```

**特征**：

- 没有脚本，没有外部依赖
- 所有逻辑以自然语言指令表达
- 高自由度，Claude 自行判断执行细节
- 适用于：写作、分析、审查、润色等认知型任务

**优势**：零依赖，跨平台通用（"Works with any Claude model"）。

**风险**：指令越多越容易模糊，Claude 可能选择性执行。解决办法是把关键步骤标为 MANDATORY，用 `AskUserQuestion` 设置硬性门控。

### 范式 2：脚本 Skill

如果 Skill 的核心价值是执行一个确定性操作，那么脚本就是主角，SKILL.md 只是 "说明书"。

**特征**：

- 核心逻辑在 `scripts/` 目录下
- SKILL.md 主要负责参数收集和脚本调用
- 低自由度，Claude 的角色是 "正确组装 CLI 参数"
- 适用于：文件转换、数据处理、自动化操作

### 范式 3：混合 Skill

**代表案例**：`lovstudio:any2pdf`

```
any2pdf/
├── SKILL.md                  # 350 行指令（交互流程 + 脚本调用）
├── references/
│   └── themes.md             # 主题配色参考（按需加载）
├── scripts/
│   └── md2pdf.py             # 核心转换引擎
├── README.md
└── CHANGELOG.md
```

**特征**：

- SKILL.md 中既有自然语言指令（交互流程、选项解释），也有脚本调用
- 部分步骤高自由度（帮用户选择主题），部分步骤低自由度（执行转换脚本）
- 使用 references/ 做渐进式披露
- 适用于：需要人机交互 + 确定性执行的复合任务

**混合 Skill 是最常见的范式。** 现实世界的任务很少是纯认知或纯机械的 -- 大多数任务需要先理解需求（高自由度），再精确执行（低自由度）。

---

## 2.10 案例解剖：三个 Skill 的横向对比

为了把前面的原则和范式融会贯通，我们横向对比三个真实 Skill。

### 案例 A：lovstudio:thesis-polish（纯指令型）

| 维度 | 详情 |
|------|------|
| 范式 | 纯指令 |
| 行数 | 112 行 |
| 文件数 | 2（SKILL.md + README.md） |
| 外部依赖 | 无 |
| 自由度 | 高 -- 润色标准是指引，非硬规则 |
| 反馈循环 | 有 -- Step 2 诊断 + Step 3 用户确认 |
| description 触发词 | "论文润色", "MBA论文", "thesis polish" 等 |

**架构亮点**：

- 5 步 Workflow 清晰分离了 "诊断 → 确认 → 执行 → 输出" 四个阶段
- 润色标准按 5 个子维度（语言、论证、结构、创新、文献）展开，每个子维度给出 4-5 条具体标准
- `AskUserQuestion` 放在 Step 3 而不是 Step 1 -- 先诊断再问用户，问题更精准

### 案例 B：lovstudio:any2pdf（混合型）

| 维度 | 详情 |
|------|------|
| 范式 | 混合（指令 + 脚本 + 参考文件） |
| 行数 | 350 行 |
| 文件数 | 5（SKILL.md + themes.md + md2pdf.py + README + CHANGELOG） |
| 外部依赖 | Python 3.8+, reportlab |
| 自由度 | 中低 -- 交互部分灵活，执行部分严格 |
| 反馈循环 | 有 -- 转换前 MUST 用 AskUserQuestion 确认选项 |
| description 触发词 | "markdown to PDF", "md2pdf", "md转pdf", "报告生成", "导出pdf" |

**架构亮点**：

- description 同时列出中英文触发词，覆盖双语用户
- 14 种主题的配色方案放在 `references/themes.md`，不占 Body 空间
- 提供了一张完整的 "用户选择 → CLI 参数" 映射表，消除 Claude 组装参数时的猜测空间
- 支持双引擎（reportlab 主力 + pandoc 备选），在 Body 中明确了选择逻辑

### 案例 C：frontend-design（Anthropic 官方 Skill）

| 维度 | 详情 |
|------|------|
| 范式 | 纯指令 |
| 行数 | 41 行 |
| 文件数 | 1（SKILL.md） |
| 外部依赖 | 无 |
| 自由度 | 极高 -- 几乎全部交给 Claude 自由发挥 |
| 反馈循环 | 无显式循环 |
| description 触发词 | "build web components, pages, or applications" |

**架构亮点**：

这个 Skill 极度精简 -- 41 行，连 100 行都不到。但它是 Anthropic 官方仓库中安装量最高的 Skill 之一。为什么？

1. **它解决的问题极其明确**：让 Claude 生成的前端代码不像 "AI 味" 的千篇一律。
2. **它给的不是规则，是审美框架**：Typography, Color, Motion, Spatial Composition -- 四个维度，每个维度给出方向但不给具体值。
3. **它的 "指令" 实际上是反面教材**：

```markdown
NEVER use generic AI-generated aesthetics like overused font families (Inter,
Roboto, Arial, system fonts), cliched color schemes (particularly purple
gradients on white backgrounds)...
```

通过告诉 Claude "不要做什么"，间接引导它 "做什么"。这是一个高级的 Instruction 设计技巧：**用否定约束代替正面规则**，给 Claude 最大的创造空间同时避开已知陷阱。

### 三个案例的共性

尽管三个 Skill 的范式、复杂度、自由度截然不同，它们共享几个设计决策：

1. **description 都包含具体触发词** -- 不含糊
2. **Body 都远低于 500 行上限** -- 41 / 112 / 350
3. **都没有冗余解释** -- 不解释 "什么是 PDF"、"什么是论文"、"什么是前端"
4. **都在关键节点设置了门控** -- AskUserQuestion 或审美框架

这不是巧合。这些共性正是 6 条原则的自然推论。

---

## 2.11 本章小结

本章解读了 Anthropic 官方规范中的 6 条 Skill 设计原则：

| # | 原则 | 一句话总结 |
|---|------|----------|
| 1 | Description 是触发命脉 | 写清 what + when，包含触发关键词 |
| 2 | Body 控制在 500 行以内 | 上下文是公共资源，只写 Claude 不知道的 |
| 3 | 引用资料按需加载 | 用 references/ 卸载细节，保持一层引用 |
| 4 | 精确度匹配脆弱度 | 脆弱任务低自由度，灵活任务高自由度 |
| 5 | Skill 是文件夹 | 文件系统即上下文工程工具 |
| 6 | Execute-then-Revise | 加一个校验步骤，质量提升戏剧性 |

这 6 条原则背后有一个统一的思想：**上下文窗口是稀缺资源，Skill 设计的本质是上下文工程（Context Engineering）。** 你要在有限的 token 预算内，让 AI 获得恰好足够的信息来完成任务 -- 不多不少。

下一章，我们将搭建开发环境，动手写出你的第一个 Skill。理论到此为止，接下来是代码。
