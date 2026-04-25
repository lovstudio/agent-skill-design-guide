<p align="center">
  <img src="assets/images/cover.png" alt="Agent Skill 高质量设计指南 Cover" width="100%">
</p>

<h1 align="center">
  <img src="assets/logo.svg" width="32" height="32" alt="Logo" align="top">
  Agent Skill 高质量设计指南
</h1>

<p align="center">
  <strong>系统掌握 AI 编程助手 Skill 设计方法论，从架构到发布的完整指南</strong><br>
  <sub>14 章 · 约 10 万字 · 26 个开源 Skill 实战案例</sub>
</p>

<p align="center">
  <a href="#在线阅读">在线阅读</a> ·
  <a href="#目录">目录</a> ·
  <a href="#为什么写这本书">为什么</a> ·
  <a href="#本地构建">本地构建</a> ·
  <a href="#参与贡献">贡献</a>
</p>

<p align="center">
  <a href="https://github.com/lovstudio/agent-skill-design-guide/actions"><img src="https://github.com/lovstudio/agent-skill-design-guide/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="License"></a>
  <a href="https://github.com/lovstudio/agent-skill-design-guide/stargazers"><img src="https://img.shields.io/github/stars/lovstudio/agent-skill-design-guide?style=social" alt="Stars"></a>
</p>

---

## 这本书讲什么

2026 年，Agent Skill 已成为 AI 编程助手能力扩展的事实标准——
Claude Code Skills 占据 GitHub 全站 4% 的提交，社区 Skill 数量突破 70 万。
但「写一个能跑的 Skill」和「写一个真正高质量的 Skill」之间，隔着一整本书的距离。

本书系统拆解 **从 Prompt 到 Skill 的能力扩展革命**：

- **架构层面**：Anthropic 官方 6 大设计原则、Progressive Disclosure 心智模型、SKILL.md 三层结构
- **质量层面**：5DQM 五维质量模型（触发准确率 / FRSR / Token 效率 / 可维护性 / 可组合性）
- **工程层面**：Instruction 编排、Workflow 四层复杂度、脚本设计模式、Skill 测试与 Lint
- **生态层面**：组合模式（Pipeline / Orchestrator / Shared Library）、MCP 集成、多平台适配
- **进化层面**：从 OPRO 到 GEPA 的自进化方法论谱系，让 Skill 自己变得更好

每一章都有 [`lovstudio/skills`](https://github.com/lovstudio/skills) 中的真实案例佐证。

## 在线阅读

📖 **mdBook 站点**：<https://lovstudio.github.io/agent-skill-design-guide/>

📥 **PDF 下载**：见 [Releases](https://github.com/lovstudio/agent-skill-design-guide/releases) 或 [`output/`](output/) 目录

## 目录

| # | 章节 | 字数 | 核心 |
|---|------|------|------|
| **第一部分** | **入门篇 · 理解 Skill 的本质** | | |
| 01 | [从 Prompt 到 Skill](src/chapter-01/) | ~6K | Skill 生态 2026 + 三大平台对比 |
| 02 | [Skill 架构解剖](src/chapter-02/) | ~8K | Anthropic 6 大设计原则深度解读 |
| 03 | [开发环境与第一个 Skill](src/chapter-03/) | ~5K | hello-world 完整流程 + dev.sh 详解 |
| **第二部分** | **设计篇 · 写出高质量 SKILL.md** | | |
| 04 | [Skill 质量模型](src/chapter-04/) | ~7K | 5DQM 框架 + L1–L4 质量等级 |
| 05 | [Instruction 设计的艺术](src/chapter-05/) | ~7K | MUST/NEVER/ALWAYS 护栏 + 精确度匹配脆弱度 |
| 06 | [Workflow 编排](src/chapter-06/) | ~7K | 四层复杂度 + Mapping Table 模式 |
| 07 | [脚本设计](src/chapter-07/) | ~8K | 单文件 CLI + CJK 三件套 + reportlab vs pandoc |
| **第三部分** | **进阶篇 · Skill 组合与生态** | | |
| 08 | [Skill 组合模式](src/chapter-08/) | ~6K | Pipeline / Orchestrator / Shared Library |
| 09 | [MCP 集成](src/chapter-09/) | ~7K | 三大原语 + FastMCP Server 开发 |
| 10 | [多平台适配](src/chapter-10/) | ~6K | Claude / Cursor / Windsurf / Cline 全景对比 |
| **第四部分** | **大师篇 · 质量工程、进化与发布** | | |
| 11 | [Skill 质量工程](src/chapter-11/) | ~7K | Lint 16 条规则 + Skill Evals 四级体系 |
| 12 | [Skill 自我进化](src/chapter-12/) | ~8K | OPRO → DSPy MIPRO → TextGrad → GEPA |
| 13 | [发布、分发与安全](src/chapter-13/) | ~7K | Prompt Injection 防御 + 一行安装设计 |
| **第五部分** | **展望篇** | | |
| 14 | [Skill 生态的未来](src/chapter-14/) | ~6K | 从 Vibe Coding 到 Vibe Engineering |
| **附录** | A: 速查模板 · B: 案例索引 · C: 工具链 | | |

完整大纲见 [`OUTLINE.md`](OUTLINE.md)。

## 为什么写这本书

我是 [手工川](https://github.com/MarkShawn2020) (Mark Shawn)，[LovStudio](https://lovstudio.ai) 创始人。

过去一年我开源了 26 个 Claude Code Skill（[lovstudio/skills](https://github.com/lovstudio/skills)），
在反复迭代中积累了大量"踩过的坑"和"被验证有效的模式"。
本书是这些经验的体系化沉淀——不是给"会用 Skill"的读者，而是给想"做 Skill"的读者。

如果你是：
- 想为团队/社区贡献 Skill 的工程师 → 第二、第三部分是核心
- 在做 AI 编程基础设施的产品/平台方 → 第四、第五部分会有共鸣
- 单纯好奇"AI 编程助手到底怎么进化"的研究者 → 第 12 章值得一读

## 本地构建

依赖 [mdBook](https://rust-lang.github.io/mdBook/)：

```bash
# 安装 mdBook（需 Rust toolchain）
cargo install mdbook

# 本地预览（http://localhost:3000）
mdbook serve --open

# 构建静态站点到 book/
mdbook build

# 构建 PDF（需 pandoc + xelatex）
./scripts/build-pdf.sh
```

## 配套资源

- 🛠 **代码仓库**：[lovstudio/skills](https://github.com/lovstudio/skills) — 26 个开源 Skill
- 🎨 **演讲幻灯片**：[15 分钟 Neo-Brutalism PPT](https://github.com/lovstudio/agent-skill-design-guide/releases) — 适合 meetup / 内部分享
- 📚 **核心参考**：
  - [Anthropic Skills 官方指南（33 页 PDF）](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
  - [anthropics/skills](https://github.com/anthropics/skills) — 官方 Skill 仓库
  - [agentskills.io](https://agentskills.io) — 社区 Skill 集市

## 参与贡献

- 内容勘误 / 案例补充 → 直接开 PR，每章都有 "Edit this page" 按钮
- 想分享你的 Skill 实战 → 开 Issue 或邮件到 `mark@lovstudio.ai`
- 翻译协作（英文版进行中）→ 见 [Issue #1](https://github.com/lovstudio/agent-skill-design-guide/issues/1)

引用约定：`手工川. Agent Skill 高质量设计指南. lovstudio, 2026.`

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=lovstudio/agent-skill-design-guide&type=Date)](https://star-history.com/#lovstudio/agent-skill-design-guide&Date)

## License

[Apache License 2.0](LICENSE) © 2026 手工川 · LovStudio

代码与脚本：自由使用、修改、分发。
书稿正文：欢迎引用与摘录，转载请保留作者与项目链接。
