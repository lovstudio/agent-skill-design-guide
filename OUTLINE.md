# Agent Skill 高质量设计指南 — 全书大纲

> 作者：手工川 | 出版社：电子工业出版社
> 目标读者：有 AI 编程助手使用经验的中级开发者
> 全书约 13 章，每章 5000-8000 字，总计约 8-10 万字
> 实战案例库：[lovstudio-skills](https://github.com/MarkShawn2020/lovstudio-skills)（26 个已发布 Skill）

---

## 第一部分：基础篇 — 理解 Skill 的本质

### Chapter 1: 从 Prompt 到 Skill — AI 编程助手的能力扩展革命
- 什么是 Agent Skill？与 Prompt Template / Plugin / MCP Tool 的本质区别
- Skill 生态现状：Claude Code Skills、Cursor Rules、Windsurf Rules 对比
- 为什么 Skill 是 AI 编程的「杀手级应用」— 复用、组合、分发
- 本书的学习路径与实战案例库介绍
- 预估字数：~6000

### Chapter 2: Skill 架构解剖 — 从 SKILL.md 到运行时
- SKILL.md 的结构：Frontmatter + Instructions + Workflow
- 触发机制：用户调用 vs 自动触发 vs Skill 间组合调用
- 运行时模型：Skill 如何被 AI 助手加载、解析、执行
- 纯指令 Skill vs 脚本 Skill vs 混合 Skill — 三种架构范式
- 案例解剖：`lovstudio:thesis-polish`（纯指令）vs `lovstudio:any2pdf`（混合型）
- 依赖关系：章节 1
- 预估字数：~7000

### Chapter 3: 开发环境搭建与第一个 Skill
- Claude Code Skills 开发环境配置
- Skill 目录结构规范与命名约定
- 从零创建第一个 Skill：`hello-world` 完整流程
- dev.sh 热链接开发模式详解
- 案例：`lovstudio:skill-creator` — 用 Skill 创建 Skill
- 依赖关系：章节 2
- 预估字数：~5000

---

## 第二部分：设计篇 — 写出高质量 SKILL.md

### Chapter 4: Instruction 设计的艺术 — 让 AI 精确理解你的意图
- 指令粒度控制：太粗 AI 乱发挥，太细 AI 没弹性
- Mandatory 标记与流程编排：用 `MUST` / `NEVER` / `ALWAYS` 构建护栏
- 交互设计：AskUserQuestion 的最佳实践 — 何时问、问什么、怎么问
- 错误处理指令：当 Skill 遇到异常时的降级策略
- 案例对比：`lovstudio:fill-form`（强交互）vs `lovstudio:gh-tidy`（弱交互）
- 依赖关系：章节 2, 3
- 预估字数：~7000

### Chapter 5: Workflow 编排 — 从线性流程到复杂管线
- 线性 Workflow：Step 1 → Step 2 → Step 3
- 条件分支：根据用户输入走不同路径
- 循环与批处理：处理多文件、多章节场景
- 多阶段 Workflow：Phase 1 / Phase 2 跨会话设计
- 案例深度解析：`lovstudio:tech-book`（5 阶段跨会话）、`lovstudio:proposal`（多步管线）
- 依赖关系：章节 4
- 预估字数：~7000

### Chapter 6: 脚本设计 — Skill 的「肌肉」
- 何时需要脚本、何时纯指令足够 — 判断准则
- 脚本设计原则：单文件 CLI、argparse、无依赖安装地狱
- Python 脚本最佳实践：CJK 混排、主题系统、文件 I/O
- Shell 脚本最佳实践：跨平台兼容、依赖检测
- Node.js 脚本：前端相关 Skill 的选择
- 案例：`lovstudio:any2pdf` 的 reportlab 方案 vs `lovstudio:md2pdf` 的 pandoc 方案
- 依赖关系：章节 4, 5
- 预估字数：~8000

---

## 第三部分：进阶篇 — Skill 组合与生态

### Chapter 7: Skill 组合模式 — 从单兵到军团
- Skill 间调用：一个 Skill 如何调用另一个 Skill
- 依赖声明与依赖链管理
- 组合模式一：Pipeline（串联）— `any2pdf` → `pdf2png`
- 组合模式二：Orchestrator（编排）— `proposal` 调用 `illustrate` + `any2pdf`
- 组合模式三：Shared Library（共享）— 14 套主题系统跨 Skill 复用
- 反模式：循环依赖、隐式依赖、版本不一致
- 依赖关系：章节 5, 6
- 预估字数：~6000

### Chapter 8: MCP 集成 — 连接外部世界
- MCP（Model Context Protocol）快速入门
- Skill + MCP：让 Skill 获得网络搜索、数据库、API 调用能力
- 实战：用 context7 MCP 拉取最新文档写入 Skill
- 实战：用 Notion MCP 将 Skill 输出写入 Notion 数据库
- MCP Server 开发入门：为你的 Skill 生态构建专属 MCP
- 安全考量：MCP 权限模型与数据隔离
- 依赖关系：章节 7
- 预估字数：~7000

### Chapter 9: 多平台适配 — 一个 Skill 跑遍所有 AI 助手
- 平台差异分析：Claude Code vs Cursor vs Windsurf vs Cline
- 可移植性设计：抽象层 + 平台适配层
- Skill 触发方式的跨平台兼容
- 测试矩阵：如何验证 Skill 在不同平台的表现
- 案例：将 `lovstudio:visual-clone` 适配到 Cursor Rules
- 依赖关系：章节 4, 6
- 预估字数：~6000

---

## 第四部分：质量篇 — 测试、优化与发布

### Chapter 10: Skill 质量工程 — 测试、Lint 与持续优化
- Skill 测试的特殊性：你在测试一段给 AI 读的指令
- 手动测试方法论：场景矩阵 × 边界条件
- 自动化 Lint：`lovstudio:skill-optimizer` 的 lint 规则解析
- 版本管理：语义化版本 + CHANGELOG 最佳实践
- 性能优化：减少 token 消耗、提升首次执行成功率
- 案例：从 v0.1 到 v0.9 的迭代之路 — `lovstudio:any2docx` 的进化史
- 依赖关系：章节 6, 7
- 预估字数：~7000

### Chapter 11: 发布与分发 — 让 Skill 触达用户
- agentskills.io 发布流程详解
- GitHub 作为 Skill 分发渠道：README、安装脚本、版本标签
- Skill 仓库管理：monorepo vs polyrepo
- 安装体验设计：一行命令安装 Skill
- 案例：lovstudio-skills monorepo 的发布自动化（dev.sh + CI/CD）
- 依赖关系：章节 10
- 预估字数：~5000

### Chapter 12: 安全与合规 — Skill 的红线
- Prompt Injection 防御：恶意输入如何劫持 Skill
- 文件系统安全：Skill 脚本的读写权限边界
- 敏感信息处理：API Key、用户数据、.env 文件
- 合规考量：Skill 的许可证选择（MIT / Apache 2.0 / proprietary）
- 案例：`lovstudio:fill-web-form` 的安全设计 — 浏览器自动化的权限控制
- 依赖关系：章节 8, 10
- 预估字数：~6000

---

## 第五部分：展望篇

### Chapter 13: Skill 生态的未来 — 从个人工具到产业基础设施
- Skill 市场：从 App Store 类比看 Skill 经济
- Agent-to-Agent 协作：Skill 在多 Agent 架构中的角色
- Skill 标准化：OpenSkill 规范展望
- 从 Vibe Coding 到 Vibe Engineering — AI 编程的范式转移
- 手工川的实践哲学：26 个 Skill 背后的创业思考
- 依赖关系：章节 9, 11, 12
- 预估字数：~6000

---

## 附录

### Appendix A: Skill 速查模板
- SKILL.md 完整模板（带注释）
- 常用 Frontmatter 字段参考
- AskUserQuestion 模式速查

### Appendix B: lovstudio-skills 完整案例索引
- 26 个 Skill 的分类、复杂度、架构类型一览表
- 推荐学习路径

### Appendix C: 工具链安装指南
- Claude Code 安装与配置
- Python / Node.js 环境配置
- mdBook / Pandoc / gh CLI 等工具安装
