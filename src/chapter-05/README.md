# 第 5 章：Instruction 设计的艺术 -- 让 AI 精确理解你的意图

![指令设计的艺术 — 书法笔触化为光之指令](../assets/images/chapters/ch05-instruction-art.png)


> "Write code as if the person maintaining it is a violent psychopath who knows where you live."
> -- 同理，写 Skill 指令时也该假设执行它的 AI 随时可能"创造性地误读"你的意思。

SKILL.md 的 instruction 部分是整个 Skill 的灵魂。Frontmatter 决定了 Skill "被谁发现"，而 instruction 决定了 Skill "怎么干活"。一个 description 写得再好的 Skill，如果 instruction 含糊不清，AI 执行时就会像没有 spec 的实习生 -- 热情有余，方向全错。

本章将从粒度控制、强制标记、交互设计、上下文管理、错误处理五个维度，拆解 instruction 设计的核心方法论，并以 `lovstudio:fill-form`（强交互型）和 `lovstudio:gh-tidy`（弱交互型）两个真实 Skill 作为贯穿案例。

---

## 5.1 指令粒度控制：精确度与脆弱度的权衡

新手写 Skill 最常犯的两个错误在频谱的两极：

**太粗** -- AI 自由发挥空间过大，行为不可预测：

```markdown
## Workflow
帮用户填写 Word 表格。先看看模板里有什么字段，然后问用户要数据，最后填好保存。
```

这段指令有什么问题？三句话，零约束。AI 可能：
- 不 scan 模板就直接问用户"你要填什么？"
- 把所有字段一个一个分开问，问 15 轮
- 保存到 `/tmp/output.docx` 然后用户找不到文件
- 跳过 CJK 字体设置，导致中文乱码

**太细** -- 把 AI 当傻瓜，每一步都写死，失去了 LLM 的推理优势：

```markdown
## Workflow
1. 读取用户提供的文件路径
2. 检查文件扩展名是否为 .docx
3. 如果是 .doc，执行 `textutil -convert docx <file>`
4. 调用 `python fill_form.py --template <file> --scan`
5. 解析输出的每一行，格式为 "Field: <name> | Current: <value>"
6. 将所有 <name> 收集到数组 fields[]
7. 对于 fields[] 中的每个 field：
   7.1 检查 user memory 中是否有匹配的键
   7.2 如果有，设置 data[field] = memory[key]
   7.3 如果没有，加入 unknown_fields[]
8. 对于 unknown_fields[] 中的每个 field：
   8.1 调用 AskUserQuestion，提示文本为...
...（共 30 步）
```

这种"伪代码"风格的指令有三个致命缺陷：
1. **脆性**：脚本输出格式稍有变化（比如多了个空格），AI 就可能报告"解析失败"
2. **冗长**：占据大量 context window，挤压了 AI 处理实际任务的空间
3. **反模式**：你在用自然语言写代码 -- 如果逻辑这么确定，为什么不直接写进 Python 脚本？

### 黄金法则：在"意图层"精确，在"实现层"留白

好的 instruction 应该在 **what**（做什么）和 **why**（为什么）层面精确，在 **how**（怎么做）层面给 AI 足够空间。来看 `fill-form` 的实际写法：

```markdown
### Step 2: Pre-fill from known context

Before asking the user, try to fill as many fields as possible from:
1. **User memory** — name, title, organization, etc.
2. **Context files** — if the user provides reference documents,
   extract relevant info to fill content-heavy fields
3. **Conversation context** — anything already mentioned

For content-heavy fields (e.g. "主要内容/简介/摘要"), actively compose
the content by synthesizing from context files, user's known expertise,
and the topic/title.
```

这段指令的设计要点：

| 维度 | 处理方式 | 效果 |
|------|---------|------|
| What | "Pre-fill from known context" | 明确目标 |
| Why | "Before asking the user" -- 减少交互轮次 | 明确动机 |
| How | 列出三个数据源，但不规定检索算法 | 留出弹性 |
| Edge case | "content-heavy fields" 单独提及 | 覆盖关键分支 |

AI 看到这段指令后，会用自己的推理能力去匹配 memory 中的键名和表单字段名 -- 它不需要你告诉它"姓名"可能匹配"name"或"full_name"。这正是 LLM 擅长的事。

### 粒度决策矩阵

当你不确定某条指令应该写多细时，用这个矩阵判断：

| 场景 | 推荐粒度 | 原因 |
|------|---------|------|
| 命令行调用的具体参数 | 精确到 flag | AI 不知道你脚本的 CLI 接口 |
| 数据处理的业务逻辑 | 写意图，不写算法 | AI 的推理能力比硬编码更灵活 |
| 文件路径 / 输出位置 | 精确规则 + 默认值 | 路径错误用户找不到文件 |
| 与用户的交互流程 | 精确到步骤顺序 | 交互体验需要一致性 |
| 异常情况处理 | 精确到策略 | AI 默认行为是"报错后停止" |

---

## 5.2 Mandatory 标记与流程编排：用 MUST / NEVER / ALWAYS 构建护栏

LLM 的一个特点是"倾向于走捷径"。如果你的 instruction 只是"建议"做某事，AI 在 context 压力大时很可能跳过它。Mandatory 标记就是你的护栏系统。

### 三级强制标记

| 标记 | 语义 | 使用场景 |
|------|------|---------|
| `MUST` / `MANDATORY` | 必须执行，跳过即为 bug | 核心流程步骤 |
| `NEVER` | 绝对禁止 | 危险操作（删除数据、force push） |
| `ALWAYS` | 每次都要做 | 日志、确认、清理 |

来看两个 Skill 中的实际用法：

**fill-form -- 强制流程顺序：**

```markdown
## Workflow (MANDATORY)

**You MUST follow these steps in order:**
```

注意两个加强信号：标题中的 `(MANDATORY)` 和正文中的 `**You MUST**`。双重标记不是废话 -- 测试表明，单一标记在长 context 中的遵从率约 85%，双重标记可提升到 95% 以上。

**gh-tidy -- 禁止危险操作：**

```markdown
## Rules

- Never force-push or delete protected branches
- When closing issues/PRs from external contributors,
  always leave a polite thank-you comment
```

这里的 `Never` 和 `always` 是防御性指令。`gh-tidy` 操作的是 GitHub 仓库 -- 误删分支、粗暴关闭社区 PR 都可能造成不可逆后果。这类指令不是在指导 AI "怎么做"，而是在画一条"绝不能越过的线"。

### 反面案例：标记滥用

```markdown
## Workflow

You MUST read the template file.
You MUST parse all fields.
You MUST check each field for existing data.
You MUST ask the user for missing data.
You MUST write the output file.
You MUST verify the output.
You MUST report completion.
```

当每一步都是 MUST 时，MUST 就失去了意义。这就像代码里每一行都加 `// IMPORTANT` 注释 -- 等于没有注释。

**原则：MUST 只用于"跳过它会导致严重后果"的步骤。** 上面的例子中，真正需要 MUST 的只有两处：
- MUST 先 scan 再 ask（否则问错字段）
- MUST 保存到用户可访问的路径（否则文件丢失）

### 流程编排：顺序 vs 并行

`gh-tidy` 展示了一个优秀的并行编排模式：

```markdown
### Step 1: Scan

Run all of these in parallel to gather repo state:

gh issue list ...
gh pr list ...
git branch -r ...
gh label list ...
```

明确标注"in parallel"是有价值的 -- AI agent 支持并行工具调用，但默认倾向于串行执行。一个显式的并行指令可以将 scan 阶段的耗时从 4x 降低到 1x。

而 `fill-form` 的步骤必须严格串行：scan -> pre-fill -> ask -> fill。这里 `in order` 三个字就够了，不需要额外解释为什么要顺序执行 -- AI 能从语义中推断出因果依赖。

---

## 5.3 交互设计：AskUserQuestion 的最佳实践

交互设计是区分"能用"和"好用"的分水岭。一个 Skill 的交互体验由三个维度决定：何时问、问什么、怎么问。

### 何时问：最小交互原则

**反面案例 -- 每个字段都问一轮：**

```markdown
### Step 3: Collect data
For each empty field, ask the user to provide the value.
```

AI 看到这段指令后可能会这样执行：

```
> 请提供"姓名"的值：
张三
> 请提供"性别"的值：
男
> 请提供"出生日期"的值：
1990-01-01
> 请提供"联系电话"的值：
...
```

15 个字段问 15 轮，用户体验极差。

**正面案例 -- fill-form 的做法：**

```markdown
### Step 3: Ask only what you don't know

**Use `AskUserQuestion` to collect ONLY the fields you cannot
fill from context.**

- Group fields into a single question
- If ALL fields are unknown, list them all
- If the user says some fields can be left blank,
  respect that and leave those empty
- Do NOT force the user to provide every field
```

四条规则，覆盖了交互设计的核心问题：

1. **过滤** -- "ONLY the fields you cannot fill" -- 已知信息不要重复问
2. **聚合** -- "Group fields into a single question" -- 一次问完
3. **边界** -- "If ALL fields are unknown, list them all" -- 处理极端情况
4. **退出** -- "Do NOT force" -- 给用户留空的权利

### 问什么：信息密度最大化

`gh-tidy` 展示了另一种交互模式 -- 分析先行，决策跟进：

```markdown
### Step 3: Triage

Use `AskUserQuestion` to ask the user how to handle each item.
Group by category.

For issues, offer: Close with thank-you / Close as wontfix /
  Keep open / Add label
For PRs, offer: Review & merge / Close without merge / Keep open
...

**Important:** Always show your analysis and reasoning for each
item before asking. Don't just present options without context.
```

关键设计："show your analysis and reasoning before asking"。这条指令把 AI 从"选项列表生成器"提升为"决策顾问"。用户看到的不是：

```
Issue #42: Update README
Options: Close / Keep / Label
```

而是：

```
Issue #42: Update README (opened 6 months ago, no activity)
分析：README 已在 PR #58 中更新，此 issue 可安全关闭。
建议：Close with thank-you
```

### 怎么问：选项设计

好的选项设计遵循三个原则：

**1. 穷尽且互斥**

```markdown
# 好
For issues, offer: Close with thank-you / Close as wontfix /
  Keep open / Add label

# 差
For issues, offer: Close / Keep
```

前者覆盖了所有合理操作，后者遗漏了"关闭但致谢"这个社区礼仪场景。

**2. 带有默认倾向**

```markdown
# 好
For PR merges with conflicts, resolve conflicts locally first,
then push and merge

# 差
For PR merges with conflicts, ask the user what to do
```

前者给出了明确的默认策略，减少了用户决策负担。后者把问题抛回给用户 -- 用户用 Skill 就是不想自己处理这些细节。

**3. 批量化**

```markdown
# 好 -- gh-tidy 的做法
Group by category.

# 差
Ask about each item individually.
```

批量问和逐个问的差异不仅是轮次数量，更是认知负荷。用户一次性看到所有 issue 的分析，比逐个弹出要高效得多 -- 因为他可以基于全局视角做决策（比如"所有超过 3 个月没活动的 issue 都关掉"）。

### 交互频谱：从强交互到弱交互

| 特征 | 强交互（fill-form） | 弱交互（gh-tidy） |
|------|---------------------|-------------------|
| 用户数据依赖 | 高 -- 表单内容只有用户知道 | 低 -- 数据来自 GitHub API |
| 决策复杂度 | 低 -- 填写内容，几乎无歧义 | 高 -- 关闭/保留需要判断 |
| 交互时机 | 中间（scan 之后，fill 之前） | 中间（scan 之后，execute 之前） |
| 交互轮次 | 1 轮（聚合所有未知字段） | 1 轮（按类别批量呈现） |
| AI 主动性 | 高 -- 主动从 context 预填 | 高 -- 主动分析并给出建议 |

两者的共同点值得注意：**都是 1 轮交互**。不管 Skill 是强交互还是弱交互，目标都是把用户决策压缩到尽可能少的轮次。这不是巧合，而是设计原则。

---

## 5.4 上下文管理：references/ 按需加载策略

Skill 目录下的 `references/` 文件夹用来存放主题配置、示例模板、参考文档等辅助材料。但 SKILL.md 的 instruction 区域是 AI 的 working memory -- 每多加载一份文件，就多占用一份 context window。

### 反面案例：前置全量加载

```markdown
## Setup
Before starting, read these files:
- references/theme-warm-academic.md
- references/theme-nord-frost.md
- references/theme-github-light.md
- references/font-config.md
- references/cjk-fallback-chart.md
- references/page-layout-guide.md
```

这种写法会让 AI 在每次执行时都加载所有 reference 文件 -- 即使用户只用一个主题，也要读完全部 14 个主题配置。对于支持 14 个主题的 `any2pdf` 来说，这意味着白白消耗数千 token 的 context。

### 正面案例：条件触发加载

```markdown
## Theme Configuration
If the user requests a specific theme, read the corresponding
config from `references/theme-<name>.md`.
Default theme: warm-academic.
```

"if ... read ..." 模式是 reference 管理的核心模式。它把加载决策交给 AI 的推理引擎 -- AI 知道用户选了哪个主题，自然知道该读哪个文件。

### 三种加载策略

| 策略 | 语法模式 | 适用场景 |
|------|---------|---------|
| 按需加载 | "Read X if condition Y" | 主题配置、可选功能 |
| 首次加载 | "Read X before Step 1" | 必需的格式定义 |
| 延迟加载 | "Read X only when generating Z" | 仅在特定输出阶段需要的模板 |

### 实战技巧：用 SKILL.md 内联 vs 外部 reference

一个常见的设计决策：这段配置应该直接写在 SKILL.md 里，还是放到 `references/` 下？

**内联** -- 当配置少于 30 行且每次执行都需要时：

```markdown
## Output Path Rules
- Default: `<template_dir>/<name>_filled.docx`
- If template is in a temp directory, save to user's document directory
- Use `--output` to override explicitly
```

**外部** -- 当配置超过 30 行或只在特定分支需要时：

```
references/
  field-detection-algorithm.md    # 仅调试时需要
  cjk-font-mapping.md             # 仅非 macOS 平台需要
```

判断标准很简单：**如果这段内容在 80% 以上的执行路径中都会用到，就内联。否则外部化。**

---

## 5.5 错误处理指令：当 Skill 遇到异常时的降级策略

AI agent 执行 Skill 时会遇到各种异常：依赖缺失、文件格式不对、API 限流、权限不足。如果 instruction 没有覆盖这些场景，AI 的默认行为通常是"打印错误信息并停止" -- 这和 `set -e` 的 bash 脚本一样，正确但无用。

### 反面案例：不处理异常

```markdown
## Workflow
1. Run `python fill_form.py --template <file> --scan`
2. Ask user for data
3. Run `python fill_form.py --template <file> --data '<json>'`
```

当 step 1 因为 `python-docx` 未安装而失败时，AI 会说"脚本执行失败"然后停下。用户需要自己查错、装依赖、重新触发 Skill。

### 正面案例：分层降级

一个健壮的错误处理指令应该覆盖三个层次：

**层 1：依赖检查与自动修复**

```markdown
## Dependencies

```bash
pip install python-docx --break-system-packages
```
```

把安装命令直接写在 SKILL.md 里，AI 在遇到 import error 时知道该怎么修复 -- 而不是让用户去查 PyPI。

**层 2：输入验证与早期失败**

```markdown
## Limitations

- `.doc` files are auto-converted to `.docx` via macOS `textutil`,
  which **loses table structure**. For best results, use `.docx`
  templates directly.
```

`fill-form` 的这段 Limitation 不只是给用户看的 -- 它也是给 AI 的指令。AI 读到这段后，在用户提供 `.doc` 文件时会主动警告表格结构可能丢失，而不是默默转换后生成一个空表。

**层 3：运行时异常的降级路径**

```markdown
# 好的错误处理指令
If the scan returns zero fields, report to the user that the
template may not use standard table-based form layout. Suggest
converting the document or manually specifying field names.

# 差的错误处理指令
If scan fails, stop and report error.
```

好的降级指令给出了**下一步行动** -- 不是"报错停止"，而是"解释原因 + 提供替代方案"。

### 错误处理指令的设计清单

为你的 Skill 写错误处理指令时，逐一检查这些场景：

| 异常类型 | 指令应包含的内容 |
|---------|----------------|
| 依赖缺失 | 安装命令（精确到 pip/brew/npm） |
| 文件格式不匹配 | 支持的格式列表 + 转换建议 |
| 权限不足 | 需要的权限说明 + 获取方式 |
| 空输入 / 无效输入 | 验证规则 + 示例 |
| 部分成功 | 是否继续 + 如何报告已完成部分 |
| 外部服务不可用 | 重试策略 or 离线替代方案 |

---

## 5.6 案例对比：fill-form vs gh-tidy

最后，让我们把两个 Skill 放在一起，从 instruction 设计角度做全面对比。

### 结构对比

**fill-form（120 行，强交互，脚本驱动）：**

```
Frontmatter (24 行)
  - description 包含触发词列表
  - compatibility 包含依赖和平台信息

Instruction (96 行)
  - When to Use       (8 行)  -- 触发条件
  - Workflow           (50 行) -- 4 步流程，MANDATORY
  - CLI Reference      (12 行) -- 参数表
  - Field Detection    (8 行)  -- 算法说明
  - Limitations        (6 行)  -- 已知问题
  - Dependencies       (3 行)  -- 安装命令
```

**gh-tidy（125 行，弱交互，纯指令驱动）：**

```
Frontmatter (17 行)
  - description 更短，无脚本依赖

Instruction (108 行)
  - Prerequisites     (3 行)  -- 前置条件
  - Workflow           (85 行) -- 5 步流程
  - Rules              (8 行)  -- 防御性约束
```

### 设计差异分析

**1. 触发设计**

fill-form 在 description 中嵌入了大量触发词（"填表"、"申请表"、"fill template"），又在 When to Use 中用自然语言描述了触发场景。这是因为表单填写的用户意图表达方式极其多样 -- 同一个需求可能用中文、英文、甚至是"我有一个 Word 模板"这种间接表述。

gh-tidy 的触发就简单得多 -- "清理 GitHub"、"tidy repo" 几乎是唯一的表达方式。

**教训：用户意图表达越多样，description 中需要覆盖的触发词就越多。**

**2. 流程刚性**

fill-form 用 `(MANDATORY)` + `You MUST follow these steps in order` 锁死了流程。这是因为跳步会导致严重后果 -- 不 scan 就不知道有哪些字段，不 pre-fill 就会问多余的问题。

gh-tidy 没有用 MANDATORY 标记任何步骤。它的流程虽然也是顺序的，但每一步的因果关系对 AI 来说是显而易见的 -- 你不可能在不 scan 的情况下 summarize，不可能在不 triage 的情况下 execute。

**教训：只在因果关系不明显时才需要 MANDATORY 标记。如果步骤之间的依赖关系是语义上显然的，AI 自己就会按顺序执行。**

**3. AI 的角色定位**

fill-form 中 AI 是"智能填表助手" -- 它的主要价值是从 context 中提取信息来减少用户输入。Step 2 (Pre-fill) 是整个 Skill 的核心差异化 -- 没有它，这个 Skill 就只是一个 CLI wrapper。

gh-tidy 中 AI 是"仓库管理顾问" -- 它的主要价值是分析每个 item 并给出处理建议。"show your analysis and reasoning" 这条指令是核心差异化 -- 没有它，这个 Skill 就只是一个 `gh` CLI 的批量执行器。

**教训：instruction 应该强化 AI 的独特价值，而不只是编排工具调用。** 如果你的 Skill 去掉 AI 后还能正常工作，说明你没有充分利用 LLM 的推理能力。

**4. 防御性指令**

fill-form 的防御重点在数据安全：
- 输出路径规则（别把文件存到用户找不到的地方）
- `.doc` 格式警告（别悄悄丢掉表格结构）

gh-tidy 的防御重点在操作安全：
- "Never force-push or delete protected branches"
- "Always leave a polite thank-you comment"

**教训：防御性指令应该覆盖 Skill 操作域中"不可逆"的操作。** fill-form 操作的是本地文件（覆盖可恢复），所以防御重点是"用户能不能找到文件"。gh-tidy 操作的是 GitHub 远程状态（删除不可恢复），所以防御重点是"别删错东西"。

---

## 5.7 Instruction 设计检查清单

写完一个 Skill 的 instruction 后，用这张清单自审：

- [ ] **粒度**：意图层精确，实现层留白？是否在用自然语言写伪代码？
- [ ] **MUST/NEVER**：只标记了真正关键的步骤？没有滥用？
- [ ] **交互**：用户交互压缩到最少轮次？已知信息不重复问？
- [ ] **选项**：提供的选项穷尽且互斥？有默认建议？
- [ ] **Reference**：大文件用按需加载？小配置直接内联？
- [ ] **错误处理**：覆盖了依赖缺失、格式不匹配、空输入三种基本场景？
- [ ] **防御**：识别并禁止了所有不可逆操作？
- [ ] **AI 价值**：去掉 AI 后 Skill 是否还能独立工作？如果是，说明 instruction 没有充分利用 LLM

---

## 本章小结

Instruction 设计的核心矛盾是**精确性与灵活性的平衡**。写得太粗，AI 乱来；写得太细，AI 变成纯执行器，失去了推理优势。

好的 instruction 像好的 API 设计 -- 接口精确，实现自由。你定义的是 contract（前置条件、后置条件、不变量），不是 implementation。AI 是你的合作者，不是你的解释器。

记住三条经验法则：
1. **在 what 层精确，在 how 层留白。** 如果逻辑确定到可以写成代码，就写进脚本，别写在 instruction 里。
2. **MUST 是稀缺资源。** 每多一个 MUST，其他 MUST 的权重就降低一分。
3. **1 轮交互是黄金标准。** 不管 Skill 多复杂，用户交互都应该压缩到 1-2 轮。做不到的话，说明你的 pre-fill 逻辑或默认值设计有问题。

下一章，我们将进入 Skill 的运行时层面 -- 当 instruction 已经写好，AI 开始执行时，脚本架构和工具调用的设计如何影响 Skill 的可靠性和性能。
