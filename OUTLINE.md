# Agent Skill 高质量设计指南 — 全书大纲

> 作者：手工川 | 出版社：电子工业出版社
> 目标读者：入门 → 进阶 → 大师（全阶段覆盖）
> 全书 14 章 + 3 附录，每章 5000-8000 字，总计约 10-12 万字
> 实战案例库：[lovstudio-skills](https://github.com/MarkShawn2020/lovstudio-skills)（26 个已发布 Skill）
> 核心参考：[Anthropic 官方 Skills 指南（33 页）](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) · [anthropics/skills](https://github.com/anthropics/skills)

---

## 第一部分：入门篇 — 理解 Skill 的本质 🟢 Beginner

### Chapter 1: 从 Prompt 到 Skill — AI 编程助手的能力扩展革命
- 什么是 Agent Skill？与 Prompt Template / Plugin / MCP Tool 的本质区别
- Skill 生态现状（2026）：Claude Code 4% GitHub 提交、87k stars 官方仓库、70 万+ 社区 Skill
- 三大平台对比：Claude Code Skills vs Cursor Rules vs Windsurf Rules
- 为什么 Skill 是 AI 编程的「杀手级应用」— 复用、组合、分发、进化
- 本书的学习路径：入门 → 进阶 → 大师，每部分能力目标
- 预估字数：~6000

### Chapter 2: Skill 架构解剖 — Anthropic 官方规范深度解读
- SKILL.md 的结构：Frontmatter + Instructions + Workflow
- **Anthropic 6 大设计原则**（源自官方 33 页指南）：
  - 原则 1：Description 是触发命脉 — 所有 "when to use" 信息写在 description
  - 原则 2：Body 控制在 500 行 / 5000 token 以内
  - 原则 3：引用资料用 references/ 按需加载，不要塞进 body
  - 原则 4：指令精确度匹配任务脆弱度 — 脆弱任务高精度，灵活任务留自由度
  - 原则 5：Skill 是文件夹 — scripts、assets、data 都是 Skill 的一部分
  - 原则 6：Execute-then-revise — 一轮执行+修订即可显著提升质量
- 运行时模型：Skill 如何被 AI 助手加载、解析、执行
- 纯指令 Skill vs 脚本 Skill vs 混合 Skill — 三种架构范式
- 案例解剖：`lovstudio:thesis-polish`（纯指令）vs `lovstudio:any2pdf`（混合型）vs Anthropic `frontend-design`（27.7 万安装）
- 依赖关系：章节 1
- 预估字数：~8000

### Chapter 3: 开发环境搭建与第一个 Skill
- Claude Code Skills 开发环境配置
- Skill 目录结构规范与命名约定
- 从零创建第一个 Skill：`hello-world` 完整流程
- dev.sh 热链接开发模式详解
- 案例：`lovstudio:skill-creator` — 用 Skill 创建 Skill
- 依赖关系：章节 2
- 预估字数：~5000

---

## 第二部分：设计篇 — 写出高质量 SKILL.md 🟡 Intermediate

### Chapter 4: Skill 质量模型 — 如何定义和衡量「高质量」
- **质量五维度模型**（本书核心框架）：
  - 触发准确率（Trigger Precision）：description 能否在正确场景被精准激活
  - 首次执行成功率（First-Run Success Rate）：用户首次调用能否得到预期结果
  - Token 效率（Token Efficiency）：完成任务消耗的 token 数
  - 可维护性（Maintainability）：他人能否理解、修改、扩展
  - 可组合性（Composability）：能否与其他 Skill 无缝协作
- **SkillsBench 基准测试**（arXiv 2602.12670）：业界首个 Skill 质量评估框架
- **agentskills.io 评审标准**：Functional Viability、Task Realism、Anti-cheating
- 质量等级定义：L1 可用 → L2 好用 → L3 优秀 → L4 卓越
- 案例：用五维度模型评估 `lovstudio:fill-form` 从 v0.1 到 v0.8 的质量跃迁
- 依赖关系：章节 2, 3
- 预估字数：~7000

### Chapter 5: Instruction 设计的艺术 — 让 AI 精确理解你的意图
- 指令粒度控制：太粗 AI 乱发挥，太细 AI 没弹性 — 精确度匹配脆弱度
- Mandatory 标记与流程编排：用 `MUST` / `NEVER` / `ALWAYS` 构建护栏
- 交互设计：AskUserQuestion 的最佳实践 — 何时问、问什么、怎么问
- 上下文管理：references/ 按需加载策略（"Read X if condition Y"）
- 错误处理指令：当 Skill 遇到异常时的降级策略
- 案例对比：`lovstudio:fill-form`（强交互）vs `lovstudio:gh-tidy`（弱交互）
- 依赖关系：章节 4
- 预估字数：~7000

### Chapter 6: Workflow 编排 — 从线性流程到复杂管线
- 线性 Workflow：Step 1 → Step 2 → Step 3
- 条件分支：根据用户输入走不同路径
- 循环与批处理：处理多文件、多章节场景
- 多阶段 Workflow：Phase 1 / Phase 2 跨会话设计
- 案例深度解析：`lovstudio:tech-book`（5 阶段跨会话）、`lovstudio:proposal`（多步管线）
- 依赖关系：章节 5
- 预估字数：~7000

### Chapter 7: 脚本设计 — Skill 的「肌肉」
- 何时需要脚本、何时纯指令足够 — 判断准则
- 脚本设计原则：单文件 CLI、argparse、无依赖安装地狱
- Python 脚本最佳实践：CJK 混排、主题系统、文件 I/O
- Shell 脚本最佳实践：跨平台兼容、依赖检测
- Node.js 脚本：前端相关 Skill 的选择
- 案例：`lovstudio:any2pdf` 的 reportlab 方案 vs `lovstudio:md2pdf` 的 pandoc 方案
- 依赖关系：章节 5, 6
- 预估字数：~8000

---

## 第三部分：进阶篇 — Skill 组合与生态 🟠 Advanced

### Chapter 8: Skill 组合模式 — 从单兵到军团
- Skill 间调用：一个 Skill 如何调用另一个 Skill
- 依赖声明与依赖链管理
- 组合模式一：Pipeline（串联）— `any2pdf` → `pdf2png`
- 组合模式二：Orchestrator（编排）— `proposal` 调用 `illustrate` + `any2pdf`
- 组合模式三：Shared Library（共享）— 14 套主题系统跨 Skill 复用
- 反模式：循环依赖、隐式依赖、版本不一致
- 依赖关系：章节 6, 7
- 预估字数：~6000

### Chapter 9: MCP 集成 — 连接外部世界
- MCP（Model Context Protocol）快速入门 — 2025-11 规范要点
- Skill + MCP：让 Skill 获得网络搜索、数据库、API 调用能力
- 实战：用 context7 MCP 拉取最新文档写入 Skill
- 实战：用 Notion MCP 将 Skill 输出写入 Notion 数据库
- MCP Server 开发入门：为你的 Skill 生态构建专属 MCP
- 安全考量：MCP 权限模型与数据隔离（OAuth 2.1 授权框架）
- 依赖关系：章节 8
- 预估字数：~7000

### Chapter 10: 多平台适配 — 一个 Skill 跑遍所有 AI 助手
- 平台差异分析：Claude Code vs Cursor vs Windsurf vs Cline vs Codex CLI vs Gemini CLI
- 可移植性设计：SKILL.md 通用格式的跨平台兼容性
- Skill 触发方式的跨平台兼容
- 测试矩阵：如何验证 Skill 在不同平台的表现
- 案例：将 `lovstudio:visual-clone` 适配到 Cursor Rules
- 依赖关系：章节 5, 7
- 预估字数：~6000

---

## 第四部分：大师篇 — 质量工程、进化与发布 🔴 Master

### Chapter 11: Skill 质量工程 — 测试、Lint 与持续优化
- Skill 测试的特殊性：你在测试一段给 AI 读的指令
- 手动测试方法论：场景矩阵 × 边界条件 × 负面测试
- 自动化 Lint：`lovstudio:skill-optimizer` 的 lint 规则解析
- **Agent Skill Evals**：构建评估管线（参考 Google Cloud Agent Skills Evals 方法论）
- 版本管理：语义化版本 + CHANGELOG 最佳实践
- 性能优化：减少 token 消耗、提升首次执行成功率
- 案例：从 v0.1 到 v0.9 的迭代之路 — `lovstudio:any2docx` 的进化史
- 依赖关系：章节 4, 7, 8
- 预估字数：~7000

### Chapter 12: Skill 自我进化 — 让 Skill 自己变得更好
- **为什么需要自我进化**：人工迭代的瓶颈 → 自动化进化的必然
- **进化方法论谱系**：
  - OPRO（LLM-as-Optimizer）→ EvoPrompt（进化算法）→ PromptBreeder（自引用进化）→ DSPy MIPRO（编程化优化）→ TextGrad（文本反向传播）
- **开源进化引擎实战**：
  - [EvoMap Evolver](https://github.com/EvoMap/evolver)：GEP 协议 — Skill 基因级遗传、跨 Agent 继承
  - [Hermes Agent Self-Evolution](https://github.com/NousResearch/hermes-agent-self-evolution)：DSPy + GEPA 引擎（ICLR 2026 Oral）
  - [EvoSkill](https://github.com/sentient-agi/EvoSkill)：从失败轨迹自动合成可复用 Skill
  - [OpenSpace](https://github.com/HKUDS/OpenSpace)：跨行业 Skill 进化（4.2x 效能提升）
- **实战：构建 Skill 进化管线**：
  - 方案 A：Experience-Based（最实用）— 日志收集 → 失败分析 → LLM 修订 → Lint 验证
  - 方案 B：DSPy MIPRO — 定义 metric → 自动生成 SKILL.md 变体 → 择优
  - 方案 C：TextGrad — 执行反馈作为梯度 → 文本反向传播更新 SKILL.md
- 案例：设计 `lovstudio:skill-evolver` 元技能 — 让 Skill 优化自身
- 依赖关系：章节 4, 11
- 预估字数：~8000

### Chapter 13: 发布、分发与安全
- agentskills.io 发布流程详解
- GitHub 作为 Skill 分发渠道：README、安装脚本、版本标签
- Skill 仓库管理：monorepo vs polyrepo
- 安装体验设计：一行命令安装 Skill
- Prompt Injection 防御：恶意输入如何劫持 Skill
- 文件系统安全：Skill 脚本的读写权限边界
- 敏感信息处理：API Key、用户数据、.env 文件
- 合规考量：Skill 的许可证选择（MIT / Apache 2.0 / proprietary）
- 案例：lovstudio-skills monorepo 的发布自动化 + `fill-web-form` 的安全设计
- 依赖关系：章节 11
- 预估字数：~7000

---

## 第五部分：展望篇

### Chapter 14: Skill 生态的未来 — 从个人工具到产业基础设施
- Skill 市场经济：从 App Store 类比看 Skill 商业化
- Agent-to-Agent 协作：Skill 在多 Agent 架构中的角色
- Skill 标准化：SKILL.md 通用规范 → OpenSkill 协议展望
- 从 Vibe Coding 到 Vibe Engineering — AI 编程的范式转移
- Skill 自进化的终局：自我编写、自我优化、自我淘汰的 Skill 生态
- 手工川的实践哲学：26 个 Skill 背后的创业思考
- 依赖关系：章节 10, 12, 13
- 预估字数：~6000

---

## 附录

### Appendix A: Skill 速查模板
- SKILL.md 完整模板（带注释，标注 Anthropic 6 原则对应位置）
- 常用 Frontmatter 字段参考
- AskUserQuestion 模式速查
- 质量检查清单（五维度自评表）

### Appendix B: lovstudio-skills 完整案例索引
- 26 个 Skill 的分类、复杂度、架构类型、质量评级一览表
- 按学习阶段推荐的案例路径：入门 5 个 → 进阶 5 个 → 大师 5 个

### Appendix C: 工具链与参考资源
- Claude Code 安装与配置
- Python / Node.js 环境配置
- mdBook / Pandoc / gh CLI 等工具安装
- 核心论文列表（PromptBreeder、DSPy、TextGrad、GEPA 等）
- 社区资源：awesome-claude-code、agentskills.io、SkillsMP
