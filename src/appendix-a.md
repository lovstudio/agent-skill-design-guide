# 附录 A：Skill 速查模板

## A.1 Skill 与相近概念对比

| 概念 | 持久性 | 可复用 | 带工具 | 可组合 | 可进化 | 可分发 |
|------|--------|--------|--------|--------|--------|--------|
| **Prompt** | ❌ 单次 | ❌ 复制粘贴 | ❌ 纯文本 | ❌ | ❌ | ❌ |
| **Prompt Template** | ✅ 可保存 | ✅ 参数化 | ❌ 纯文本 | ❌ | ❌ | ⚠️ 手动分享 |
| **Plugin / Extension** | ✅ | ✅ | ✅ 代码级 | ⚠️ 有限 | ❌ | ✅ 商店分发 |
| **MCP Tool** | ✅ | ✅ | ✅ API 级 | ✅ 协议标准 | ❌ | ✅ Registry |
| **Agent Skill** | ✅ | ✅ | ✅ 指令+脚本 | ✅ Skill 间调用 | ✅ 自进化 | ✅ 市场分发 |

**核心区别**：

- **Prompt Template** 给人用 —— 人填参数、人发送、人检查结果
- **Plugin** 给平台用 —— 平台加载代码、调用 API、返回结构化结果
- **MCP Tool** 给模型用 —— 模型通过标准协议调用外部能力
- **Skill** 给 AI 助手用 —— AI 读懂指令、自主决策、调用工具链、交付完整结果

类比：如果 AI 助手是一个新员工，Prompt 是口头交代的任务，Plugin 是公司配的工具，MCP Tool 是内部系统的 API 接口，而 **Skill 是一本操作手册**。

---

## A.2 SKILL.md 完整模板

```yaml
---
# ===== 必填字段 =====
name: your-namespace:skill-name        # 命名空间:技能名
description: >
  一句话描述 Skill 做什么。
  Trigger when user mentions "关键词1", "关键词2".
  Use this when user wants to [场景描述].

# ===== 可选字段 =====
metadata:
  version: "0.1.0"                     # 语义化版本
  author: "Your Name"
  license: "MIT"
  tags: [tag1, tag2, tag3]
  compatibility:
    - claude-code
    - codex-cli
    - cursor
---

# skill-name — 简短描述

## When to Use

- 用户想要 [场景 1]
- 用户提到 [关键词]
- 文件类型为 [.xxx]

## Pre-Check (MANDATORY)

**You MUST use `AskUserQuestion` before proceeding:**

1. [选项 1]：具体描述
2. [选项 2]：具体描述

## Workflow

### Step 1: 收集信息
- 使用 AskUserQuestion 确认参数

### Step 2: 执行核心任务
- 调用 scripts/main.py 或直接用 AI 能力完成
- MUST: [关键约束]
- NEVER: [禁止行为]

### Step 3: 验证与交付
- 检查输出完整性
- 向用户汇报结果

## Configuration Reference

| 参数 | 默认值 | 描述 |
|------|--------|------|
| `--input` | (必填) | 输入文件路径 |
| `--output` | `output.xxx` | 输出文件路径 |

## Dependencies

\```bash
pip install some-package
\```
```

### Anthropic 6 大原则对应位置

| 原则 | 对应位置 |
|------|---------|
| 1. Description 是触发命脉 | `description` 字段 — 包含 "when to use" + 触发关键词 |
| 2. Body ≤ 500 行 / 5000 token | 整个 `---` 之后的正文部分 |
| 3. 引用资料用 references/ | 在 Step 中写 `Read references/xxx.md if [条件]` |
| 4. 精确度匹配脆弱度 | MUST/NEVER 标记用在关键步骤，灵活步骤留自由度 |
| 5. Skill 是文件夹 | scripts/ + references/ + examples/ + assets/ |
| 6. Execute-then-revise | 先跑一遍，根据结果修订 SKILL.md |

---

## A.3 AskUserQuestion 模式速查

### 单选（默认）

```json
{
  "question": "选择输出格式？",
  "header": "格式",
  "options": [
    {"label": "PDF（推荐）", "description": "排版精美，适合分发"},
    {"label": "DOCX", "description": "可编辑，适合协作"}
  ],
  "multiSelect": false
}
```

### 多选

```json
{
  "question": "需要哪些附加功能？",
  "header": "功能",
  "options": [
    {"label": "目录", "description": "自动生成 TOC"},
    {"label": "水印", "description": "添加文字水印"},
    {"label": "封面", "description": "生成封面页"}
  ],
  "multiSelect": true
}
```

### 最佳实践

- 一次最多问 4 个问题（AskUserQuestion 限制）
- 推荐选项放第一个，标注「（推荐）」
- 用户可以选「Other」自由输入，不需要穷举所有选项
- 简单任务不要问太多 —— 合理默认值优于反复确认

---

## A.4 质量检查清单（五维度自评）

| 维度 | 检查项 | ✅ / ❌ |
|------|--------|:------:|
| **触发准确率** | description 包含明确的触发关键词？ | |
| | description 包含 "when to use" 场景描述？ | |
| | 不会在无关场景被误触发？ | |
| **首次成功率** | 有 AskUserQuestion 收集必要参数？ | |
| | 有合理默认值避免用户决策疲劳？ | |
| | 错误场景有降级策略？ | |
| **Token 效率** | Body ≤ 500 行？ | |
| | 详细资料放在 references/ 按需加载？ | |
| | 没有冗余的重复说明？ | |
| **可维护性** | 有语义化版本号？ | |
| | Workflow 步骤有编号和明确输入输出？ | |
| | 关键约束用 MUST/NEVER 标记？ | |
| **可组合性** | 依赖的其他 Skill 有明确声明？ | |
| | 输入输出格式标准化？ | |
| | 可独立运行也可被其他 Skill 调用？ | |
