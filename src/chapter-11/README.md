# 第 11 章：Skill 质量工程 — 测试、Lint 与持续优化

> "If it compiles, ship it" 在传统软件里是玩笑话。但在 Agent Skill 领域，太多开发者连 "compiles" 这一步都跳过了 — 因为 SKILL.md 本身不是代码，没有编译器会拒绝它。这正是 Skill 质量工程困难的根源：你在测试一段给 AI 读的指令，而 AI 不会抛出 SyntaxError。

---

## 11.1 Skill 测试的特殊性：你在测试一段给 AI 读的指令

传统软件测试有一个隐含前提：被测系统是确定性的。给定输入 X，期望输出 Y。如果输出不是 Y，那是 bug。

Agent Skill 打破了这个前提。

一个 Skill 的"运行时"是 LLM。同样的 SKILL.md，同样的用户输入，在不同的对话上下文中可能产生完全不同的行为。AI 可能跳过你精心设计的 workflow 步骤，可能误解一个参数的默认值，可能在中英文混合的描述里抓错了关键词。

这意味着 Skill 的质量问题分为两层：

**第一层：结构性缺陷** — 可以通过静态分析发现。frontmatter 缺字段、版本号格式不对、description 太短没写触发词、脚本没有 argparse。这些问题与 AI 无关，是纯粹的规范违反。

**第二层：语义性缺陷** — 只有在 AI 实际执行时才暴露。workflow 步骤的措辞让 AI 产生歧义、trigger phrase 覆盖不全导致该触发时不触发、两个 Skill 的触发条件重叠导致误触发。这些问题本质上是"指令的 bug"。

质量工程的目标是：用自动化手段尽可能覆盖第一层，用系统化的手动测试方法论应对第二层。

### 为什么传统测试方法论不够

你可能会想：我写几个 unit test 不就行了？

问题在于，Skill 的"输出"不是一个函数返回值，而是 AI 的一系列行为 — 它调用了哪些工具、按什么顺序调用、给用户的回复是否准确。你没法用 `assertEqual(skill.run(input), expected_output)` 来验证这些。

更关键的是，Skill 的质量是一个频谱，不是二元的。一个 Skill 可能：

- 在简单场景下完美执行，在复杂场景下丢步骤
- 对英文用户完美触发，对中文用户完全不触发
- 在对话的第一轮正确识别，在第三轮因为上下文污染而误触发
- 脚本本身没有 bug，但 SKILL.md 里写的调用方式是错的

这就是 Skill 质量工程的核心挑战：你需要一套方法论来系统性地发现这些问题，而不是靠运气。

---

## 11.2 手动测试方法论：场景矩阵 x 边界条件 x 负面测试

在自动化工具覆盖不到的领域，手动测试仍然是最可靠的武器。但"随便试试"不是测试 — 你需要结构化的方法。

### 场景矩阵

为每个 Skill 构建一个二维矩阵：横轴是用户意图的变体，纵轴是输入条件的变体。

以 `lovstudio:any2docx` 为例：

| | 简单 Markdown | 含代码块 | 含表格 | 含图片 | CJK 混排 | 超长文档 |
|---|---|---|---|---|---|---|
| 默认参数 | - | - | - | - | - | - |
| 指定主题 | - | - | - | - | - | - |
| 带封面页 | - | - | - | - | - | - |
| 带水印 | - | - | - | - | - | - |
| 带 TOC | - | - | - | - | - | - |
| 全部选项 | - | - | - | - | - | - |

这个矩阵有 36 个格子。你不需要全部测完 — 但你需要知道你覆盖了哪些、跳过了哪些。跳过的格子就是你的技术债。

**实践建议**：每次发版前至少覆盖对角线（简单+默认、代码块+指定主题、表格+带封面...），加上你知道最容易出问题的角落。

### 边界条件测试

Skill 的边界条件和传统软件不太一样。以下是最常出问题的边界：

**输入边界**：
- 空文件（0 字节的 .md）
- 只有 YAML frontmatter、没有正文的 .md
- 文件名含空格、中文、特殊字符
- 输入路径是相对路径 vs 绝对路径
- 文件编码是 UTF-8 with BOM vs without BOM

**参数边界**：
- 用户不回答 AskUserQuestion（直接跳过交互步骤）
- 用户给了 SKILL.md 里没有列出的选项值
- 用户在一轮对话里连续调用同一个 Skill 两次

**环境边界**：
- 目标路径不存在
- 依赖未安装（Python 包、系统命令）
- 磁盘空间不足（罕见但致命）
- 网络不可用（对于需要下载资源的 Skill）

### 负面测试：测试 Skill 不应该做的事

负面测试往往被忽略，但它在 Skill 领域尤其重要。因为 AI 有"过度讨好"的倾向 — 如果用户的请求和 Skill 沾点边，AI 就可能强行触发它。

**触发准确性测试**：
- 用户说"帮我写个 Word 文档"（应该触发 any2docx 吗？如果没有 .md 源文件呢？）
- 用户说"把这个 PDF 转成 Word"（不应该触发 any2docx — 它只处理 Markdown）
- 用户说"docx"但语境是在讨论文件格式，不是在请求转换

**权限边界测试**：
- Skill 是否会覆盖用户已有的同名文件而不提醒？
- Skill 是否会在用户没确认的情况下删除临时文件？
- Skill 是否会在 README 里写死路径而泄露开发者的目录结构？

**优雅降级测试**：
- 依赖缺失时，Skill 是否给出了有意义的错误信息？还是让 AI 看到一堆 Python traceback 然后自行发挥？
- 脚本执行超时时，会发生什么？

### 测试记录的最小格式

不需要复杂的测试管理工具。一个 Markdown 表格就够了：

```markdown
## 测试记录 — lovstudio:any2docx v0.3.0

| # | 场景 | 输入 | 期望 | 实际 | Pass? |
|---|------|------|------|------|-------|
| 1 | 基础转换 | simple.md, 默认参数 | 生成 .docx | OK | Y |
| 2 | CJK 混排 | mixed-cjk.md, warm-academic | 中英文字体正确 | 宋体/Helvetica | Y |
| 3 | 空文件 | empty.md | 友好报错 | Python traceback | N → #27 |
```

最后一列的 `N → #27` 表示失败并关联到 issue 编号。这比任何花哨的 CI dashboard 都有用。

---

## 11.3 自动化 Lint：lovstudio:skill-optimizer 的规则解析

手动测试成本高、不可持续。凡是能自动化的检查，都应该自动化。这就是 `lovstudio:skill-optimizer` 的 lint 子系统要解决的问题。

### Lint 的设计哲学

`lint_skill.py` 是一个约 370 行的 Python 脚本，零外部依赖（仅 stdlib），对一个 Skill 目录执行静态检查。它的设计遵循三个原则：

1. **零配置**：不需要 `.lintrc` 或配置文件。所有规则硬编码在脚本中。这是故意的 — Skill repo 的约定是统一的，不需要每个 Skill 自定义规则。
2. **三级 severity**：`error`（必须修）、`warn`（应该修）、`info`（可以考虑）。CI 只阻断 error。
3. **每条 finding 带 fix_hint**：lint 不只是告诉你"坏了"，还告诉你怎么修。这使得 `skill-optimizer` 可以直接根据 lint 输出自动应用修复。

### 规则拆解

让我们逐类分析 lint 检查的规则，理解每条规则背后的质量逻辑。

#### 结构检查（check_structure）

```
DIR_PREFIX   error  — 目录名必须以 lovstudio- 开头
MISSING_SKILL error  — 必须有 SKILL.md
MISSING_README error — 必须有 README.md
```

这三条是最基础的准入门槛。没有 `SKILL.md` 就不是一个 Skill。没有 `README.md` 就无法在 GitHub 上被人类发现和理解。目录前缀是命名空间约定 — 确保不同作者的 Skill 不会名称冲突。

注意 `README.md` 被标记为 `error` 而不是 `warn`。这是一个经过实践验证的决策：Anthropic 官方的 skill-creator 模板不生成 README，但当你的 Skill 发布到 GitHub 时，没有 README 等于隐形 — 没有人会安装一个没有使用说明的 Skill。

#### Frontmatter 检查（check_skill_md）

```
FM_MISSING_FIELD  error  — 缺少必需字段（name/description/license/compatibility/metadata）
FM_NAME_MISMATCH  error  — name 字段与目录名不匹配
FM_DESC_TOO_SHORT warn   — description 少于 80 字符
FM_DESC_NO_TRIGGER warn  — description 没有触发词线索
FM_META_FIELD     warn   — metadata 缺少 author/version/tags
FM_VERSION_FORMAT warn   — version 不是 semver 格式
```

这组规则值得深入理解。

`FM_DESC_TOO_SHORT` 和 `FM_DESC_NO_TRIGGER` 是两条相互补充的规则。description 是 AI 决定是否触发一个 Skill 的核心依据。如果你的 description 只写了"Convert Markdown to DOCX"，AI 在用户说"md转word"时可能不会触发它。description 必须包含：

- **What**：做什么（Convert Markdown to DOCX）
- **When**：什么时候触发（Use when the user wants to turn a .md file into a styled Word document）
- **Trigger phrases**：具体的触发词（"markdown to docx", "md2docx", "md转word", "生成word"）

看 `any2docx` 的 description 就是一个优秀样本 — 它在 12 行的描述里覆盖了英文触发词、中文触发词、使用场景、技术特性：

```yaml
description: >
  Convert Markdown documents to professionally styled DOCX (Word) files...
  Use this skill whenever the user wants to turn a .md file into a
  styled Word document... Also trigger when the user mentions
  "markdown to docx", "md2docx", "md转word", "md转docx", "生成word"...
```

`FM_NAME_MISMATCH` 是一条容易被低估的规则。如果目录叫 `lovstudio-any2docx` 但 frontmatter 里的 name 是 `lovstudio:anytodocx`，AI 会困惑。保持一致性是零成本的事情，没理由不做。

#### Body 检查

```
BODY_TODO         error  — 正文含有 TODO 占位符
BODY_NO_ASKUSER   info   — Workflow 中没有提到 AskUserQuestion
BODY_TOO_LONG     warn   — 正文超过 500 行
```

`BODY_TODO` 标为 error 是因为 TODO 意味着 Skill 未完成 — 发布一个半成品不如不发布。

`BODY_TOO_LONG` 反映了一个重要的质量原则：**progressive disclosure**（渐进式展示）。SKILL.md 是 AI 在每次触发时都要读取的文件。如果它有 800 行，AI 要花费大量 token 来消化这些信息，而其中可能 80% 在当前任务中用不到。解决方案是把详细的参考文档拆到 `references/` 目录，SKILL.md 只保留核心 workflow 和参数定义，按需引用 reference 文件。

`BODY_NO_ASKUSER` 只是 info 级别，因为确实存在不需要交互的 Skill（比如 `skill-optimizer` 自身就是全自动的）。但对于大多数面向终端用户的 Skill，跳过交互步骤意味着 AI 会自行猜测参数，这通常不是用户想要的。

#### README 检查

```
README_TODO       error  — README 含有 TODO 占位符
README_NO_BADGE   warn   — 缺少版本 badge
README_NO_INSTALL warn   — 缺少安装命令
```

`README_NO_BADGE` 看起来像是美观问题，实际上是版本可追溯性问题。当用户在 GitHub 上浏览你的 Skill 时，badge 是他们判断这个 Skill 是否还在维护的第一个信号。一个显示 `v0.3.0` 的 badge 比没有 badge 的 README 多传达了两个信息：这个项目有版本管理，它已经迭代了若干次。

`README_NO_INSTALL` 是"一步安装"原则的体现。如果用户需要读完整个 README 才能搞清楚怎么安装你的 Skill，他们多半不会安装。`npx skills add lovstudio/skills --skill lovstudio:any2docx` 必须出现在 README 的前三行。

#### 脚本检查（check_scripts）

```
SCRIPT_NO_ARGPARSE warn   — CLI 脚本没有使用 argparse
SCRIPT_PIP_FLAG    info   — 脚本里内嵌了 pip install --break-system-packages
SCRIPT_LARGE       info   — 脚本超过 80KB
SCRIPT_NO_CJK_HINT info   — 文档类 Skill 脚本缺少 CJK 处理代码
```

`SCRIPT_NO_ARGPARSE` 是 CLI 一致性规则。lovstudio-skills repo 的约定是所有脚本都是独立的 argparse CLI — 这确保了 Skill 可以在 SKILL.md 里用统一的 `python script.py --input X --output Y` 语法来描述调用方式。如果脚本用 `sys.argv` 手动解析参数，SKILL.md 里的调用示例就可能和实际行为不一致。

`SCRIPT_NO_CJK_HINT` 是一条领域特定规则。对于文档生成类 Skill（名字含 pdf/docx/deck），如果脚本里完全没有 CJK 相关的处理代码，几乎可以肯定它会在中文场景下出问题。这不是 error — 也许 CJK 处理在依赖库里 — 但值得人工确认一下。

### 将 Lint 集成到工作流

Lint 的价值不在于跑一次，而在于每次修改后都跑。推荐的集成方式：

```bash
# 开发时：改完就跑
python3 skills/lovstudio-skill-optimizer/scripts/lint_skill.py any2docx

# CI 中：作为 PR check
python3 skills/lovstudio-skill-optimizer/scripts/lint_skill.py any2docx --json
# 解析 JSON，error 级别阻断合并

# 批量审计：一次扫全部
for dir in skills/lovstudio-*/; do
  name=$(basename "$dir" | sed 's/lovstudio-//')
  python3 scripts/lint_skill.py "$name" 2>/dev/null
done
```

lint 产出的 JSON 格式是这样的：

```json
{
  "skill": "lovstudio-any2docx",
  "path": "/path/to/skills/lovstudio-any2docx",
  "findings": [
    {
      "severity": "warn",
      "code": "README_NO_BADGE",
      "message": "README.md missing version badge",
      "fix_hint": "Add ![Version](https://img.shields.io/badge/version-X.Y.Z-CC785C) near the top",
      "file": "README.md"
    }
  ]
}
```

注意 `fix_hint` 字段 — 它不是给人看的提示，而是给 `skill-optimizer` 的自动修复引擎用的半结构化指令。当 `skill-optimizer` 读到 `"Add ![Version](...) near the top"`，它知道该用 Edit 工具在 README.md 的标题下方插入一行 badge。

---

## 11.4 Agent Skill Evals：构建评估管线

静态 lint 解决第一层问题，但第二层 — 语义性缺陷 — 需要更高级的方法。这就是 Skill Evals（评估）的领域。

### 什么是 Skill Eval

Skill Eval 的核心思想是：把"手动试试看"变成可重复、可量化的自动化流程。

一个 Eval 包含三部分：

1. **Test Case**：一个模拟的用户消息 + 上下文
2. **Expected Behavior**：期望 AI 做出的行为（调用了什么工具、按什么顺序、产出了什么文件）
3. **Evaluator**：判定实际行为是否符合期望的逻辑

### Eval 的类型

按检查粒度，Eval 分为三类：

**触发 Eval** — 验证 Skill 是否在正确的时机被触发。

```yaml
- input: "帮我把 report.md 转成 Word 文档"
  expect_trigger: lovstudio:any2docx

- input: "帮我把这个 PDF 转成可编辑的格式"
  expect_trigger: NOT lovstudio:any2docx  # PDF 不是 Markdown

- input: "md2docx"
  expect_trigger: lovstudio:any2docx

- input: "我想讨论一下 docx 格式的优缺点"
  expect_trigger: NONE  # 讨论不应触发任何转换 Skill
```

**Workflow Eval** — 验证 Skill 触发后是否按正确的步骤执行。

```yaml
- input: "把 report.md 转成 docx"
  expect_steps:
    - tool: AskUserQuestion  # 必须先问用户选项
    - tool: Bash             # 然后调用转换脚本
    - contains: "--input report.md"
    - tool: Read             # 读取输出确认成功
```

**Output Eval** — 验证最终产出是否符合预期。

```yaml
- input: "把 report.md 转成 docx，主题用 warm-academic"
  expect_output:
    - file_exists: "report.docx"
    - file_size_gt: 1024  # 至少 1KB
    - docx_has_style: "Warm Academic"
```

### 构建 Eval 管线的实践方法

完整的 Eval 管线开发成本很高。以下是一个务实的渐进式方法：

**Level 0：手动 + 记录**（每个 Skill 都应该做）

就是 11.2 节的场景矩阵，但每次测试都记录结果。这不是自动化，但它是可重复的 — 下次发版时你知道该测什么。

**Level 1：脚本级单元测试**（有脚本的 Skill 应该做）

不测 Skill 整体，只测脚本的核心函数。比如 `md2docx.py` 的 Markdown 解析逻辑、主题应用逻辑、CJK 字体切换逻辑 — 这些可以用标准的 pytest 来测。

```python
def test_cjk_font_detection():
    assert detect_cjk_font("macOS") == "Songti SC"
    assert detect_cjk_font("Windows") == "SimSun"

def test_markdown_table_parsing():
    md = "| A | B |\n|---|---|\n| 1 | 2 |"
    rows = parse_table(md)
    assert len(rows) == 1
    assert rows[0] == ["1", "2"]
```

**Level 2：Trigger 快照测试**（高流量 Skill 应该做）

维护一个 trigger test cases 文件，定期用 LLM API 跑一遍，检查触发率是否发生了回归。

```python
TRIGGER_CASES = [
    ("帮我把 report.md 转成 Word", "any2docx", True),
    ("PDF 转 Word", "any2docx", False),
    ("md转docx", "any2docx", True),
    ("生成word", "any2docx", True),
    ("讨论 docx 格式", "any2docx", False),
]

def test_trigger_accuracy():
    hits = 0
    for query, skill, expected in TRIGGER_CASES:
        actual = simulate_trigger(query)
        if (actual == skill) == expected:
            hits += 1
    accuracy = hits / len(TRIGGER_CASES)
    assert accuracy >= 0.8, f"Trigger accuracy {accuracy:.0%} below threshold"
```

**Level 3：End-to-End Eval**（关键 Skill 且有 CI 预算时做）

在 CI 环境中启动一个真实的 AI session，发送测试用例，检查完整的 workflow 执行结果。这是最可靠但也最昂贵的方法 — 每次运行都消耗 API token。

Google Cloud 的 Agent Skills Evals 方法论提供了一个参考框架：

1. **定义 Golden Tasks**：一组必须通过的核心场景
2. **设置 Evaluation Criteria**：每个 task 的通过条件（tool calls 序列、输出文件存在性、内容检查）
3. **量化 Pass Rate**：按 task 类别统计通过率，设置回归阈值
4. **Root Cause Analysis**：对失败的 task 做归因 — 是触发问题、workflow 问题、还是脚本 bug

实践中，大多数 Skill 开发者不需要到 Level 3。Level 0 + Level 1 已经能覆盖 80% 的质量问题。

---

## 11.5 版本管理：语义化版本 + CHANGELOG 最佳实践

Skill 的版本管理不只是在 frontmatter 里改一个数字。它是质量可追溯性的基础。

### 语义化版本在 Skill 中的含义

SemVer 的 `MAJOR.MINOR.PATCH` 在 Skill 语境下有特定含义：

| 类型 | 递增条件 | 示例 |
|------|----------|------|
| `PATCH` | 修复 bug、调整措辞、修正 frontmatter | description 补充触发词 |
| `MINOR` | 新增功能选项、新增参考文档、扩展适用范围 | 新增 `--watermark` 参数 |
| `MAJOR` | 破坏性变更：删除选项、重命名 Skill、CLI 不兼容 | `--theme` 值格式改变 |

**关键约定**：在 Skill 生态的早期阶段（大多数 Skill 还没有大量用户），使用 `0.x` 版本号。`0.x` 的语义是"API 可能随时变化"，这给了开发者迭代的自由度。不要过早跳到 `1.0` — 那意味着你承诺了向后兼容。

`lovstudio:any2docx` 当前版本是 `0.3.0`，经历了从创建到成熟的多次迭代，但仍然保持在 `0.x` 范围内。这不是谦虚，是务实。

### CHANGELOG 的写法

每个 Skill 目录下应该有一个 `CHANGELOG.md`，格式遵循 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)。

一个好的 CHANGELOG entry 长这样：

```markdown
## [0.3.0] - 2026-04-13

### Added

- Image embedding: local paths (relative to .md) and remote URLs auto-downloaded
- TOC: field code + static fallback + updateFields=true for auto-refresh on open
- Frontmatter: YAML front matter block fully stripped from output
- Cover: title font size adapts to length (36pt->22pt) to prevent overflow

### Fixed

- Version: corrected from 1.0.0 to 0.x per repo conventions
```

注意几个要点：

1. **日期用 ISO 8601**（`YYYY-MM-DD`），不要用 "April 13" 或 "2026/04/13"
2. **分类清晰**：Added / Changed / Fixed / Removed，不要混在一起
3. **条目聚焦 What & Why**，不要写 How（代码层面的改动不属于 CHANGELOG）
4. **每个条目可以独立理解**，不要假设读者看过之前的版本

### 自动化版本管理

`skill-optimizer` 内置了 `bump_version.py` 脚本，可以自动完成版本号递增和 CHANGELOG entry 创建。它的工作流程是：

1. 读取当前 SKILL.md frontmatter 中的 version
2. 根据变更类型（patch/minor/major）计算新版本号
3. 更新 SKILL.md 中的 version 字段
4. 在 CHANGELOG.md 头部插入新的 entry（日期取当天）
5. 更新 README.md 的 version badge

这个流程消除了"改了代码忘了改版本号"的问题 — 只要跑一次 optimizer，版本号、CHANGELOG、badge 三者保持同步。

---

## 11.6 性能优化：减少 token 消耗、提升首次执行成功率

Skill 的"性能"有两个维度：AI 消耗了多少 token 来理解和执行它（成本），以及 AI 首次执行就成功的概率（可靠性）。

### Token 消耗优化

AI 每次触发一个 Skill 都要读取完整的 SKILL.md。这意味着 SKILL.md 的每一行都有成本。

**策略 1：Progressive Disclosure**

把 SKILL.md 控制在 200 行以内。详细的参数说明、主题列表、示例输出等放到 `references/` 目录。SKILL.md 只在需要时指示 AI 去读 reference 文件：

```markdown
## Themes

14 built-in themes are available. For the full list with color previews,
read `references/themes.md`. The default is `warm-academic`.
```

这样，如果用户只说"用默认主题转换"，AI 就不需要读那个 reference 文件，省下了几百 token。

**策略 2：消除冗余**

审查 SKILL.md 中是否有重复信息。常见的冗余：
- frontmatter 的 description 和正文的 "When to Use" 说的是同一件事
- Quick Start 和 Workflow 步骤里列了两遍完整的 CLI 参数
- 参数表出现在 SKILL.md 和 README.md 两个地方（只应在 README.md 里有完整参数表，SKILL.md 里放简化版或引用）

**策略 3：用结构替代散文**

AI 对结构化内容的理解效率远高于散文。比较：

```markdown
<!-- 散文版 — 150 tokens -->
The script accepts several options. You can specify the input file
using --input, the output file using --output (defaults to the
input filename with .docx extension), the title using --title,
the author using --author, and the theme using --theme.
```

```markdown
<!-- 结构化版 — 80 tokens -->
| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--input` | Yes | — | Source .md file |
| `--output` | No | `{input}.docx` | Output path |
| `--title` | No | filename | Cover page title |
| `--theme` | No | `warm-academic` | Color theme |
```

同样的信息，token 量减少近一半，且 AI 的理解准确率更高。

### 首次执行成功率优化

首次执行成功率（First-Run Success Rate, FRSR）是衡量 Skill 质量的最重要指标。如果一个 Skill 需要用户反复调试才能跑通，它的实际价值就大打折扣。

**影响 FRSR 的关键因素**：

1. **依赖安装指导是否清晰**。`compatibility` 字段必须明确列出所有依赖和安装命令。不要写"需要 Python 相关库"，要写"需要 `pip install python-docx`"。

2. **默认值是否合理**。好的 Skill 应该在用户提供最少信息的情况下也能产出可用的结果。`any2docx` 只需要 `--input` 一个必填参数，其他全有合理默认值。

3. **错误信息是否可操作**。脚本报错时，错误信息应该告诉 AI 下一步该怎么做，而不只是抛出异常：

```python
# 差的错误处理
if not Path(args.input).exists():
    raise FileNotFoundError(args.input)

# 好的错误处理
if not Path(args.input).exists():
    print(f"Error: input file '{args.input}' not found.", file=sys.stderr)
    print(f"Hint: check the path is correct and the file exists.", file=sys.stderr)
    sys.exit(1)
```

4. **AskUserQuestion 的选项是否穷举**。如果 Skill 提供 14 个主题但 AskUserQuestion 只列了 3 个，用户可能选了一个不在列表里的主题名，导致脚本报错。

5. **环境检测前置**。在执行核心逻辑之前，先检查依赖是否存在：

```python
import shutil
if not shutil.which("pandoc"):
    print("Error: pandoc not found. Install: brew install pandoc", file=sys.stderr)
    sys.exit(1)
```

---

## 11.7 案例：从 v0.1 到 v0.3 的迭代之路 — lovstudio:any2docx 的进化史

理论讲完了。让我们看一个真实的 Skill 如何通过质量工程从粗糙走向成熟。

### v0.1.0 — 能跑就行

`any2docx` 的第一个版本是"最小可用产品"：

- 基本的 Markdown → DOCX 转换
- 单一主题（Warm Academic 硬编码）
- 无封面页、无 TOC、无水印
- CJK 字体硬编码为 macOS 的宋体
- description 只有一句话："Convert Markdown to DOCX"

这个版本在开发者自己的 macOS 上能跑通简单场景。但：

- 在 Linux 上因为找不到宋体字体而崩溃
- 含表格的 Markdown 渲染错位
- 代码块没有语法高亮，字体和正文一样
- 没有 README，没有 CHANGELOG
- 用户说"md转word"时不触发（description 里没有中文触发词）

如果用 lint 扫一遍，大概会报出 5 个 error、4 个 warn。

### v0.2.0 — 补齐短板

基于 v0.1.0 的使用反馈和 lint 结果，v0.2.0 做了系统性的补强：

**description 重写**：从一句话扩展到完整的触发词覆盖。加入了 "md2docx"、"md转word"、"md转docx"、"生成word" 等中文触发词。lint 的 `FM_DESC_TOO_SHORT` 和 `FM_DESC_NO_TRIGGER` 就此消除。

**多主题支持**：从硬编码单一主题扩展到 14 个主题，与 `any2pdf` 共享同一套色板。这是 MINOR bump — 新增了功能选项但不破坏已有用法。

**CJK 字体自适应**：实现了平台检测逻辑 — macOS 用宋体、Windows 用 SimSun、Linux 用 Noto Serif CJK SC。从"在我机器上能跑"升级到"跨平台可用"。

**代码块样式**：等宽字体 + 灰色背景 + 缩进，和正文明确区分。

**README + CHANGELOG**：补上了这两个文件。README 包含安装命令、用法示例、参数表。CHANGELOG 记录了从 v0.1.0 到 v0.2.0 的所有变更。

### v0.3.0 — 功能成熟

v0.3.0 是截至目前最大的一次更新，直接看 CHANGELOG：

```
### Added
- Image embedding: local paths and remote URLs auto-downloaded and embedded
- TOC: field code + static fallback + updateFields=true for auto-refresh on open
- Frontmatter: YAML front matter block fully stripped from output
- Cover: title font size adapts to length (36pt->22pt) to prevent overflow

### Fixed
- Version: corrected from 1.0.0 to 0.x per repo conventions
```

几个值得注意的质量工程实践：

1. **图片嵌入**同时支持本地相对路径和远程 URL — 这是边界条件测试驱动的决策。v0.2.0 只支持本地路径，用户一旦在 Markdown 里引用了网络图片就会生成一个没有图的 DOCX。

2. **TOC 的双重实现**（field code + static fallback）是典型的防御性编程。Word 的 field code 在大多数情况下会自动生成目录，但如果用户用 LibreOffice 打开 .docx，field code 不会执行。static fallback 确保在任何阅读器里都有一个可见的目录。

3. **版本号从 1.0.0 回退到 0.x** — 这个 "Fix" 看起来反直觉，但严格遵循了 repo 的发版约定。1.0.0 意味着 API 稳定承诺，而 `any2docx` 的 CLI 参数在 v0.2 到 v0.3 之间还在变化。降回 0.x 是诚实的做法。

4. **封面标题自适应字号** — 这是手动测试中用长标题发现的问题。当标题超过一定长度时，36pt 字号会导致文字溢出封面区域。自适应逻辑根据标题长度在 36pt 到 22pt 之间动态调整。

### 进化模式总结

回顾 `any2docx` 从 v0.1 到 v0.3 的三个版本，可以提炼出一个 Skill 进化的通用模式：

```
v0.1 — Proof of Concept
       "在我机器上能跑通核心场景"
       质量债务：description 不完整、无跨平台支持、无文档

v0.2 — Convention Compliance
       "通过 lint、补齐文档、覆盖基本边界条件"
       消除所有 error 级 lint finding，补 README/CHANGELOG

v0.3 — Feature Completeness
       "覆盖用户真实需求的 80%，防御性处理边界情况"
       由真实用户反馈和手动测试驱动的功能补全

v0.4+ — Polish & Performance
       "优化 token 消耗、提升 FRSR、处理长尾场景"
       progressive disclosure、更好的错误信息、eval 管线
```

每个阶段都有明确的质量目标和退出标准。不要试图在 v0.1 就做到完美 — 那是过度工程。也不要在 v0.3 还有 error 级 lint finding — 那是质量底线的缺失。

---

## 本章小结

Skill 质量工程的核心认知是：你在测试一段给 AI 读的指令，而不是一段给编译器读的代码。这要求我们同时使用传统软件工程的工具（lint、版本管理、CI）和面向 AI 系统特有的方法论（trigger eval、workflow eval、FRSR 优化）。

实操清单：

1. **每个 Skill 都该有**：场景矩阵文档、CHANGELOG、版本 badge
2. **每次发版前都该做**：跑一遍 lint（消除 error）、走一遍对角线测试
3. **有脚本的 Skill 额外做**：核心函数的 unit test
4. **高流量 Skill 额外做**：trigger 快照测试、FRSR 统计
5. **Token 预算紧张时做**：progressive disclosure 重构、结构化替代散文

质量不是一个终点，而是一个持续的过程。`any2docx` 从 v0.1 到 v0.3 花了三个迭代周期，每次都因为真实的使用反馈而变得更好。这才是质量工程的本质 — 不是追求一次性的完美，而是建立一个让每次迭代都朝正确方向前进的系统。
