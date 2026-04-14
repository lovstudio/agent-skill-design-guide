# 第 3 章：开发环境搭建与第一个 Skill

![第一个 Skill — 工匠工作台上萌芽的种子](../assets/images/chapters/ch03-first-skill.png)


> **本章目标：** 从零配置 Claude Code Skills 开发环境，理解目录结构规范，亲手创建并运行第一个 Skill，掌握 dev.sh 热链接开发模式。最后，通过 `lovstudio:skill-creator` 案例体验"用 Skill 创建 Skill"的 meta 玩法。

前两章我们理解了 Skill 的本质和架构。现在，打开终端，动手写代码。

---

## 3.1 Claude Code Skills 开发环境配置

### 3.1.1 前置条件

开发 Skill 需要以下工具：

| 工具 | 最低版本 | 用途 |
|------|---------|------|
| Claude Code CLI | 最新 | 运行和加载 Skill |
| Python | 3.8+ | 编写脚本 Skill |
| Node.js | 18+ | 部分 Skill 依赖 |
| Git | 任意 | 版本管理 |

确认 Claude Code 已安装并可用：

```bash
claude --version
```

如果还没安装，参考官方文档：

```bash
npm install -g @anthropic-ai/claude-code
```

### 3.1.2 Skill 存储位置

Claude Code 从 `~/.claude/skills/` 目录加载 Skill。每个子目录就是一个 Skill，目录中必须包含 `SKILL.md` 文件：

```
~/.claude/skills/
├── my-first-skill/
│   └── SKILL.md
├── lovstudio-any2pdf/
│   ├── SKILL.md
│   ├── scripts/
│   └── references/
└── lovstudio-fill-form/
    ├── SKILL.md
    └── scripts/
```

Claude Code 启动新会话时，会扫描这个目录，将所有 `SKILL.md` 注册为可用 Skill。用户的指令匹配到 Skill 的 `description` 中的触发词时，Claude 会自动调用对应 Skill。

**关键认知：** Skill 的加载是会话级别的——修改了 `SKILL.md`，需要开启新的 Claude Code 会话才能生效。这一点对后面的开发流程有直接影响。

### 3.1.3 创建 Skill 仓库

实际项目中，你不会直接在 `~/.claude/skills/` 里开发。正确做法是创建独立的 Git 仓库，通过符号链接连接到 Skills 目录：

```bash
mkdir -p ~/projects/my-skills
cd ~/projects/my-skills
git init
mkdir skills
```

这样做的好处：
- 版本管理：所有改动有 Git 历史
- 多 Skill 管理：一个仓库管理多个 Skill
- 协作发布：推送到 GitHub 后，其他人可以安装

---

## 3.2 Skill 目录结构规范与命名约定

### 3.2.1 最小结构

一个 Skill 最少只需要一个文件：

```
my-skill/
└── SKILL.md
```

`SKILL.md` 既是 Skill 的定义文件（frontmatter 声明元数据），也是 Claude 的操作手册（正文部分的 workflow 指令）。这是 Skill 系统最优雅的设计——**一个文件，两个角色**。

### 3.2.2 完整结构

当 Skill 需要执行确定性操作（如文件格式转换、数据处理）时，需要脚本支持：

```
lovstudio-<name>/
├── SKILL.md          # 必须：Skill 定义 + AI 指令
├── README.md         # 推荐：人类可读的文档（发布到 GitHub 时必须）
├── scripts/          # 可选：Python/Shell 脚本
│   └── main.py
├── references/       # 可选：领域知识文档
│   └── style-guide.md
├── assets/           # 可选：模板、字体等资源
└── examples/         # 可选：示例文件
```

**每个目录的职责明确：**

- **`scripts/`** — 确定性操作，每次调用都会被 Claude 执行的代码
- **`references/`** — 领域知识，Claude 在决策时按需读取
- **`assets/`** — 静态资源，脚本运行时使用的模板和文件
- **`examples/`** — 输入/输出示例，帮助 Claude 理解预期结果

### 3.2.3 命名约定

如果你在开发个人或团队的 Skill 系列，建议采用统一前缀：

| 元素 | 约定 | 示例 |
|------|------|------|
| Skill 名称 | `<prefix>:<name>` | `lovstudio:any2pdf` |
| 目录名 | `<prefix>-<name>` | `lovstudio-any2pdf` |
| 脚本名 | 小写 + 下划线 | `md2pdf.py`、`fill_form.py` |
| 仓库结构 | 统一放在 `skills/` 下 | `skills/lovstudio-any2pdf/` |

前缀起到命名空间的作用，避免不同作者的 Skill 名称冲突。就像 npm 的 `@scope/package`，简单有效。

---

## 3.3 从零创建第一个 Skill：hello-world 完整流程

让我们抛开框架，手工创建一个最简单的 Skill，理解每一步的含义。

### 3.3.1 Step 1：创建目录和 SKILL.md

```bash
mkdir -p ~/projects/my-skills/skills/hello-world
```

创建 `skills/hello-world/SKILL.md`：

```markdown
---
name: hello-world
description: >
  A simple greeting skill for learning purposes.
  Trigger when the user says "hello", "greet me", or "say hi".
license: MIT
metadata:
  author: your-name
  version: "1.0.0"
  tags: hello greeting demo
---

# hello-world

A minimal skill that demonstrates the basic structure.

## Workflow

### Step 1: Greet the user

When triggered, respond with a personalized greeting that includes:
- The current date and time
- A random fun fact about programming

### Step 2: Ask for follow-up

Use `AskUserQuestion` to ask:
"Want to hear another fun fact? (yes/no)"

If yes, share another fact. If no, end the conversation.
```

这就是一个完整的 Skill。我们来解剖它。

### 3.3.2 SKILL.md 的两个部分

**Part 1 — Frontmatter（YAML 头部）**

```yaml
---
name: hello-world
description: >
  A simple greeting skill for learning purposes.
  Trigger when the user says "hello", "greet me", or "say hi".
license: MIT
metadata:
  author: your-name
  version: "1.0.0"
  tags: hello greeting demo
---
```

Frontmatter 是 Skill 的"身份证"。Claude Code 通过它来：

1. **识别 Skill**（`name`）
2. **判断何时触发**（`description` 中的关键词）
3. **显示元信息**（`version`、`author`、`tags`）

`description` 字段至关重要——它不仅是给人看的说明，更是 Claude 判断"要不要调用这个 Skill"的依据。写得太模糊，Claude 不知道什么时候该调用；写得太窄，又会漏掉本该触发的场景。这是第 5 章会深入讨论的主题。

**Part 2 — 正文（Markdown 指令）**

Frontmatter 下方的 Markdown 内容是 Claude 的操作手册。Claude 读到这些指令后，会按照 Workflow 中描述的步骤执行。这部分的写作质量直接决定了 Skill 的行为质量。

### 3.3.3 Step 2：安装到 Claude Code

将 Skill 链接到 Claude Code 的 Skills 目录：

```bash
ln -s ~/projects/my-skills/skills/hello-world ~/.claude/skills/hello-world
```

验证链接是否正确：

```bash
ls -la ~/.claude/skills/hello-world
# 应该看到指向源目录的符号链接
```

### 3.3.4 Step 3：测试

启动新的 Claude Code 会话：

```bash
claude
```

然后输入：

```
hello
```

如果一切配置正确，Claude 会按照 SKILL.md 中的 Workflow 执行：先给出带有日期和趣味事实的问候，然后用 `AskUserQuestion` 询问是否继续。

**常见问题排查：**

| 现象 | 原因 | 解决 |
|------|------|------|
| Skill 没被触发 | `description` 中没有匹配用户输入的关键词 | 在 description 中添加更多触发词 |
| 找不到 Skill | 符号链接指向错误路径 | `ls -la` 检查链接目标 |
| 修改后没生效 | 当前会话已加载旧版本 | 开启新的 Claude Code 会话 |

### 3.3.5 Step 4：添加脚本能力

纯指令型 Skill 的能力有限。当你需要执行确定性操作时（格式转换、文件处理、API 调用），需要添加脚本。

给 hello-world 加一个 Python 脚本：

```bash
mkdir -p ~/projects/my-skills/skills/hello-world/scripts
```

创建 `scripts/greet.py`：

```python
#!/usr/bin/env python3
"""Generate a greeting with a random programming fun fact."""

import argparse
import random
from datetime import datetime

FACTS = [
    "The first computer bug was an actual bug — a moth found in Harvard's Mark II in 1947.",
    "Python is named after Monty Python, not the snake.",
    "The first programmer was Ada Lovelace, who wrote algorithms for Babbage's Analytical Engine in 1843.",
    "Git was created by Linus Torvalds in just 2 weeks.",
    "The term 'refactoring' was popularized by Martin Fowler's 1999 book.",
]

def main():
    ap = argparse.ArgumentParser(description="Generate a greeting")
    ap.add_argument("--name", default="World", help="Name to greet")
    args = ap.parse_args()

    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    fact = random.choice(FACTS)

    print(f"Hello, {args.name}!")
    print(f"Current time: {now}")
    print(f"Fun fact: {fact}")

if __name__ == "__main__":
    main()
```

然后更新 `SKILL.md` 的 Workflow 部分，让 Claude 调用这个脚本：

```markdown
## Workflow

### Step 1: Get the user's name

Use `AskUserQuestion` to ask: "What's your name?"

### Step 2: Run the greeting script

```bash
python ~/.claude/skills/hello-world/scripts/greet.py --name "<user's name>"
```

### Step 3: Display the result

Show the script output to the user, then ask if they want another greeting.
```

注意脚本路径使用了 `~/.claude/skills/` 的绝对路径——因为 Claude Code 执行命令时的工作目录是用户的项目目录，不是 Skill 目录。这是新手常踩的坑。

**脚本设计原则：**

- 单文件、无依赖（或最少依赖），用 `argparse` 处理参数
- 通过 stdout 输出结果，通过 stderr 输出错误
- 退出码 0 表示成功，非 0 表示失败
- 不要依赖特定工作目录，所有路径用参数传入

---

## 3.4 dev.sh 热链接开发模式详解

手动 `ln -s` 管理一个 Skill 还行，管理十几个就要疯了。lovstudio-skills 仓库设计了一个 `dev.sh` 脚本来解决这个问题。

### 3.4.1 dev.sh 做了什么

```bash
bash dev.sh
```

这条命令做了三件事：

1. 扫描 `skills/` 目录下所有包含 `SKILL.md` 的 `lovstudio-*` 目录
2. 将每个 Skill 目录符号链接到 `~/.claude/skills/`
3. 进入等待状态，`Ctrl+C` 退出时自动恢复原状

也可以只链接单个 Skill：

```bash
bash dev.sh lovstudio-any2pdf
```

### 3.4.2 源码解读

`dev.sh` 只有 55 行，但设计精巧。来看核心逻辑：

**链接函数：**

```bash
link_skill() {
  local dir="$1"
  local name="$(basename "$dir")"
  local target="$SKILLS_DIR/$name"

  # 如果目标已存在且不是符号链接，先备份
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
  fi
  rm -f "$target"
  ln -s "$dir" "$target"
  LINKED+=("$name")
  echo "  ✓ $name → $dir"
}
```

关键细节：如果 `~/.claude/skills/` 中已经有同名的正式安装目录（不是符号链接），会先备份为 `.bak`，不会直接覆盖。这样开发完退出后，原来安装的版本会自动恢复。

**清理函数：**

```bash
cleanup() {
  for name in "${LINKED[@]}"; do
    local target="$SKILLS_DIR/$name"
    rm -f "$target"
    if [ -d "$target.bak" ]; then
      mv "$target.bak" "$target"
      echo "  Restored $name from backup."
    else
      echo "  Removed $name symlink."
    fi
  done
  echo "Dev mode OFF."
}
trap cleanup INT TERM
```

`trap` 捕获 `Ctrl+C`（INT 信号）和 TERM 信号，确保退出时自动清理。这是 Unix 哲学的体现——工具用完不留垃圾。

### 3.4.3 开发工作流

有了 `dev.sh`，日常开发流程变成：

```
终端 A                          终端 B
──────────                      ──────────
$ bash dev.sh                   $ claude
Dev mode ON:                    > /lovstudio:any2pdf
  ✓ lovstudio-any2pdf → ...     （Claude 加载 SKILL.md 并执行）
  ✓ lovstudio-fill-form → ...
                                （发现问题，修改 SKILL.md）
Edit source freely.
                                > /clear  （或开新会话）
                                > /lovstudio:any2pdf
                                （验证修改生效）

Ctrl+C
Dev mode OFF.
```

核心循环是：**改源码 → 开新会话 → 测试 → 改源码**。由于 Skill 加载是会话级的，每次改完都需要新会话。但因为是符号链接，不需要重新拷贝文件——源码改了，新会话立即读到最新版。

### 3.4.4 为你的项目写 dev.sh

`dev.sh` 的模式可以直接复用。如果你的 Skill 目录前缀不是 `lovstudio-`，只需改一行：

```bash
# 原来
for d in "$SOURCE_ROOT"/skills/lovstudio-*/; do

# 改成你的前缀
for d in "$SOURCE_ROOT"/skills/myteam-*/; do
```

或者更通用的版本——扫描所有包含 `SKILL.md` 的目录：

```bash
for d in "$SOURCE_ROOT"/skills/*/; do
  [ -f "$d/SKILL.md" ] && link_skill "$d"
done
```

---

## 3.5 案例：lovstudio:skill-creator — 用 Skill 创建 Skill

### 3.5.0 站在巨人的肩膀上

`lovstudio:skill-creator` 并非从零开始——它是 [Anthropic 官方 skill-creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) 的二次开发版本。

这引出了 Skill 开发中两个值得铭记的原则：

**原则一：优秀公司的官方实现是最好的教材。** Anthropic 的 skill-creator 只有几十行，但每一行都体现了他们对 SKILL.md 规范的深度理解。当你不知道一个 Skill 应该怎么写时，先去 [anthropics/skills](https://github.com/anthropics/skills) 仓库看官方是怎么做的——它们是 Anthropic 工程师用自己制定的规范写出来的，是最权威的参考实现。`lovstudio:skill-creator` 在官方版本基础上增加了 README 自动生成、仓库级文件更新、发布工作流等功能，但核心的 5 步创建流程和 frontmatter 模板设计，都继承自官方。

**原则二：自举（Bootstrapping）是 AI 时代的标志性特性。** 用 Skill 创建 Skill——这在传统软件开发中相当于用编译器编译自己。但在 AI 时代，自举变得自然而然：你只需要用自然语言说「帮我创建一个将 Markdown 转成 EPUB 的 Skill」，skill-creator 就会走完从需求分析到目录生成到代码填充的全流程。AI 读懂指令、生成代码、调用脚本、创建新的指令文件——**用自然语言生成自然语言驱动的自动化流程**，这在以前是无法想象的。

### 3.5.1 它解决什么问题

每次创建新 Skill 时，你需要：

1. 创建目录 `skills/lovstudio-<name>/`
2. 创建 `SKILL.md` 并填入 frontmatter 模板
3. 创建 `README.md` 用于 GitHub 展示
4. 创建 `scripts/` 目录
5. 更新根目录的 `README.md` 和 `CLAUDE.md` 的 Skills 列表

手动做？第一次可以，第三次就开始出错了——漏了 README、忘了更新列表、frontmatter 格式不对。官方 skill-creator 提供了基础骨架生成，`lovstudio:skill-creator` 在此基础上补全了 monorepo 场景下的自动化需求。

### 3.5.2 架构拆解

`skill-creator` 的文件结构：

```
skills/lovstudio-skill-creator/
├── SKILL.md                    # AI 指令：5 步创建流程
└── scripts/
    └── init_skill.py           # Python 脚本：生成目录和模板文件
```

它是一个"指令 + 脚本"混合型 Skill。SKILL.md 定义了完整的创建流程（5 步），其中 Step 3 调用 `init_skill.py` 生成初始文件结构。

### 3.5.3 init_skill.py 的设计

这个脚本做的事情很简单——接收一个名称参数，生成标准目录结构：

```python
def main():
    ap = argparse.ArgumentParser(description="Initialize a new lovstudio skill")
    ap.add_argument("name", help="Skill name (without lovstudio- prefix)")
    ap.add_argument("--path", default="", help="Custom base path")
    args = ap.parse_args()

    name = args.name.removeprefix("lovstudio-").removeprefix("lovstudio:")
    # ... 定位仓库根目录 ...

    skill_dir = base / f"lovstudio-{name}"
    skill_dir.mkdir(parents=True)
    (skill_dir / "scripts").mkdir()
    (skill_dir / "SKILL.md").write_text(SKILL_MD.format(name=name))
    (skill_dir / "README.md").write_text(README_MD.format(name=name))
```

脚本内嵌了 `SKILL.md` 和 `README.md` 的模板字符串，用 `{name}` 占位符填充。运行效果：

```bash
$ python init_skill.py fill-form

Created skill at /Users/you/projects/lovstudio-skills/skills/lovstudio-fill-form/
  SKILL.md    — edit frontmatter description + workflow
  README.md   — edit for GitHub readers
  scripts/    — add Python CLI scripts

Next steps:
  1. Implement scripts in scripts/
  2. Fill in TODO placeholders in SKILL.md and README.md
  3. Update root README.md and CLAUDE.md skills tables
  4. Test: bash dev.sh lovstudio-fill-form
```

生成的 `SKILL.md` 模板包含了所有必需的 frontmatter 字段和 Workflow 骨架，TODO 占位符明确标出需要填写的位置。

### 3.5.4 SKILL.md 中的创建流程

`skill-creator` 的 SKILL.md 定义了 5 步工作流：

| 步骤 | 动作 | 执行者 |
|------|------|--------|
| Step 1 | 理解 Skill 需求——问用户要做什么 | Claude（对话） |
| Step 2 | 规划内容——哪些是脚本、哪些是参考文档 | Claude（分析） |
| Step 3 | 运行 `init_skill.py` 生成骨架 | 脚本（确定性） |
| Step 4 | 填充 SKILL.md 和脚本实现 | Claude（生成代码） |
| Step 5 | 更新仓库级文件（README、CLAUDE.md） | Claude（编辑） |

这个流程体现了 Skill 设计的核心思想：**Claude 负责理解需求和生成内容，脚本负责执行确定性操作**。Step 1-2 是 Claude 的强项（理解、规划），Step 3 用脚本保证结构一致性，Step 4-5 又回到 Claude 的领域（代码生成、文件编辑）。

### 3.5.5 值得学习的设计决策

**1. 名称归一化**

```python
name = args.name.removeprefix("lovstudio-").removeprefix("lovstudio:")
```

无论用户传入 `fill-form`、`lovstudio-fill-form` 还是 `lovstudio:fill-form`，都能正确处理。防御性编程，减少用户犯错的可能。

**2. 智能定位仓库根目录**

```python
known = Path.home() / "projects" / "lovstudio-skills"
if (known / "skills").is_dir():
    base = known / "skills"
else:
    # 从 cwd 向上搜索
    for parent in [cwd] + list(cwd.parents):
        if (parent / "skills").is_dir() and (parent / "dev.sh").exists():
            repo_root = parent
            break
```

先检查已知路径，再从当前目录向上搜索。这种"先快后全"的策略在 CLI 工具中很常见。

**3. 模板内嵌而非外部文件**

模板字符串直接写在 Python 文件中，而不是放在单独的模板文件里。对于不到 100 行的模板，这是正确的选择——减少文件依赖，单文件即可运行。

**4. 防重复创建**

```python
if skill_dir.exists():
    print(f"ERROR: {skill_dir} already exists", file=sys.stderr)
    sys.exit(1)
```

如果目录已存在，直接报错退出，不会覆盖已有内容。简单粗暴，但安全。

### 3.5.6 实际使用体验

在 Claude Code 中输入：

```
帮我创建一个新 skill，用来将 Markdown 转成 EPUB
```

Claude 会识别到 `skill-creator` 的触发词（"创建skill"、"new skill"），然后启动 5 步流程：

1. 问你几个问题：输入输出是什么？需要什么依赖？
2. 分析后规划文件结构
3. 运行 `init_skill.py md2epub` 生成骨架
4. 根据你的回答填充 SKILL.md 和实现脚本
5. 自动更新 README.md 和 CLAUDE.md

整个过程 2-3 分钟，你得到一个结构完整、文档齐全、可以直接 `dev.sh` 测试的新 Skill。

---

## 本章小结

本章完成了从"理论理解"到"动手实践"的跨越：

1. **环境配置** — `~/.claude/skills/` 是 Skill 的安装目录，开发时用符号链接连接源码
2. **目录结构** — 最小只需 `SKILL.md`，完整结构包含 scripts、references、assets
3. **hello-world** — 从空目录到可运行的 Skill，理解了 frontmatter 和 workflow 的分工
4. **dev.sh** — 55 行的热链接脚本，解决了多 Skill 开发的日常痛点
5. **skill-creator** — 一个真实的 meta Skill，展示了"指令 + 脚本"的协作模式

现在你已经能创建和测试 Skill 了。但"能跑"和"好用"之间还有巨大的差距。下一章，我们将建立 Skill 质量模型——定义什么是"高质量"，以及如何系统性地衡量和提升它。
