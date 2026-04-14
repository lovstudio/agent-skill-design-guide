# 第 9 章：MCP 集成 — 连接外部世界

> "Skill 定义了 AI 能做什么；MCP 决定了 AI 能连接什么。两者结合，才是完整的 Agent。"

前几章我们一直在打磨 Skill 的内功 — 精准的 Instruction、流畅的 Workflow、健壮的脚本。但一个 Skill 如果只能操作本地文件系统，就像一台断网的电脑：能力再强也只能自给自足。

本章的主角是 **MCP（Model Context Protocol）** — 2024 年底由 Anthropic 发布的开放协议，它为 AI 助手提供了一套标准化的方式来连接外部工具、数据源和 API。截至 2026 年初，MCP Registry 已索引超过 20,000 个公开 Server，月均 SDK 下载量突破 9,700 万次，ChatGPT、Claude、Gemini、Copilot、Cursor 等主流 AI 平台均已原生支持。

如果 Skill 是 Agent 的大脑，MCP 就是它的神经系统。

---

## 9.1 MCP 快速入门 — 协议要点

### 9.1.1 一句话定义

MCP 是一个基于 JSON-RPC 2.0 的 C/S 协议，定义了 AI 应用（Client）与外部能力提供方（Server）之间的标准通信方式。你可以把它理解为 **AI 世界的 USB-C** — 一个接口，连接一切。

### 9.1.2 核心概念

MCP 协议围绕三个原语（Primitive）构建：

| 原语 | 方向 | 用途 | 类比 |
|------|------|------|------|
| **Tool** | Client → Server | 让 AI 调用外部功能（搜索、查询、写入） | 函数调用 |
| **Resource** | Client → Server | 让 AI 读取外部数据（文档、数据库记录） | 只读 API |
| **Prompt** | Server → Client | Server 提供预设的 Prompt 模板 | Skill 的 Instruction |

这三个原语覆盖了 AI 与外部世界交互的绝大多数场景。Tool 负责"做事"，Resource 负责"读数据"，Prompt 负责"教 AI 怎么用我"。

### 9.1.3 传输层

MCP 不绑定特定传输协议。当前规范支持三种传输方式：

- **Stdio**：通过标准输入/输出通信，适合本地进程。大多数 CLI 集成的 MCP Server 使用此方式。
- **Streamable HTTP**：基于 HTTP 的流式传输，2025-11 规范推荐的生产环境方案，替代了早期的 SSE 方案。
- **SSE（Server-Sent Events）**：早期方案，仍在广泛使用，但新项目建议使用 Streamable HTTP。

### 9.1.4 2025-11 规范重大更新

2025 年 11 月 25 日 — MCP 发布一周年之际 — 规范迎来了最大一次更新。核心变化：

**Tasks（异步任务）**：任何请求都可以变成"先调用、后获取"的异步模式。Task 的状态机包括 `working` → `input_required` → `completed` / `failed` / `cancelled`。这对需要多步交互的复杂操作至关重要。

**OAuth 2.1 授权框架**：引入标准化的授权流程，支持 Client Credentials（机器对机器）和企业 IdP 策略控制。Client 可以提供一个 URL 指向自身的 JSON 描述文档，Server 据此做权限决策。

**Extensions 机制**：为协议引入了扩展点，允许社区在不修改核心协议的情况下添加新能力。Authorization Extensions 是第一批官方扩展。

**Sampling with Tools**：MCP Server 现在可以在发起 Sampling 请求时附带 Tool 定义，使得 Server 端也能运行 Agent 循环。

### 9.1.5 治理：从 Anthropic 到 Linux Foundation

2025 年 12 月，Anthropic 将 MCP 捐赠给 Linux Foundation 下新成立的 **Agentic AI Foundation（AAIF）**。AAIF 由 Anthropic、Block、OpenAI 联合创立，Google、Microsoft、AWS、Cloudflare 等参与支持。MCP 与 Block 的 goose、OpenAI 的 AGENTS.md 一起成为 AAIF 的创始项目。

这意味着 MCP 不再是 Anthropic 的"家规"，而是整个行业的开放标准。对 Skill 开发者来说，这是一个明确的信号：**押注 MCP 是安全的。**

---

## 9.2 Skill + MCP：架构模式

### 9.2.1 Skill 和 MCP 的关系

先厘清一个常见误解：**Skill 不是 MCP Server，MCP Server 也不是 Skill。** 它们解决不同层次的问题：

- **Skill** 是给 AI 助手的操作手册 — 它告诉 AI "你现在要扮演什么角色、执行什么流程、产出什么结果"。
- **MCP Server** 是给 AI 助手的工具箱 — 它告诉 AI "你可以调用哪些外部能力"。

两者的结合才是完整的 Agent 能力栈：

```
┌─────────────────────────────────┐
│         AI 助手 (Client)          │
│  ┌───────────┐  ┌────────────┐  │
│  │   Skill   │  │ MCP Client │  │
│  │ (Workflow) │  │ (连接管理)   │  │
│  └─────┬─────┘  └──────┬─────┘  │
│        │               │        │
│   "做什么"          "用什么做"     │
└────────┼───────────────┼────────┘
         │               │
         ▼               ▼
   本地脚本/文件     MCP Server(s)
                   ┌──────────┐
                   │ 搜索引擎  │
                   │ 数据库    │
                   │ Notion   │
                   │ GitHub   │
                   │ ...      │
                   └──────────┘
```

### 9.2.2 三种集成模式

**模式一：Skill 编排，MCP 执行**

最常见的模式。Skill 的 Instruction 中引用 MCP Tool，让 AI 在执行 Workflow 时调用外部能力。

```markdown
<!-- SKILL.md 片段 -->
## Workflow

1. 使用 `web_search` 工具搜索用户提供的主题，获取最新资料
2. 整理搜索结果，提取关键信息
3. 根据模板生成报告
4. 使用 `notion_create_page` 工具将报告写入 Notion 数据库
```

Skill 只负责编排流程，实际的搜索和写入由 MCP Server 完成。

**模式二：MCP 提供上下文，Skill 消费**

Skill 执行前需要最新的外部信息（如某个库的最新 API 文档），通过 MCP Resource 获取。

```markdown
<!-- SKILL.md 片段 -->
## 前置步骤

在生成代码之前，使用 context7 MCP 拉取目标库的最新文档：
1. 调用 `resolve-library-id` 确认库的 Context7 ID
2. 调用 `query-docs` 获取相关 API 文档
3. 基于获取的文档（而非训练数据）生成代码
```

**模式三：Skill 产出数据，MCP 分发**

Skill 生成内容后，通过多个 MCP Server 分发到不同平台。

```markdown
<!-- SKILL.md 片段 -->
## 分发步骤

内容生成完成后，按用户选择的渠道分发：
- [ ] Notion：调用 `notion_create_page` 写入知识库
- [ ] GitHub：调用 `create_issue` 创建 Issue
- [ ] Slack：调用 `send_message` 发送通知
```

### 9.2.3 在 SKILL.md 中引用 MCP Tool 的最佳实践

```markdown
<!-- 好的写法：声明依赖 + 降级策略 -->
## Dependencies

- MCP Server: `context7` (文档查询)
- MCP Server: `notion` (可选，用于输出到 Notion)

## Workflow

1. 如果 `context7` MCP 可用，使用 `query-docs` 获取最新文档
2. 如果不可用，使用训练数据中的知识（并提醒用户可能不是最新）
```

关键原则：**永远提供降级路径。** 不是所有用户都配置了你需要的 MCP Server。一个好的 Skill 在有 MCP 时更强，在没有 MCP 时仍然能用。

---

## 9.3 实战：用 context7 MCP 拉取最新文档写入 Skill

### 9.3.1 场景

你正在开发一个代码生成 Skill，需要确保生成的代码使用的是目标库的最新 API，而不是 AI 训练数据中可能过时的版本。

### 9.3.2 配置 context7 MCP

在 Claude Code 的 MCP 配置中添加 context7：

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

配置完成后，AI 助手在会话中就可以使用两个 Tool：

- `resolve-library-id`：搜索库名，返回 Context7 兼容的 Library ID
- `query-docs`：用 Library ID 查询特定主题的文档和代码示例

### 9.3.3 在 Skill 中使用

假设我们有一个 `codegen` Skill，需要为用户生成 Next.js 代码：

```markdown
---
name: codegen
description: 生成使用最新 API 的代码片段
---

# codegen Skill

## Workflow

### Step 1: 确认目标库

向用户确认要使用的库和版本。

### Step 2: 拉取最新文档

使用 context7 MCP 获取最新文档：

1. 调用 `resolve-library-id`，传入库名（如 "next.js"）
2. 从返回结果中选择匹配的 Library ID（如 `/vercel/next.js`）
3. 调用 `query-docs`，传入 Library ID 和用户的具体问题
4. 将返回的文档片段作为上下文注入后续代码生成

### Step 3: 生成代码

基于 Step 2 获取的文档，而非训练数据，生成代码。
在代码注释中标注文档来源和版本。

### 降级策略

如果 context7 MCP 不可用：
- 告知用户将基于训练数据生成代码
- 建议用户自行验证 API 是否为最新版本
```

### 9.3.4 效果对比

| | 无 MCP | 有 context7 MCP |
|---|---|---|
| API 时效性 | 取决于训练数据截止日期 | 实时获取最新文档 |
| 版本准确性 | 可能混淆不同版本的 API | 精确到指定版本 |
| 代码可用性 | 可能需要用户手动修复 | 大幅降低 API 变更导致的错误 |

---

## 9.4 实战：用 Notion MCP 将 Skill 输出写入 Notion 数据库

### 9.4.1 场景

你有一个 `research` Skill，它会搜索、整理资料并生成研究报告。你希望报告自动写入 Notion 数据库，方便团队协作和归档。

### 9.4.2 配置 Notion MCP

Notion 官方提供了 MCP Server。配置方式：

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer ntn_xxxx\", \"Notion-Version\": \"2022-06-28\"}"
      }
    }
  }
}
```

其中 `ntn_xxxx` 是你的 Notion Internal Integration Token，需要在 Notion 开发者后台创建。

### 9.4.3 Skill 中的 Notion 输出步骤

```markdown
## 输出到 Notion（可选）

如果用户要求将结果保存到 Notion：

1. 使用 `notion-search` 工具搜索目标数据库
2. 确认数据库 ID 和字段结构
3. 使用 `notion-create-page` 工具创建新页面：
   - Title：研究报告标题
   - Tags：从内容中提取的关键词
   - Status：Draft
   - Content：完整的研究报告（Markdown 格式）
4. 返回 Notion 页面链接给用户
```

### 9.4.4 完整流程图

```
用户输入研究主题
       │
       ▼
┌──────────────┐     context7 MCP
│  Skill 编排   │────────────────→ 拉取相关文档
│  (research)  │
│              │     web_search MCP
│              │────────────────→ 搜索最新资料
│              │
│  整理 & 生成  │
│  研究报告     │
│              │     Notion MCP
│              │────────────────→ 写入 Notion 数据库
└──────────────┘
       │
       ▼
  返回 Notion 链接
```

这个例子展示了一个 Skill 如何同时编排多个 MCP Server — context7 提供文档上下文，Web Search 提供最新信息，Notion 负责输出存储。**Skill 是指挥官，MCP Server 是各兵种。**

---

## 9.5 MCP Server 开发入门：为你的 Skill 生态构建专属 MCP

### 9.5.1 什么时候需要自建 MCP Server

公开 Registry 中已有 20,000+ Server，覆盖了大多数常见场景。但以下情况你需要自建：

- 连接内部系统（ERP、CRM、自建数据库）
- 封装复杂的业务逻辑（审批流程、数据转换管线）
- 提供团队专属的领域知识（产品文档、设计规范）
- 需要精细的权限控制和审计日志

### 9.5.2 用 Python SDK 构建 MCP Server

MCP 官方提供了 TypeScript 和 Python 两套 SDK。以 Python SDK 为例，构建一个为团队提供产品知识查询的 MCP Server：

```python
"""
product-kb MCP Server — 团队产品知识库查询服务

安装依赖：pip install mcp
运行：python product_kb_server.py
"""

from mcp.server.fastmcp import FastMCP

mcp = FastMCP(
    name="product-kb",
    description="团队产品知识库 MCP Server",
)


# ---- Tool: 搜索产品文档 ----

@mcp.tool()
def search_docs(query: str, product: str = "all") -> list[dict]:
    """搜索产品知识库文档。

    Args:
        query: 搜索关键词
        product: 产品名称过滤，默认搜索全部产品
    """
    # 实际实现中连接内部搜索引擎或数据库
    results = internal_search(query, product)
    return [
        {"title": r.title, "content": r.snippet, "url": r.url}
        for r in results
    ]


# ---- Tool: 获取产品变更日志 ----

@mcp.tool()
def get_changelog(product: str, since: str = "7d") -> list[dict]:
    """获取产品最近的变更日志。

    Args:
        product: 产品名称
        since: 时间范围，如 "7d"、"30d"、"2025-01-01"
    """
    entries = fetch_changelog(product, since)
    return [
        {"date": e.date, "version": e.version, "changes": e.summary}
        for e in entries
    ]


# ---- Resource: 产品配置（只读） ----

@mcp.resource("product://{product_name}/config")
def get_product_config(product_name: str) -> str:
    """获取指定产品的当前配置信息"""
    config = load_product_config(product_name)
    return config.to_json()


# ---- Prompt: 产品问答模板 ----

@mcp.prompt()
def product_qa(product: str, question: str) -> str:
    """生成产品问答的 Prompt 模板"""
    return (
        f"你是 {product} 的技术支持专家。"
        f"请根据产品知识库中的信息回答以下问题：\n\n{question}\n\n"
        f"如果知识库中没有相关信息，请明确说明。"
    )


if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="127.0.0.1", port=8000)
```

### 9.5.3 代码解析

这段代码展示了 MCP Server 的四个关键组成部分：

1. **`FastMCP` 实例**：Server 的入口。`name` 和 `description` 会出现在 Client 的 Server 列表中，帮助 AI 理解这个 Server 能做什么。

2. **`@mcp.tool()` 装饰器**：注册一个 Tool。Python 的类型注解和 docstring 会被自动转换为 JSON Schema，Client 据此展示参数说明和做输入校验。**好的 docstring 直接决定 AI 能否正确调用你的 Tool。**

3. **`@mcp.resource()` 装饰器**：注册一个只读 Resource。URI 模板中的 `{product_name}` 是动态参数。Resource 适合暴露配置、状态等不需要副作用的数据。

4. **`@mcp.prompt()` 装饰器**：注册一个 Prompt 模板。这是一个经常被忽视的原语 — 它让 Server 可以向 Client 提供"推荐的使用方式"。

### 9.5.4 TypeScript SDK 对照

如果你更熟悉 TypeScript，MCP 官方 TypeScript SDK 提供了几乎一致的开发体验：

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({
  name: "product-kb",
  version: "0.1.0",
});

server.tool(
  "search_docs",
  "搜索产品知识库文档",
  { query: z.string(), product: z.string().default("all") },
  async ({ query, product }) => {
    const results = await internalSearch(query, product);
    return {
      content: [{ type: "text", text: JSON.stringify(results) }],
    };
  }
);
```

### 9.5.5 部署方式

| 方式 | 适用场景 | 传输协议 |
|------|---------|---------|
| 本地进程 | 个人开发、测试 | Stdio |
| Docker 容器 | 团队内部 | Streamable HTTP |
| 云函数（Cloudflare Workers / Vercel） | 公开服务 | Streamable HTTP |
| npm/pip 包 | 社区分发 | Stdio（用户本地运行） |

对于团队内部使用的 MCP Server，Docker + Streamable HTTP 是最实用的方案。对于要分发给社区的 Server，打包成 npm/pip 包让用户通过 `npx` 或 `uvx` 本地运行是主流做法。

---

## 9.6 安全考量：MCP 权限模型与数据隔离

MCP 连接了 AI 与外部世界，安全性不是"最好有"而是"必须有"。2025-11 规范在安全方面做了大幅强化。

### 9.6.1 OAuth 2.1 授权框架

2025-11 规范引入了完整的 OAuth 2.1 授权框架，这是 MCP 走向生产环境的关键一步。

**Server 端授权发现**：MCP Server 通过 `/.well-known/oauth-authorization-server` 端点暴露授权服务器的元数据。Client 据此知道该去哪里获取访问令牌。

**Client 注册**：Client 可以提供一个 URL 指向自身的 JSON 描述文档（`client_uri`），Server 据此判断 Client 的身份和权限。这解决了 "谁在调用我" 的信任问题。

**两种授权模式**：

```
Authorization Code Flow（人机交互）：
用户 → Client → Authorization Server → 授权码 → Access Token

Client Credentials Flow（机器对机器）：
Client → Authorization Server → Access Token（无用户参与）
```

**企业 IdP 集成**：通过 Authorization Extension，企业可以强制所有 MCP Client 通过企业的 Identity Provider（如 Okta、Azure AD）进行认证。这让 IT 部门可以用统一的策略管控 AI 助手访问哪些外部服务。

### 9.6.2 Skill 开发者的安全清单

开发涉及 MCP 的 Skill 时，以下安全实践是底线：

**1. 最小权限原则**

```markdown
<!-- 好的做法：Skill 明确声明需要的权限范围 -->
## MCP 依赖

- `notion` MCP：仅需要 `read_content` 和 `insert_content` 权限
  - 不需要 `delete` 权限
  - 不需要访问 workspace 级别的设置
```

**2. 敏感数据不经过 AI**

```markdown
<!-- Workflow 中的安全指引 -->
## 安全要求

- 数据库连接凭据通过 MCP Server 的环境变量管理，不在对话中传递
- 查询结果中的个人信息（邮箱、手机号）必须脱敏后再返回
- 不要将 API Key 写入 Skill 的任何输出文件
```

**3. 操作确认机制**

```markdown
## 写入操作

在执行以下操作前，必须向用户确认：
- 向 Notion 创建页面
- 向 GitHub 创建 Issue / PR
- 向 Slack 发送消息
- 任何涉及删除或修改的操作

格式："即将向 [目标] 执行 [操作]，内容摘要如下：... 确认执行？"
```

**4. 降级与熔断**

```markdown
## 异常处理

- MCP Server 调用超时（> 30s）：告知用户并建议稍后重试
- MCP Server 返回错误：展示错误信息，不要静默吞掉
- 多次失败：建议用户检查 MCP Server 配置和网络连接
```

### 9.6.3 MCP Server 开发者的安全清单

如果你在自建 MCP Server，还需要注意：

**输入校验**：永远不要信任 Client 传入的参数。即使 JSON Schema 会在 Client 端做校验，Server 端必须再验一次。

**速率限制**：AI 助手可能在短时间内发起大量调用。为你的 MCP Server 设置合理的速率限制。

**审计日志**：记录每次 Tool 调用的时间、参数和结果。在出问题时，日志是唯一的真相来源。

**数据隔离**：多租户场景下，确保不同用户的数据互不可见。Token 中的 `sub`（subject）字段是隔离的依据。

```python
@mcp.tool()
def search_docs(query: str, ctx: Context) -> list[dict]:
    """搜索文档，结果按当前用户权限过滤"""
    user_id = ctx.request_context.get("user_id")
    if not user_id:
        raise ValueError("未获取到用户身份，拒绝查询")

    # 只返回该用户有权限访问的文档
    return search_with_acl(query, user_id)
```

### 9.6.4 安全反模式

以下做法在 MCP 集成中极其危险，必须避免：

| 反模式 | 风险 | 正确做法 |
|--------|------|---------|
| 在 SKILL.md 中硬编码 API Key | Key 泄露到版本控制和日志 | 使用 MCP Server 的 `env` 配置 |
| 让 AI 自由拼接 SQL 查询 | SQL 注入 | Server 端使用参数化查询 |
| MCP Server 返回全量数据由 AI 过滤 | 数据泄露、Token 浪费 | Server 端做权限过滤和分页 |
| 不校验 Client 身份就执行写入操作 | 未授权访问 | 启用 OAuth 2.1 授权 |
| 将 MCP Server 暴露在公网且无认证 | 被恶意调用 | 加认证 + 限制来源 IP / 域名 |

---

## 9.7 MCP 集成的未来展望

### 9.7.1 从"配置驱动"到"发现驱动"

当前的 MCP 集成需要用户手动配置每个 Server。随着 MCP Registry 的成熟和 AAIF 的标准化推进，未来的体验可能是：

```
用户：帮我查一下 Jira 里的 Sprint 进度

AI 助手：检测到你需要 Jira 集成。在 MCP Registry 中找到了
      官方 Jira MCP Server（认证：Atlassian 官方，评分：4.8/5）。
      需要我帮你安装并授权吗？
```

Skill 开发者可以在 `SKILL.md` 中声明"推荐的 MCP Server"，AI 助手自动从 Registry 拉取和配置。

### 9.7.2 MCP + Tasks = 长时间运行的 Skill

Tasks 原语的引入让 Skill 可以编排需要几分钟甚至几小时的工作流。例如一个 CI/CD 部署 Skill：

1. 触发部署（Task 状态：`working`）
2. 等待构建完成（轮询 Task 状态）
3. 构建失败时请求用户决策（Task 状态：`input_required`）
4. 部署完成后通知用户（Task 状态：`completed`）

这在之前是不可能的 — 同步的 Tool 调用无法处理这种时间跨度。

### 9.7.3 Skill 作为 MCP Server

一个有趣的趋势是：**Skill 本身也可以被封装为 MCP Server。** 你写了一个高质量的"代码审查 Skill"，为什么不把它作为 MCP Tool 暴露给其他 AI 助手？

这创造了一个递归的能力网络 — AI 助手通过 MCP 调用另一个 AI 助手的 Skill，形成 Agent 之间的协作。这正是 AAIF 愿景中 "Agentic AI" 的含义。

---

## 本章小结

| 要点 | 说明 |
|------|------|
| MCP 是什么 | AI 助手连接外部工具和数据的标准协议（JSON-RPC 2.0） |
| 三大原语 | Tool（执行操作）、Resource（读取数据）、Prompt（使用模板） |
| Skill + MCP | Skill 负责编排流程，MCP 负责连接外部能力 |
| 自建 MCP Server | Python/TypeScript SDK，装饰器模式定义 Tool/Resource/Prompt |
| 安全底线 | OAuth 2.1 授权、最小权限、输入校验、操作确认、审计日志 |
| 降级策略 | Skill 必须在 MCP 不可用时仍能工作 |

**核心原则：Skill 定义意图，MCP 提供能力。好的 Skill 在有 MCP 时如虎添翼，在没有 MCP 时仍能独立作战。**

下一章，我们将探讨 Skill 如何跨平台适配 — 同一个 Skill 如何在 Claude Code、Cursor、Copilot 等不同 AI 助手中都能工作。
