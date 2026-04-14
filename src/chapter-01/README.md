# 第 1 章：从 Prompt 到 Skill — AI 编程助手的能力扩展革命

> 本章状态：✅ 初稿完成

---

**场景：一个重复了 200 次的烦恼**

你是一个技术团队的负责人。每周五，你需要把团队的 Markdown 周报转成排版精美的 PDF，发给管理层。你打开 Claude Code，输入一段 prompt：

```
帮我把这个 markdown 文件转成 PDF，要求：
- 封面带标题和日期
- 正文用宋体，代码用等宽字体
- 中英文混排间距正确
- 加上页眉页脚和页码
- 用暖色调主题
```

Claude 给出了一段 Python 脚本。你跑了一下，字体找不到。改了字体路径，中文换行又断在了半个字符上。修了换行，页眉又跑偏了。折腾两小时后终于搞定。

下周五，同样的事情又来了。你翻聊天记录，复制上次的 prompt，但 Claude 的回答又不太一样 —— 这次它用了 `weasyprint` 而不是 `reportlab`，整个脚本得重新调试。

**第三周，你终于忍了。**

你把这段 prompt 和修好的脚本一起打包，存成一个标准化的文件。从此只需要说一句 `/any2pdf`，Claude 就能用你验证过的方案完成转换，不再瞎猜。

这个文件，就是 **Skill**。

---

## 1.1 什么是 Agent Skill？

**Agent Skill（智能体技能）** 是 AI 编程助手的可复用能力扩展单元。它不是一段 prompt，不是一个插件，也不是一个 API 端点 —— 它是一套完整的「行为规范 + 工具链」，让 AI 助手在特定领域拥有专家级别的执行能力。

一个 Skill 通常由一个 `SKILL.md` 文件定义，包含三个核心部分：

```yaml
---
name: lovstudio:any2pdf          # 唯一标识
description: >                   # 触发条件：什么时候该用这个 Skill
  Convert Markdown to PDF...
  Trigger when user mentions "md2pdf", "导出pdf"...
metadata:
  version: "1.2.0"
  tags: markdown pdf cjk
---

# any2pdf — Markdown to Professional PDF    ← 指令正文

## Workflow                                  ← 执行步骤
Step 1: 询问用户参数（主题、输出路径...）
Step 2: 调用 scripts/md2pdf.py
Step 3: 验证输出并汇报
```

三个核心部分各司其职：

- **Frontmatter（前置元数据）**：告诉 AI「我是谁」「什么时候该调用我」
- **Instructions（指令正文）**：告诉 AI「怎么做」「注意什么」
- **Workflow（工作流）**：告诉 AI「按什么顺序执行」

### Skill 与相近概念的区别

初学者常把 Skill 和其他概念混淆。以下是关键区别：

| 概念 | 持久性 | 可复用 | 带工具 | 可组合 | 可分发 |
|------|--------|--------|--------|--------|--------|
| **Prompt** | ❌ 单次 | ❌ 复制粘贴 | ❌ 纯文本 | ❌ | ❌ |
| **Prompt Template** | ✅ 可保存 | ✅ 参数化 | ❌ 纯文本 | ❌ | ⚠️ 手动分享 |
| **Plugin / Extension** | ✅ | ✅ | ✅ 代码级 | ⚠️ 有限 | ✅ 商店分发 |
| **MCP Tool** | ✅ | ✅ | ✅ API 级 | ✅ 协议标准 | ✅ |
| **Agent Skill** | ✅ | ✅ | ✅ 指令+脚本 | ✅ Skill 间调用 | ✅ 市场分发 |

关键差异在于 **抽象层次** 和 **执行模型**：

- **Prompt Template** 给人用 —— 人填参数、人发送、人检查结果
- **Plugin** 给平台用 —— 平台加载代码、调用 API、返回结构化结果
- **MCP Tool** 给模型用 —— 模型通过标准协议调用外部能力（数据库、搜索引擎...）
- **Skill** 给 AI 助手用 —— AI 读懂指令、自主决策、调用工具链、交付完整结果

用一个类比：如果 AI 助手是一个新入职的员工，Prompt 是你口头交代的任务，Plugin 是公司配的工具，MCP Tool 是内部系统的 API 接口，而 **Skill 是一本操作手册** —— 它告诉这个员工在什么场景下该做什么、怎么做、用什么工具、注意什么坑。

### MCP 与 Skill 的协作关系

MCP（Model Context Protocol，模型上下文协议）和 Skill 不是替代关系，而是互补关系：

- **MCP** 解决「能不能做」—— 让 AI 助手能访问数据库、调用 API、搜索网页
- **Skill** 解决「会不会做」—— 教 AI 助手如何高质量地完成一个复杂任务

一个成熟的 Skill 经常会调用 MCP Tool。比如 `lovstudio:proposal` 在生成方案书时，可能通过 MCP 调用 context7 拉取最新技术文档，再调用 `lovstudio:illustrate` 生成配图，最后调用 `lovstudio:any2pdf` 输出 PDF。Skill 是编排层，MCP 是能力层。

---

## 1.2 Skill 生态现状（2026）

2026 年初，AI 编程已经不再是「辅助」，而是很多开发者的默认工作方式。几个关键数据：

### Claude Code 的爆发

- **GitHub 提交占比 4%**：根据 2026 年初的统计，全球 GitHub 新增提交中约 4% 由 Claude Code 生成或辅助生成
- **官方仓库 87k+ stars**：[anthropics/claude-code](https://github.com/anthropics/claude-code) 成为 GitHub 增长最快的开发者工具之一
- **Skills 市场**：[agentskills.io](https://agentskills.io) 上线后迅速聚集了超过 70 万个社区贡献的 Skill

### 三大 AI 编程助手的 Skill 生态

| 平台 | Skill 机制名称 | 生态规模 | 开放程度 |
|------|---------------|----------|----------|
| Claude Code | Skills (SKILL.md) | 70 万+ | 完全开放，文件系统级 |
| Cursor | Rules (.cursor/rules/) | 大量社区规则 | 平台内分享 |
| Windsurf | Rules (.windsurfrules) | 增长中 | 社区驱动 |

还有更多玩家在入场：Cline、Codex CLI、Gemini CLI 都在 2025-2026 年推出了类似的能力扩展机制。这不是巧合 —— 当 AI 助手的基础能力趋同，**可定制化** 和 **可扩展性** 就成了核心差异化因素。

### Skills 市场的兴起

2025 年底 Anthropic 推出 agentskills.io 后，Skill 的创建和分发变得标准化。平台提供：

- **发现**：按类别（Document Conversion、Code Quality、DevOps...）浏览 Skill
- **安装**：一行命令将 Skill 安装到本地
- **评审**：官方审核确保 Skill 的功能可行性（Functional Viability）、任务真实性（Task Realism）和防作弊（Anti-cheating）
- **度量**：安装量、使用频率、用户评分

头部 Skill 如 Anthropic 官方的 `frontend-design`（前端设计助手）已经积累了 27.7 万次安装。这意味着近 30 万个开发者在使用同一套经过验证的前端设计最佳实践。

---

## 1.3 三大平台对比：Claude Code Skills vs Cursor Rules vs Windsurf Rules

虽然三大平台都提供了类似的能力扩展机制，但设计哲学和技术实现有显著差异。

### Claude Code Skills

Claude Code 的 Skill 系统是最完整的实现：

```
~/.claude/skills/
  lovstudio-any2pdf/
    SKILL.md           # 核心定义：frontmatter + instructions + workflow
    scripts/
      md2pdf.py        # 可执行脚本
    references/
      theme-guide.md   # 按需加载的参考资料
    examples/
      sample-output.pdf
```

核心特点：

- **Skill 是文件夹**，不只是一个配置文件。脚本、参考资料、示例文件都是 Skill 的组成部分
- **自然语言触发**：通过 `description` 字段中的关键词匹配自动触发，也可以通过 `/skill-name` 手动调用
- **按需加载**：references/ 目录下的文件不会一股脑塞进上下文，而是 AI 在需要时才读取
- **Skill 间调用**：一个 Skill 可以声明依赖并调用另一个 Skill

### Cursor Rules

Cursor 采用基于规则文件的方式：

```
.cursor/rules/
  react-best-practices.mdc    # MDC 格式（Markdown + 元数据）
  api-conventions.mdc
```

核心特点：

- **项目级**：Rules 通常绑定到项目，放在 `.cursor/rules/` 目录下
- **自动附加**：匹配条件满足时，Rule 内容自动附加到 AI 的上下文中
- **轻量级**：不支持脚本，纯指令驱动
- **Glob 触发**：通过文件路径模式（如 `*.tsx`）触发特定规则

### Windsurf Rules

Windsurf 的规则系统更接近项目级配置：

```
.windsurfrules          # 单文件配置
.windsurf/rules/        # 或多文件目录
```

核心特点：

- **级联规则**：全局 → 工作区 → 项目，多层级覆盖
- **Markdown 原生**：规则文件就是普通 Markdown
- **社区驱动**：通过 GitHub 仓库分享规则集

### 对比总结

| 维度 | Claude Code Skills | Cursor Rules | Windsurf Rules |
|------|-------------------|--------------|----------------|
| 定义格式 | SKILL.md (YAML frontmatter) | .mdc (MDC 格式) | .md / .windsurfrules |
| 脚本支持 | ✅ Python / Shell / Node.js | ❌ 纯指令 | ❌ 纯指令 |
| 触发方式 | 关键词 + 手动 /命令 | Glob 路径匹配 | 手动 + 上下文推断 |
| 按需加载 | ✅ references/ 目录 | ❌ 全量加载 | ❌ 全量加载 |
| Skill 间调用 | ✅ 依赖声明 | ❌ | ❌ |
| 分发市场 | ✅ agentskills.io | ⚠️ 社区仓库 | ⚠️ 社区仓库 |
| 版本管理 | ✅ 语义化版本 | ❌ | ❌ |

Claude Code Skills 的设计明显更接近一个完整的「能力扩展框架」，而 Cursor Rules 和 Windsurf Rules 更像是「行为配置」。这不是说后者不好 —— 对于简单的代码规范和偏好设置，轻量级的 Rule 反而更合适。但当你需要构建复杂的、可组合的、带工具链的自动化流程时，Skill 的架构优势就显现出来了。

---

## 1.4 为什么 Skill 是 AI 编程的「杀手级应用」

Skill 不只是「更高级的 prompt」。它解决了 AI 编程中四个根本性问题。

### 问题一：复用 — 知识不应该随对话消失

每次和 AI 对话，你都在「教」它做事。但对话结束后，这些「教学成果」就消失了。下次你要从头再教一遍。

Skill 把验证过的知识固化为文件。以 `lovstudio:any2pdf` 为例，这个 Skill 经过 1.2.0 版本的迭代，沉淀了大量关于 CJK 混排、字体回退、页面布局的经验。这些经验不会因为对话结束而丢失，任何人安装这个 Skill 后都能直接受益。

```
# 这些知识沉淀在 SKILL.md 和脚本中，而不是散落在聊天记录里

Skill v0.1 → 能转换基本 Markdown
Skill v0.5 → 解决了 CJK 换行问题
Skill v0.8 → 支持 14 种色彩主题
Skill v1.0 → 封面、目录、页眉页脚全齐
Skill v1.2 → 双引擎（reportlab + pandoc）自动选择
```

### 问题二：组合 — 复杂任务需要多个能力协作

一个 Skill 能做好一件事，多个 Skill 组合起来能做更复杂的事。这就是 Unix 哲学在 AI 时代的延伸。

来看 `lovstudio:proposal`（方案书生成器）的工作流：

```
用户输入需求描述
  ↓
Step 1: 分析需求，生成大纲
  ↓
Step 2: 调用 lovstudio:illustrate → 生成配图
  ↓
Step 3: 组装 Markdown 正文
  ↓
Step 4: 调用 lovstudio:any2pdf → 输出 PDF
  ↓
交付：一份图文并茂的方案书
```

单个 Skill 无法完成这个任务。但通过 Skill 间调用，复杂的管线被拆解为简单的步骤，每个步骤由擅长该任务的 Skill 负责。

### 问题三：分发 — 好的实践应该被传播

当你写出一个高质量 Skill，它不仅服务你自己。通过 agentskills.io 或 GitHub 分发，全世界的开发者都能使用你的 Skill。

这创造了一种新的贡献模式：**你不是在写代码，你是在教 AI 做事**。一个优秀的 Skill 作者，本质上是在把自己的专业知识「传授」给全球数百万个 AI 助手实例。

传统软件分发面临环境差异、依赖冲突等问题。Skill 的分发天然简洁 —— 核心就是一个文本文件（SKILL.md），可选配套脚本。AI 助手负责适配运行环境。这大幅降低了知识分发的门槛。

### 问题四：进化 — Skill 可以自我改进

最令人兴奋的是，Skill 可以进化。因为 SKILL.md 本身就是自然语言，AI 可以阅读它、理解它、改进它。

```
# lovstudio:skill-optimizer 可以自动分析并改进其他 Skill

/skill-optimizer

→ 分析目标 Skill 的 SKILL.md
→ 检测问题：description 不够精确、指令有歧义、缺少错误处理...
→ 输出改进建议或直接修改
```

这不是科幻。`lovstudio:skill-optimizer` 就是一个能优化其他 Skill 的「元技能（Meta-Skill）」。在本书的第 12 章，我们还将探讨更前沿的 Skill 自进化方法论，包括基于 DSPy 的自动优化和基于执行反馈的文本梯度更新（TextGrad）。

### 四大价值的协同效应

当复用、组合、分发、进化四个特性同时存在时，产生的效果是乘法级的：

```
个人 Skill → 分发到社区 → 被其他人组合到更大的 Workflow 中
    ↑                                         ↓
    └── 社区反馈和 AI 优化 → 进化出更好的版本 ←┘
```

这就是为什么说 Skill 是 AI 编程的「杀手级应用」—— 它不只是提升个人效率，而是构建了一个 **AI 能力的开源生态**。每个人的贡献都在提升整个生态的能力上限。

---

## 1.5 实战预告：lovstudio-skills — 26 个 Skill 的实践案例

本书的所有案例都来自 [lovstudio-skills](https://github.com/MarkShawn2020/lovstudio-skills) 仓库，这是一个包含 25 个已发布 Skill 的 monorepo。我们把它们按照架构类型和复杂度分为三类：

### 纯指令 Skill（Pure Instruction Skill）

完全依赖 AI 的理解和推理能力，不包含任何脚本：

| Skill | 用途 | 章节 |
|-------|------|------|
| `thesis-polish` | MBA 论文润色 | Ch.5 |
| `auto-context` | 自动理解项目上下文 | Ch.5 |
| `visual-clone` | 从参考图片提取设计风格 | Ch.10 |
| `gh-tidy` | GitHub 仓库整理 | Ch.5 |
| `translation-review` | 翻译审校 | Ch.5 |

### 脚本 Skill（Script Skill）

核心逻辑由 Python / Shell / Node.js 脚本实现：

| Skill | 用途 | 语言 | 章节 |
|-------|------|------|------|
| `any2pdf` | Markdown → PDF | Python (reportlab) | Ch.7 |
| `any2docx` | Markdown → Word | Python (python-docx) | Ch.7 |
| `fill-form` | 填充 Word 模板 | Python (python-docx) | Ch.4, 5 |
| `pdf2png` | PDF → PNG 图片 | Shell (CoreGraphics) | Ch.7 |
| `skill-optimizer` | Skill 质量检测 | Python | Ch.11 |

### 混合 Skill（Hybrid Skill）

指令编排 + 脚本执行 + Skill 间调用：

| Skill | 用途 | 调用的其他 Skill | 章节 |
|-------|------|-----------------|------|
| `proposal` | 方案书生成 | `illustrate` + `any2pdf` | Ch.6, 8 |
| `any2deck` | Markdown → PPT | `image-creator` | Ch.6 |
| `tech-book` | 技术书出版流水线 | `md2pdf` + `gh-tidy` | Ch.6 |
| `xbti-creator` | 小报童封面生成 | `image-creator` | Ch.8 |
| `skill-creator` | 创建新 Skill | — (元技能) | Ch.3 |

在后续章节中，我们会反复回到这些 Skill，从不同角度剖析它们的设计决策。你不需要现在就理解每个 Skill 的细节 —— 只需要知道，本书的每一个设计原则、每一条最佳实践，都来自这些 Skill 的真实迭代经验。

---

## 1.6 本书的学习路径

本书分为五个部分，覆盖从入门到大师的全阶段：

### 第一部分：入门篇（Chapter 1-3）

**目标**：理解 Skill 是什么，能创建简单的 Skill。

- 本章：理解 Skill 的本质和生态定位
- 第 2 章：深度解读 SKILL.md 的结构和 Anthropic 6 大设计原则
- 第 3 章：搭建开发环境，创建你的第一个 Skill

**完成后你能**：独立创建一个纯指令 Skill，理解 frontmatter、instructions、workflow 三要素。

### 第二部分：设计篇（Chapter 4-7）

**目标**：写出高质量的 SKILL.md，掌握指令设计和脚本开发。

- 第 4 章：质量五维度模型 —— 如何定义和衡量「高质量」
- 第 5 章：指令设计的艺术 —— 精确度、交互设计、错误处理
- 第 6 章：Workflow 编排 —— 从线性流程到多阶段管线
- 第 7 章：脚本设计 —— Python / Shell / Node.js 最佳实践

**完成后你能**：设计带交互、带脚本的复杂 Skill，达到 agentskills.io 发布标准。

### 第三部分：进阶篇（Chapter 8-10）

**目标**：掌握 Skill 组合模式，打通 MCP 集成，实现多平台适配。

- 第 8 章：Skill 组合模式 —— Pipeline、Orchestrator、Shared Library
- 第 9 章：MCP 集成 —— 让 Skill 连接外部世界
- 第 10 章：多平台适配 —— 一个 Skill 跑遍所有 AI 助手

**完成后你能**：构建多 Skill 协作的复杂工作流，发布跨平台兼容的 Skill。

### 第四部分：大师篇（Chapter 11-13）

**目标**：掌握 Skill 质量工程、自我进化和安全发布。

- 第 11 章：测试、Lint 与持续优化
- 第 12 章：Skill 自我进化 —— OPRO、DSPy、TextGrad
- 第 13 章：发布、分发与安全

**完成后你能**：构建 Skill 的自动化质量管线，理解 Skill 进化的前沿方法论。

### 第五部分：展望篇（Chapter 14）

- Skill 市场经济、Agent-to-Agent 协作、标准化展望

---

## 1.7 小结

本章我们回答了一个核心问题：**为什么 Skill 重要？**

- Skill 不是更长的 Prompt，而是 AI 助手的「操作手册」—— 包含指令、脚本、参考资料的完整能力单元
- Skill 与 MCP 互补：MCP 给 AI 能力，Skill 教 AI 方法
- 2026 年的 Skill 生态已经成熟：70 万+ 社区 Skill、多平台支持、标准化市场
- Skill 的四大核心价值：复用、组合、分发、进化，构成一个自增强的生态
- Claude Code Skills 在架构完整性上领先（脚本支持、按需加载、Skill 间调用、版本管理），但 Cursor Rules 和 Windsurf Rules 在轻量场景下同样有效

下一章，我们将深入 SKILL.md 的内部结构，解读 Anthropic 的 6 大设计原则。这些原则是写出高质量 Skill 的基础 —— 无论你用哪个平台。

> **动手试试**：在你的终端执行 `claude` 启动 Claude Code，输入 `/skills`，浏览已安装的 Skill 列表。如果你还没有任何 Skill，没关系 —— 第 3 章我们就会创建第一个。
