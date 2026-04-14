# 第 1 章：从 Prompt 到 Skill — AI 编程助手的能力扩展革命

> 本章状态：✅ 完成

---

**场景：哆啦 A 梦的四次元口袋**

凌晨两点，你接到一个紧急需求：把客户发来的 30 页 Word 方案书翻译成英文，重新排版成 PDF，然后生成一份带配图的摘要发到 Slack。

你打开 Claude Code，说了一句：

```
/proposal 帮我处理这份方案书，翻译成英文并输出 PDF
```

3 分钟后，一份排版精美的英文 PDF 出现在桌面上。Claude 自动调用了 `translation-review` 做翻译审校，用 `illustrate` 生成了配图，用 `any2pdf` 完成了排版，甚至用 `fill-web-form` 把摘要发到了 Slack。

你没有写一行代码，没有调试任何脚本，也没有在四个工具之间来回切换。你只是从口袋里掏出了需要的道具。

这个口袋，就是你的 **Skill 库**。

但更有意思的是 —— 如果你的口袋里没有合适的道具呢？有些 Agent（如 Hermes Agent）甚至能在执行任务的过程中**自动创建新 Skill**，把学到的领域知识沉淀为可复用的能力。下次遇到类似场景，Skill 已经在那里等你了。

这就是 Agent Skill 的本质 —— 不是一段更长的 Prompt，而是一套**可发现、可组合、可进化**的能力系统。

---

## 1.1 什么是 Agent Skill？

**Agent Skill（智能体技能）** 是 AI 编程助手的可复用能力扩展单元。它是一套完整的「行为规范 + 工具链」，让 AI 助手在特定领域拥有专家级别的执行能力。

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

三要素各司其职：

- **Frontmatter（前置元数据）**：告诉 AI「我是谁」「什么时候该调用我」
- **Instructions（指令正文）**：告诉 AI「怎么做」「注意什么」
- **Workflow（工作流）**：告诉 AI「按什么顺序执行」

Skill 与 Prompt Template、Plugin、MCP Tool 等相近概念有本质区别 —— 核心在于 Skill 是唯一同时具备**组合性**和**进化性**的抽象。因为 SKILL.md 本身就是自然语言，AI 不仅能执行它，还能阅读它、理解它、改进它。详细的概念对比表见[附录 A](../appendix-a.md)。

### MCP 与 Skill 的协作关系

MCP（Model Context Protocol，模型上下文协议）和 Skill 不是替代关系，而是互补关系：

- **MCP** 解决「能不能做」—— 让 AI 助手能访问数据库、调用 API、搜索网页
- **Skill** 解决「会不会做」—— 教 AI 助手如何高质量地完成一个复杂任务

一个成熟的 Skill 经常会调用 MCP Tool。比如 `lovstudio:proposal` 在生成方案书时，通过 MCP 调用 context7 拉取最新技术文档，再调用 `lovstudio:illustrate` 生成配图，最后调用 `lovstudio:any2pdf` 输出 PDF。Skill 是编排层，MCP 是能力层。

---

## 1.2 Skill 的前世今生 — 从 .cursorrules 到开放标准

Agent Skill 不是凭空出现的。它的演化脉络清晰可循：

### 2024：萌芽期 — 各自为战

| 时间 | 事件 | 意义 |
|------|------|------|
| 2024 年初 | Cursor 引入 `.cursorrules` 文件 | 首次将「给 AI 的持久指令」从对话中独立出来 |
| 2024 年中 | 社区出现 `awesome-cursorrules` 等仓库 | 证明开发者有强烈的规则共享需求 |
| 2024-06 | Anthropic 发布 Claude 3.5 Sonnet | 工具调用（tool use）能力质变，Agent 范式成为可能 |
| 2024-11 | Anthropic 发布 MCP 协议 | AI 与外部工具的标准化通信协议 |

这一年的关键洞察：**开发者不只想和 AI 对话，还想教 AI 做事，并且让这些教学成果持久化**。但各平台的格式互不兼容 —— `.cursorrules`、`.windsurfrules`、CLAUDE.md，各说各话。

### 2025：标准化 — 开放生态成型

| 时间 | 事件 | 意义 |
|------|------|------|
| 2025-02 | Claude 3.7 + Claude Code 发布 | Agent 编程正式进入主流，Claude Code 首次支持 Skills 目录 |
| 2025-10 | Anthropic 推出 Agent Skills 概念 | 将可复用 AI 能力正式定义为「Skill」 |
| 2025-11 | MCP 发布重大规范更新 | Tasks 原语、OAuth 2.1、Extensions 框架 |
| 2025-12-18 | **Anthropic 发布 Agent Skills 开放标准** | SKILL.md 规范 + SDK，agentskills.io 上线 |
| 2025-12-20 | **Microsoft、OpenAI 在 48 小时内采纳** | VS Code 集成 Skills，Codex CLI 支持相同格式 |
| 2025-12 | MCP 捐赠给 Linux Foundation (AAIF) | 协议治理中立化 |

2025-12-18 是 Skill 生态的「iPhone 时刻」。Anthropic 把 SKILL.md 发布为开放标准后，48 小时内 Microsoft 在 VS Code 中集成了 Skills 支持，OpenAI 在 Codex CLI 中添加了「结构相同的架构」。这种速度在开发者工具历史上罕见，说明 Skill 的抽象层次击中了行业共识。

### 2026：爆发期 — 平台竞争与生态繁荣

| 时间 | 事件 | 意义 |
|------|------|------|
| 2026-01 | Google Antigravity 正式采纳 Agent Skills 标准 | 三大 AI 公司全部入局 |
| 2026-02 | OpenClaw 开源，迅速增长至 345k stars | 最广泛的平台连接器（50+ 渠道）+ 44k 社区 Skill |
| 2026-02 | Hermes Agent 发布自进化引擎 | GEPA 算法实现 Skill 自主优化（ICLR 2026 Oral） |
| 2026-03 | Vercel 发布 `npx skills` CLI | 统一安装工具，支持 40+ Agent 平台 |
| 2026-04 | Skill 生态数据：87k stars（官方仓库）、70 万+ 社区 Skill、42.5 万+（SkillsMP） | 规模效应形成 |

2026 年的 Skill 生态呈现三个特征：

1. **标准统一**：SKILL.md 成为事实标准，`npx skills add` 一行命令在 40+ 平台安装
2. **自我进化**：Hermes Agent 的学习循环让 Skill 从「人写 AI 用」进化为「AI 写 AI 用」
3. **能力发现**：`find-skills` 等元技能让 Agent 能自动搜索并安装所需能力，真正实现「四次元口袋」

---

## 1.3 Skill 平台全景（2026 年 4 月）

2025 年底 SKILL.md 开放标准发布后，Skill 生态从单一平台扩展到 **40+ 平台共存** 的格局。

参考 [StackOne 的 120+ Agentic AI 工具分层](https://www.stackone.com/blog/ai-agent-tools-landscape-2026/)（Model → Harness → Orchestration 三层架构）和 [DataCamp 的 Agentic IDE 四类分类](https://www.datacamp.com/blog/best-agentic-ide)，我们可以将支持 Skills 的平台按**交互形态**分为四类：

### CLI Agent（终端原生 Agent）

开发者在终端中直接与 Agent 对话，Agent 拥有完整的文件系统、终端、Git 操作能力。2026 年最大的范式转移是 [从 IDE 插件到终端原生 Agent](https://peerpush.net/blog/coding-agents-in-2026)。

| 平台 | 厂商 | Skill 支持 | 特色 |
|------|------|-----------|------|
| **Claude Code** | Anthropic | SKILL.md 标准制定者；87k stars 官方仓库 | 终端 + Desktop + Web + IDE 全形态；脚本 / references / Skill 间调用全支持 |
| **Codex CLI** | OpenAI | SKILL.md 标准格式（48h 内采纳） | 云端沙箱执行，产出 diff/PR |
| **Gemini CLI** | Google | SKILL.md 标准格式 | 深度集成 Google 生态 |
| **Kiro** | AWS | 遵循 Agent Skills 标准 | Spec 驱动开发，强调可复现性 |
| **Goose, Aider** | 社区 | 通过 `npx skills` 支持 | 轻量级替代方案 |

### Agentic IDE（AI 原生编辑器）

在编辑器内提供 Agent 模式，兼顾代码编写和 Agent 任务：

| 平台 | 特点 | Skill 机制 |
|------|------|-----------|
| **Cursor** | VS Code fork，跨文件推理 | `.cursor/rules/*.mdc`，Glob 触发 |
| **Windsurf** | Cascade Agent 可视化执行计划 | `.windsurfrules`（2026 年声量下降） |
| **GitHub Copilot** | VS Code / JetBrains 原生集成 | VS Code Agent Skills 扩展 |

### 自治 Agent 框架（Orchestration 层）

独立运行的 Agent 框架，不依赖特定 IDE，侧重自主执行和多 Agent 协作：

| 平台 | Stars | Skill 生态 | 特色 |
|------|-------|-----------|------|
| **[OpenClaw](https://github.com/swarmclawai/swarmclaw)** | 345k | ClawHub 44k+ 社区 Skill | 50+ 渠道连接器；注意 [ClawHavoc 安全事件](https://thenewstack.io/persistent-ai-agents-compared/)（341 恶意 Skill） |
| **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** | — | 自动创建 + agentskills.io 标准 | 唯一内置学习循环；[GEPA 自进化（ICLR 2026 Oral）](https://github.com/NousResearch/hermes-agent-self-evolution) |

### Background Agent（后台自治 Agent）

从 Issue Tracker 或调度触发器拾取任务，在沙箱中独立运行，产出 PR：

| 平台 | 特点 |
|------|------|
| Codex (Cloud mode) | OpenAI 云端沙箱，自动产出 PR |
| GitHub Copilot Workspace | 从 Issue 到 PR 的端到端自动化 |
| Factory, Devin | 全自治软件工程 Agent |

> **分类说明**：以上四类并非互斥。Claude Code 同时覆盖 CLI + IDE 扩展 + Background（通过 CI/CD hooks）；OpenClaw 既是 Orchestration 框架，也可嵌入 IDE。分类依据的是平台的**主要交互形态**，参考 [DataCamp](https://www.datacamp.com/blog/best-agentic-ide)、[PeerPush](https://peerpush.net/blog/coding-agents-in-2026)、[StackOne](https://www.stackone.com/blog/ai-agent-tools-landscape-2026/) 的行业分析。

### 统一安装：`npx skills`

Vercel 的 [skills CLI](https://github.com/vercel-labs/skills) 是 Skill 生态的包管理器，一行命令覆盖 40+ 平台：

```bash
# 搜索 Skill
npx skills search "markdown to pdf"

# 安装到当前 Agent 平台（自动检测 Claude Code / Codex / Cursor 等）
npx skills add lovstudio:any2pdf

# 列出已安装的 Skill
npx skills list
```

这意味着 Skill 作者不需要为每个平台单独打包 —— 写一份 SKILL.md，通过 `npx skills` 分发到所有平台。

### 能力发现：find-skills

更进一步，一些 Agent 已经支持 **自动发现** Skill。当你提出一个任务，Agent 会先搜索是否已有合适的 Skill，如果没有，甚至会自动创建一个：

```
用户: "帮我把这个 CSV 转成可视化图表"

Agent 内部流程:
  1. 搜索已安装 Skill → 未找到 csv-to-chart
  2. 调用 find-skills → 在 SkillsMP 找到 data-viz 评分最高
  3. npx skills add data-viz → 安装
  4. 执行 data-viz → 输出图表
```

Hermes Agent 更进一步：如果找不到现成 Skill，它会在完成任务后**自动将解决方案沉淀为新 Skill**，存入 Memory 供下次复用。这就是本书第 12 章将深入探讨的「Skill 自我进化」。

---

## 1.4 为什么 Skill 是 AI 编程的「杀手级应用」

Skill 不只是「更高级的 prompt」。它解决了 AI 编程中四个根本性问题。

### 复用 — 知识不应该随对话消失

每次和 AI 对话，你都在「教」它做事。但对话结束后，教学成果消失了。Skill 把验证过的知识固化为文件：

```
Skill v0.1 → 能转换基本 Markdown
Skill v0.5 → 解决了 CJK 换行问题
Skill v0.8 → 支持 14 种色彩主题
Skill v1.2 → 双引擎（reportlab + pandoc）自动选择
```

以 `lovstudio:any2pdf` 为例，经过 1.2.0 版本迭代沉淀的 CJK 混排、字体回退、页面布局经验，任何人安装后都能直接受益。

### 组合 — 复杂任务需要多个能力协作

一个 Skill 做好一件事，多个 Skill 组合起来做更复杂的事 —— Unix 哲学在 AI 时代的延伸：

```
用户: "/proposal 帮我生成客户方案书"
  ↓
Step 1: 分析需求，生成大纲
Step 2: 调用 lovstudio:illustrate → 生成配图
Step 3: 组装 Markdown 正文
Step 4: 调用 lovstudio:any2pdf → 输出 PDF
  ↓
交付：一份图文并茂的方案书
```

### 分发 — 好的实践应该被传播

当你写出一个高质量 Skill，通过 `npx skills` 或 GitHub 分发，全世界 40+ 平台的开发者都能使用。**你不是在写代码，你是在教 AI 做事**。

Anthropic 官方的 `frontend-design` Skill 已积累 27.7 万次安装 —— 近 30 万个 AI 助手实例在使用同一套前端设计最佳实践。

### 进化 — Skill 可以自我改进

最令人兴奋的是 Skill 的进化能力。因为 SKILL.md 本身就是自然语言，AI 可以阅读、理解、改进它：

- **人工进化**：`lovstudio:skill-optimizer` 自动分析并优化其他 Skill
- **半自动进化**：基于执行日志的失败分析 → LLM 修订 → Lint 验证
- **全自动进化**：Hermes Agent 的 GEPA 引擎，从执行轨迹自动合成新 Skill

这四个特性同时存在时，产生的是乘法级效果：

```
个人 Skill → 分发到 40+ 平台 → 被组合到更大的 Workflow
    ↑                                         ↓
    └── 社区反馈 + AI 自进化 → 更好的版本 ←──┘
```

---

## 1.5 实战预告：lovstudio-skills — 26 个 Skill 的实践案例

本书的所有案例来自 [lovstudio-skills](https://github.com/MarkShawn2020/lovstudio-skills) 仓库（26 个已发布 Skill）。按架构类型分三类：

### 纯指令 Skill（Pure Instruction）

完全依赖 AI 的理解和推理能力，不含脚本：

| Skill | 用途 | 章节 |
|-------|------|------|
| `thesis-polish` | MBA 论文润色 | Ch.5 |
| `auto-context` | 自动理解项目上下文 | Ch.5 |
| `visual-clone` | 从参考图片提取设计风格 | Ch.10 |
| `gh-tidy` | GitHub 仓库整理 | Ch.5 |
| `translation-review` | 翻译审校 | Ch.5 |

### 脚本 Skill（Script-backed）

核心逻辑由 Python / Shell / Node.js 实现：

| Skill | 用途 | 语言 | 章节 |
|-------|------|------|------|
| `any2pdf` | Markdown → PDF | Python (reportlab) | Ch.7 |
| `any2docx` | Markdown → Word | Python (python-docx) | Ch.7 |
| `fill-form` | 填充 Word 模板 | Python (python-docx) | Ch.4, 5 |
| `pdf2png` | PDF → PNG 图片 | Shell (CoreGraphics) | Ch.7 |
| `skill-optimizer` | Skill 质量检测 | Python | Ch.11 |

### 混合 Skill（Hybrid — 指令编排 + 脚本 + Skill 间调用）

| Skill | 用途 | 调用的其他 Skill | 章节 |
|-------|------|-----------------|------|
| `proposal` | 方案书生成 | `illustrate` + `any2pdf` | Ch.6, 8 |
| `any2deck` | Markdown → PPT | `image-creator` | Ch.6 |
| `tech-book` | 技术书出版流水线 | mdBook + pandoc | Ch.6 |
| `xbti-creator` | 小报童封面 | `image-creator` | Ch.8 |
| `skill-creator` | 创建新 Skill | — (元技能) | Ch.3 |

---

## 1.6 本书的学习路径

本书 14 章覆盖入门到大师全阶段：

| 部分 | 章节 | 目标 | 完成后你能 |
|:----:|:----:|------|-----------|
| 🟢 入门 | Ch1-3 | 理解 Skill，创建第一个 | 独立创建纯指令 Skill，理解三要素 |
| 🟡 设计 | Ch4-7 | 写出高质量 SKILL.md | 设计带交互、带脚本的复杂 Skill，达到发布标准 |
| 🟠 进阶 | Ch8-10 | Skill 组合 + MCP + 跨平台 | 构建多 Skill 协作工作流，发布跨 40+ 平台的 Skill |
| 🔴 大师 | Ch11-13 | 质量工程 + 自进化 + 安全 | 构建自动化质量管线，理解前沿进化方法论 |
| 展望 | Ch14 | Skill 生态的未来 | 形成对 Skill 经济和 Agent 协作的前瞻判断 |

---

## 1.7 小结

本章回答了一个核心问题：**为什么 Skill 重要？**

- Skill 是 AI 助手的「四次元口袋」—— 可发现、可组合、可进化的能力系统
- 从 2024 年 `.cursorrules` 的萌芽，到 2025-12-18 开放标准发布（48 小时内 Microsoft、OpenAI 采纳），再到 2026 年 40+ 平台、70 万+ 社区 Skill，Skill 生态用一年半完成了从零到行业标准的跨越
- 2026 年的平台格局：Claude Code + Codex CLI + OpenClaw + Hermes Agent 领跑，`npx skills` 统一安装层，Cursor 等 IDE 跟进
- 四大核心价值 —— 复用、组合、分发、进化 —— 构成自增强飞轮
- Skill 自进化是最前沿的方向：从手动迭代到 AI 自主创建和优化 Skill

下一章，我们将深入 SKILL.md 的内部结构，解读 Anthropic 的 6 大设计原则。

> **动手试试**：执行 `npx skills search "pdf"` 搜索 PDF 相关的 Skill，或执行 `claude` 启动 Claude Code 后输入 `/skills` 浏览已安装列表。

---

## 延伸阅读

- [Anthropic 官方 Skills 指南（33 页 PDF）](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [Agent Skills 开放标准发布公告](https://thenewstack.io/agent-skills-anthropics-next-bid-to-define-ai-standards/)
- [Microsoft、OpenAI 48 小时内采纳 Skills 标准](https://byteiota.com/agent-skills-standard-microsoft-openai-adopt-in-48-hours/)
- [Skills CLI (npx skills)](https://github.com/vercel-labs/skills)
- [OpenClaw vs Hermes Agent 深度对比](https://thenewstack.io/persistent-ai-agents-compared/)
- [SkillsBench: 首个 Skill 质量基准测试 (arXiv)](https://arxiv.org/html/2602.12670v1)
