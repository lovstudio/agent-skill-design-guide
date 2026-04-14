# 术语表 / Glossary

| 中文 | 英文 | 定义 |
|------|------|------|
| 技能 | Skill | AI 编程助手的可复用能力扩展单元，通常以 SKILL.md 为核心定义文件 |
| 指令 | Instruction | SKILL.md 中给 AI 助手的自然语言行为指导 |
| 工作流 | Workflow | Skill 的执行步骤编排，定义从输入到输出的完整流程 |
| 前置元数据 | Frontmatter | SKILL.md 顶部的 YAML 块，声明名称、版本、依赖等元信息 |
| 模型上下文协议 | MCP (Model Context Protocol) | Anthropic 提出的 AI 模型与外部工具/数据源的通信协议 |
| 触发 | Trigger | 用户或系统激活 Skill 的方式（命令调用、自动检测等） |
| 纯指令 Skill | Pure Instruction Skill | 不含脚本，完全依赖 AI 理解和执行指令的 Skill |
| 脚本 Skill | Script Skill | 包含可执行脚本（Python/Shell/Node.js）的 Skill |
| 混合 Skill | Hybrid Skill | 同时包含指令和脚本的 Skill |
| 热链接 | Symlink (dev mode) | 开发时将 Skill 源码目录符号链接到 AI 助手的 Skill 加载目录 |
