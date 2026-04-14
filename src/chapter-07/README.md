# 第 7 章：脚本设计 -- Skill 的「肌肉」

> "Talk is cheap. Show me the code." -- Linus Torvalds

前六章我们都在讨论 SKILL.md 里的「大脑」-- 如何用自然语言指令让 AI 助手理解意图、执行流程、处理异常。但总有些任务光靠文字描述是搞不定的：生成一份带封面和目录的 PDF、把 40 页 PDF 转成拼接的长图、填充 Word 模板里的表格字段。这些需要**精确的字节级操作**，需要调用第三方库的 API，需要在文件系统上做重活。

这就是脚本的用武之地。脚本是 Skill 的「肌肉」-- SKILL.md 发号施令，脚本干苦力活。

本章讨论何时需要脚本、如何设计脚本、以及三种主流脚本语言（Python / Shell / Node.js）在 Skill 场景下的最佳实践。所有案例均来自生产环境中经过大量迭代的真实 Skill。

---

## 7.1 何时需要脚本、何时纯指令足够

这是第一个要回答的问题。并非每个 Skill 都需要脚本。以我们仓库中的 Skill 为例：

| Skill | 有脚本? | 原因 |
|-------|---------|------|
| `auto-context` | 无 | 纯 prompt 技巧，AI 自身能力足够 |
| `thesis-polish` | 无 | 文本润色，AI 原生能力 |
| `visual-clone` | 无 | 分析截图提取设计 DNA，AI 视觉能力 |
| `any2pdf` | 有 (Python) | 生成带排版的 PDF，需要 reportlab |
| `pdf2png` | 有 (Shell+Python) | 调用 macOS CoreGraphics 渲染 PDF |
| `fill-form` | 有 (Python) | 操作 .docx XML 结构 |

**判断准则**：问自己三个问题。

**1. AI 能不能直接做？** 如果任务是「改写这段文字」「分析这张图的配色」「检查代码风格」，AI 本身就能做，不需要脚本。SKILL.md 里给好 prompt 就够了。

**2. 输出是不是二进制/结构化文件？** 生成 PDF、PPTX、DOCX、PNG -- 这些格式有严格的二进制结构，AI 不能直接「写出」一个合法的 PDF 文件。必须用脚本调用专门的库。

**3. 需不需要精确的数值控制？** 页面边距 25mm、字号 10.5pt、行距 17pt、水印倾斜 35 度 -- 这种精度要求超出了自然语言指令的能力范围。脚本用 argparse 暴露参数，SKILL.md 负责决定传什么值。

如果三个问题的答案是「不能 / 是 / 需要」，那就需要脚本。否则，保持纯指令，别增加复杂度。

> **实战经验**：我们仓库中 17 个 Skill 里有 8 个是纯指令的。不要低估 AI 的原生能力 -- `thesis-polish` 只靠 SKILL.md 里的 prompt 就能做到学术论文级别的中英文润色，加脚本反而画蛇添足。

---

## 7.2 脚本设计原则

当你决定需要脚本时，遵循以下原则。

### 原则一：单文件 CLI

每个脚本是一个**独立的、可以直接运行的 CLI 工具**。不要搞 Python package，不要搞 `setup.py`，不要搞 `__init__.py`。一个 `.py` 文件，放在 `scripts/` 目录下，`python scripts/xxx.py --input foo --output bar` 就能跑。

原因很简单：AI 助手执行脚本的方式是 `Bash("python /path/to/script.py --args")`。它不会帮你 `pip install -e .`，不会帮你激活 virtualenv，不会帮你配置 `PYTHONPATH`。单文件 CLI 是零配置的。

```
skills/lovstudio-any2pdf/
  SKILL.md
  scripts/
    md2pdf.py          # 1451 行，一个文件搞定所有事
```

是的，1451 行放在一个文件里。这在传统软件工程里是 code smell，但在 Skill 脚本的场景下是正确选择。原因：

- **部署零摩擦**：复制一个文件就能用
- **依赖透明**：文件头的 import 区就是完整的依赖清单
- **AI 友好**：AI 助手可以一次性读取整个脚本理解全貌

### 原则二：argparse 是标准接口

SKILL.md 和脚本之间的接口就是命令行参数。使用 `argparse` 定义清晰的 CLI 接口：

```python
def main():
    parser = argparse.ArgumentParser(
        description="md2pdf -- Markdown to Professional PDF"
    )
    parser.add_argument("--input", "-i", required=True,
                        help="Input markdown file")
    parser.add_argument("--output", "-o", default="output.pdf",
                        help="Output PDF path")
    parser.add_argument("--title", default="",
                        help="Cover page title")
    parser.add_argument("--theme", default="warm-academic",
                        help="Theme name")
    parser.add_argument("--cover", default=True,
                        type=lambda x: x.lower() != 'false',
                        help="Generate cover page")
    parser.add_argument("--toc", default=True,
                        type=lambda x: x.lower() != 'false',
                        help="Generate TOC")
    parser.add_argument("--watermark", default="",
                        help="Watermark text (empty = none)")
    parser.add_argument("--page-size", default="A4",
                        choices=["A4", "Letter"],
                        help="Page size")
    args = parser.parse_args()
```

几个要点：

**必填参数用 `required=True`**，可选参数给合理的默认值。AI 助手只需要传用户明确指定的参数，其余走默认值。

**布尔参数用 `lambda` 解析字符串**。`argparse` 的 `type=bool` 行为反直觉（`bool("false")` 是 `True`），用 `lambda x: x.lower() != 'false'` 才是正确姿势。

**用 `choices` 约束枚举值**。`--page-size` 只接受 `A4` 和 `Letter`，传错了 argparse 直接报错，不用你在代码里校验。

### 原则三：最小依赖

Skill 脚本的依赖应该尽可能少。理想情况是只有一个核心依赖：

| 任务 | 核心依赖 | 安装命令 |
|------|---------|---------|
| Markdown -> PDF | reportlab | `pip install reportlab` |
| 操作 Word 文档 | python-docx | `pip install python-docx` |
| PDF 转图片 (macOS) | pyobjc-framework-Quartz | `pip install pyobjc-framework-Quartz` |

不要引入 framework。不要用 Flask 来跑一个本地服务器。不要用 pandas 来解析一个 CSV。`import csv` 是标准库，够用了。

在 SKILL.md 的 frontmatter 里声明依赖，在脚本文件头的 docstring 里也写明安装命令：

```python
#!/usr/bin/env python3
"""
md2pdf -- Convert Markdown to professionally typeset PDF.

Dependencies:
  pip install reportlab --break-system-packages
"""
```

`--break-system-packages` 这个 flag 是 2023 年之后 Python（PEP 668）的现实。在 macOS / Linux 上直接 `pip install` 会被系统拒绝。要么用这个 flag，要么用 `pipx`，要么用 `uv`。作为 Skill 作者，在文档里直接给出能跑的命令，别让用户自己去摸索。

### 原则四：脚本头部声明一切

一个好的脚本头部应该像是一份完整的说明书：

```python
#!/usr/bin/env python3
"""
md2pdf -- Convert Markdown to professionally typeset PDF.

Features:
  - CJK/Latin mixed text with automatic font switching
  - Fenced code blocks with preserved indentation
  - Markdown tables with smart proportional column widths
  - Cover page, clickable TOC, PDF bookmarks, page numbers
  - Configurable color themes
  - Watermark support

Usage:
  python md2pdf.py --input report.md --output report.pdf \
    --title "My Report"

Dependencies:
  pip install reportlab --break-system-packages
"""

import re, os, sys, json, argparse
from datetime import date
from reportlab.lib.pagesizes import A4, LETTER
from reportlab.lib.units import mm
# ... 所有 import 集中在这里
```

AI 助手读到这个头部就知道：这个脚本做什么、怎么用、需要什么依赖。不需要翻到第 1400 行去看 argparse 的定义。

---

## 7.3 Python 脚本最佳实践

Python 是 Skill 脚本的首选语言，原因是：AI 助手对 Python 最熟悉、Python 的库生态最丰富、跨平台兼容性最好。以下是从实战中总结的最佳实践。

### 7.3.1 CJK/Latin 混排

如果你的 Skill 要处理中文（或日文、韩文），CJK 混排是绕不过去的坑。核心问题是：中文字符和英文字符需要使用不同的字体。英文用 Arial/Palatino，中文用宋体/黑体，而且两者经常混在一起出现。

`lovstudio:any2pdf` 的解决方案是字符级的字体切换：

```python
# CJK Unicode ranges for font switching
_CJK_RANGES = [
    (0x4E00, 0x9FFF),    # CJK Unified Ideographs
    (0x3400, 0x4DBF),    # CJK Extension A
    (0xF900, 0xFAFF),    # CJK Compatibility Ideographs
    (0x3000, 0x303F),    # CJK Symbols and Punctuation
    (0xFF00, 0xFFEF),    # Fullwidth Forms
    # ... 更多 range
]

def _is_cjk(ch):
    cp = ord(ch)
    return any(lo <= cp <= hi for lo, hi in _CJK_RANGES)
```

然后在渲染文本时，逐字符扫描，把连续的 CJK 字符和 Latin 字符分段，每段用对应字体渲染：

```python
def _font_wrap(text):
    """Wrap CJK runs in <font name='CJK'> tags for reportlab Paragraph."""
    out, buf, in_cjk = [], [], False
    for ch in text:
        c = _is_cjk(ch)
        if c != in_cjk and buf:
            seg = ''.join(buf)
            out.append(
                f"<font name='CJK'>{seg}</font>" if in_cjk else seg
            )
            buf = []
        buf.append(ch)
        in_cjk = c
    if buf:
        seg = ''.join(buf)
        out.append(
            f"<font name='CJK'>{seg}</font>" if in_cjk else seg
        )
    return ''.join(out)
```

这个函数的输入是普通文本，输出是带 `<font>` 标签的 reportlab 标记文本。reportlab 的 `Paragraph` 组件能理解这些标签，自动切换字体。

对于 canvas 级别的绘制（封面标题、页眉页脚），不能用 `Paragraph`，需要手动切换字体：

```python
def _draw_mixed(c, x, y, text, size, anchor="left", max_w=0):
    """Draw mixed CJK/Latin text on canvas with font switching."""
    segs, buf, in_cjk = [], [], False
    for ch in text:
        cj = _is_cjk(ch)
        if cj != in_cjk and buf:
            segs.append(("CJK" if in_cjk else "Sans", ''.join(buf)))
            buf = []
        buf.append(ch)
        in_cjk = cj
    if buf:
        segs.append(("CJK" if in_cjk else "Sans", ''.join(buf)))

    total_w = sum(c.stringWidth(t, f, size) for f, t in segs)
    if anchor == "right":   x -= total_w
    elif anchor == "center": x -= total_w / 2

    for font, txt in segs:
        c.setFont(font, size)
        c.drawString(x, y, txt)
        x += c.stringWidth(txt, font, size)
```

> **教训**：我们最初尝试用单一的 Unicode 字体（Arial Unicode MS）来解决 CJK 混排，结果英文字体很丑。后来改为双字体切换方案，英文用专业的衬线/无衬线字体，CJK 用宋体，效果好了一个量级。这 100 多行代码是整个 Skill 里最值得投入的部分。

### 7.3.2 跨平台字体发现

CJK 混排的下一个问题是：字体文件在哪？macOS、Linux、Windows 的字体路径完全不同。

`any2pdf` 的方案是**候选列表 + 首匹配**：

```python
_FONT_CANDIDATES = {
    "Sans": [
        # macOS
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        # Windows
        "C:/Windows/Fonts/arial.ttf",
        # Linux Debian
        "/usr/share/fonts/truetype/crosextra/Carlito-Regular.ttf",
        # Linux Noto
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        # Linux Fedora
        "/usr/share/fonts/noto/NotoSans-Regular.ttf",
    ],
    "CJK": [
        # macOS Songti SC
        ("/System/Library/Fonts/Supplemental/Songti.ttc", 0),
        # Windows SimSun
        "C:/Windows/Fonts/simsun.ttc",
        # Windows MSYH
        "C:/Windows/Fonts/msyh.ttc",
        # Linux Noto CJK
        "/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc",
        # ...
    ],
    # ... Serif, Mono, Bold variants
}

def _find_font(candidates):
    """Return first existing path from candidates list."""
    for c in candidates:
        path = c[0] if isinstance(c, tuple) else c
        if os.path.exists(path):
            return c
    return None
```

每种字体角色（Sans、Serif、Mono、CJK）定义一组候选路径，按优先级排列。`_find_font` 遍历候选列表，返回第一个存在的文件。

注意 `.ttc`（TrueType Collection）文件需要指定 subfontIndex：`("/System/Library/Fonts/Palatino.ttc", 0)` 表示取 Palatino.ttc 里的第一个子字体。

注册字体时统一处理两种格式：

```python
def register_fonts():
    missing = []
    for name, candidates in _FONT_CANDIDATES.items():
        spec = _find_font(candidates)
        if spec is None:
            missing.append(name)
            continue
        if isinstance(spec, tuple):
            pdfmetrics.registerFont(
                TTFont(name, spec[0], subfontIndex=spec[1])
            )
        else:
            pdfmetrics.registerFont(TTFont(name, spec))

    if missing:
        print(f"Warning: Missing fonts: {', '.join(missing)}",
              file=sys.stderr)
```

缺失字体不是致命错误 -- 打印 warning 继续运行，用户可能只处理英文文档。但要在 warning 里给出修复命令：

```python
if _PLAT == "Linux":
    print("  Fix: sudo apt install fonts-noto fonts-noto-cjk",
          file=sys.stderr)
```

### 7.3.3 主题系统

一个好的文档转换 Skill 应该支持多种视觉风格。`any2pdf` 用一个 Python dict 定义 14 种主题，每个主题包含颜色和排版参数：

```python
THEMES = {
    "warm-academic": {
        "canvas": "#F9F9F7",       # 页面背景
        "canvas_sec": "#F0EEE6",   # 次级背景（代码块等）
        "ink": "#181818",          # 正文颜色
        "ink_faded": "#87867F",    # 次级文字
        "accent": "#CC785C",       # 强调色
        "accent_light": "#D99A82", # 浅强调色
        "border": "#E8E6DC",       # 边框色
        "watermark_rgba": (0.82, 0.80, 0.76, 0.12),
        "layout": {
            "body_font": "Serif",
            "body_size": 10.5,
            "body_leading": 17,
            "heading_align": "center",
            "heading_decoration": "rules",
            "header_style": "full",
            "code_style": "bg",
            "cover_style": "centered",
            "page_decoration": "top-bar",
        }
    },
    "nord-frost": {
        "canvas": "#ECEFF4",
        "ink": "#2E3440",
        "accent": "#5E81AC",
        # ...
        "layout": {
            "body_font": "Sans",        # 无衬线
            "heading_align": "left",     # 左对齐标题
            "heading_decoration": "underline",
            "cover_style": "left-aligned",
            "page_decoration": "left-stripe",
        }
    },
    "tufte": {
        # ...
        "layout": {
            "margins": (30, 55, 25, 25),  # Tufte 风格：超宽右边距
            "body_font": "Serif",
            "body_size": 11,
            "heading_decoration": "none",
            "header_style": "none",
            "cover_style": "minimal",
            "page_decoration": "side-rule",
        }
    },
    # ... 共 14 个主题
}
```

设计要点：

**1. 颜色和排版分离**。`canvas`/`ink`/`accent` 是颜色，`layout` 是排版参数。同一种排版风格可以搭配不同的颜色方案。

**2. layout 使用默认值合并**。不是每个主题都要写全所有 layout 参数。定义一个 `_DEFAULT_LAYOUT`，然后主题只覆盖需要修改的值：

```python
_DEFAULT_LAYOUT = {
    "margins": (25, 22, 28, 25),
    "body_font": "Serif",
    "body_size": 10.5,
    "body_leading": 17,
    "h1_size": 26,
    "h2_size": 18,
    "h3_size": 12,
    "heading_align": "center",
    "heading_decoration": "rules",
    "header_style": "full",
    "code_style": "bg",
    "cover_style": "centered",
    "page_decoration": "none",
}
```

**3. 支持自定义主题文件**。用 `--theme-file custom.json` 可以加载用户自定义的主题 JSON。这样用户不需要修改脚本源码。

**4. 主题名是 CLI 参数**。`--theme warm-academic` 直接传字符串，SKILL.md 里根据用户的偏好或文档类型选择合适的主题。

### 7.3.4 文件 I/O 模式

Skill 脚本的 I/O 模式很固定：

```
读取输入文件 -> 处理 -> 写入输出文件
```

遵循以下约定：

```python
# 1. 输入输出都用参数指定
parser.add_argument("--input", "-i", required=True)
parser.add_argument("--output", "-o", default="output.pdf")

# 2. 读取文件时指定编码
with open(args.input, encoding='utf-8') as f:
    md_text = f.read()

# 3. 完成后打印输出信息
size = os.path.getsize(output_path)
print(f"Done! {output_path} ({size/1024/1024:.1f} MB)")
```

最后的 `print` 很重要 -- AI 助手需要知道脚本执行成功了，输出文件在哪。如果没有这行输出，AI 不知道操作是否成功。

### 7.3.5 错误处理策略

Skill 脚本的错误处理哲学是**快速失败，清晰报错**：

```python
# 检查输入文件存在
if not os.path.exists(args.input):
    print(f"Error: input file not found: {args.input}",
          file=sys.stderr)
    sys.exit(1)

# 检查依赖
try:
    from reportlab.lib.pagesizes import A4
except ImportError:
    print("Error: reportlab not installed. "
          "Run: pip install reportlab --break-system-packages",
          file=sys.stderr)
    sys.exit(1)
```

不要 `try/except` 整个 `main()`。让不可恢复的错误直接崩溃并打印 traceback -- AI 助手能读懂 Python traceback 并做出诊断。吞掉异常反而让 AI 迷失方向。

---

## 7.4 Shell 脚本最佳实践

有些场景下 Shell 脚本比 Python 更合适：调用系统命令、管道式处理、或者需要直接使用系统级 API。`lovstudio:pdf2png` 就是一个好案例。

### 7.4.1 案例分析：pdf2png.sh

这个脚本做一件事：把 PDF 的每一页渲染成图片，然后垂直拼接成一张长 PNG。

```bash
#!/bin/bash
# Convert PDF to vertically concatenated PNG
# (using macOS native CoreGraphics)
# Usage: pdf2png.sh file1.pdf [file2.pdf ...]

for f in "$@"; do
  [[ "$f" == *.pdf ]] || continue
  output="${f%.pdf}.png"
  /usr/bin/python3 - "$f" "$output" <<'PYEOF'
import sys
from Quartz import (
    CGPDFDocumentCreateWithURL,
    CGPDFDocumentGetNumberOfPages,
    CGPDFDocumentGetPage,
    CGPDFPageGetBoxRect, kCGPDFMediaBox,
    CGColorSpaceCreateDeviceRGB,
    CGBitmapContextCreate,
    kCGImageAlphaPremultipliedLast,
    CGContextDrawPDFPage,
    CGContextScaleCTM,
    CGBitmapContextCreateImage,
    CGContextDrawImage, CGRectMake
)
from CoreFoundation import (
    CFURLCreateWithFileSystemPath, kCFURLPOSIXPathStyle
)
from AppKit import NSBitmapImageRep, NSPNGFileType

url = CFURLCreateWithFileSystemPath(
    None, sys.argv[1], kCFURLPOSIXPathStyle, False
)
doc = CGPDFDocumentCreateWithURL(url)
n = CGPDFDocumentGetNumberOfPages(doc)
scale = 2.0  # 2x for Retina quality

# Render each page
images, total_h, max_w = [], 0, 0
for i in range(1, n + 1):
    page = CGPDFDocumentGetPage(doc, i)
    r = CGPDFPageGetBoxRect(page, kCGPDFMediaBox)
    w, h = int(r.size.width * scale), int(r.size.height * scale)
    cs = CGColorSpaceCreateDeviceRGB()
    ctx = CGBitmapContextCreate(
        None, w, h, 8, 4 * w, cs,
        kCGImageAlphaPremultipliedLast
    )
    CGContextScaleCTM(ctx, scale, scale)
    CGContextDrawPDFPage(ctx, page)
    images.append((CGBitmapContextCreateImage(ctx), w, h))
    total_h += h
    max_w = max(max_w, w)

# Stitch vertically
cs = CGColorSpaceCreateDeviceRGB()
ctx = CGBitmapContextCreate(
    None, max_w, total_h, 8, 4 * max_w, cs,
    kCGImageAlphaPremultipliedLast
)
y = total_h
for img, w, h in images:
    y -= h
    CGContextDrawImage(ctx, CGRectMake(0, y, w, h), img)

rep = NSBitmapImageRep.alloc().initWithCGImage_(
    CGBitmapContextCreateImage(ctx)
)
data = rep.representationUsingType_properties_(NSPNGFileType, None)
data.writeToFile_atomically_(sys.argv[2], True)
PYEOF
  echo "Created: $output"
done
```

这个脚本有几个值得学习的设计决策。

### 7.4.2 Heredoc 嵌入 Python

Shell 脚本的正文是一个 bash `for` 循环，但核心逻辑用 Python heredoc 嵌入。为什么？

- **Shell 擅长**：遍历命令行参数（`"$@"`）、文件名处理（`${f%.pdf}.png`）、输出反馈（`echo`）
- **Python 擅长**：调用 CoreGraphics API、位图操作、复杂的坐标计算

用 heredoc（`<<'PYEOF'`）嵌入 Python 代码，单引号阻止 Shell 变量展开，`sys.argv` 接收参数。这是一种在单文件里融合两种语言优势的实用技巧。

### 7.4.3 使用系统 Python

注意脚本用的是 `/usr/bin/python3` 而不是 `python3`。这是有意为之 -- macOS 的系统 Python 自带 `pyobjc` 绑定（Quartz、CoreFoundation、AppKit），不需要额外安装。如果用 Homebrew 的 Python，这些绑定不存在，反而需要 `pip install pyobjc-framework-Quartz`。

教训：**了解你的运行环境**。macOS 上系统 Python 有独特的优势；Linux 上 `/usr/bin/python3` 可能缺少很多包。脚本要根据目标平台选择正确的 Python。

### 7.4.4 Shell 脚本的防御性编程

生产级 Shell 脚本应该加上以下防护：

```bash
#!/bin/bash
set -euo pipefail  # 严格模式

# 依赖检测
command -v python3 >/dev/null 2>&1 || {
    echo "Error: python3 not found" >&2; exit 1;
}

# 参数校验
if [[ $# -eq 0 ]]; then
    echo "Usage: pdf2png.sh file1.pdf [file2.pdf ...]" >&2
    exit 1
fi

# 文件存在性检查
for f in "$@"; do
    [[ -f "$f" ]] || {
        echo "Warning: $f not found, skipping" >&2; continue;
    }
    [[ "$f" == *.pdf ]] || continue
    # ... 处理
done
```

`set -euo pipefail` 三件套：`-e` 任何命令失败立即退出；`-u` 使用未定义变量报错；`-o pipefail` 管道中任何一步失败都报错。这避免了 Shell 脚本「静默失败」的经典陷阱。

### 7.4.5 何时选 Shell vs Python

| 场景 | 选 Shell | 选 Python |
|------|---------|----------|
| 调用系统命令管道 | `ffmpeg \| sox \| lame` | - |
| 批量文件处理 | `for f in *.pdf` | - |
| 复杂数据结构 | - | dict, list, class |
| 二进制文件操作 | - | struct, bytes |
| 需要跨平台 | - | `platform.system()` |
| 10 行以内 | Shell | - |
| 100 行以上 | - | Python |

经验法则：**如果你在 Shell 脚本里写超过 3 个 `if` 语句，换 Python**。

---

## 7.5 Node.js 脚本：前端相关 Skill 的选择

有些 Skill 涉及前端技术栈：生成 PPTX、操作 SVG、渲染 HTML。这时 Node.js 可能是更好的选择。

`lovstudio:any2deck` 就用了 Node.js 来生成 PowerPoint：

```javascript
// 使用 pptxgenjs 库
const pptxgen = require("pptxgenjs");

// 每张幻灯片对应 markdown 的一个 ## 标题
sections.forEach(section => {
    const slide = pres.addSlide();
    slide.addText(section.title, {
        x: 0.5, y: 0.3, w: 9, h: 1,
        fontSize: 28, bold: true,
        color: theme.accent
    });
    // ...
});

pres.writeFile({ fileName: outputPath });
```

Node.js 的优势场景：

1. **PPTX 生成**：`pptxgenjs` 是目前最成熟的幻灯片生成库，没有同等水平的 Python 替代品（`python-pptx` 功能弱很多）
2. **PDF 操作**：`pdf-lib` 可以合并、拆分、加水印，且是纯 JavaScript，无系统依赖
3. **SVG 处理**：Node 生态的 SVG 工具比 Python 丰富
4. **与前端复用**：如果 Skill 涉及生成 HTML 预览，Node 是天然选择

但 Node.js 的劣势也很明显：

- **`node_modules` 地狱**：Python 的 `pip install reportlab` 装一个包就完事，Node 的 `npm install pptxgenjs` 会拖入一棵依赖树
- **AI 助手熟悉度**：大多数 AI 助手对 Python 的理解比 Node 更深
- **启动速度**：对于简单任务，`python script.py` 比 `node script.js` 快（不需要解析 `node_modules`）

**实用建议**：除非目标库只有 Node 版本（如 `pptxgenjs`），否则首选 Python。如果必须用 Node，把 `package.json` 和脚本放在同一个 `scripts/` 目录下，让 AI 助手能 `cd scripts && npm install && node generate.js` 一条龙。

---

## 7.6 案例对比：reportlab 方案 vs pandoc 方案

同一个需求 -- Markdown 转 PDF -- 我们有两种实现。这个对比能帮助你理解「自己造轮子」和「调用成熟工具」的取舍。

### 方案 A：lovstudio:any2pdf（reportlab，Python 原生渲染）

**架构**：Python 脚本直接使用 reportlab 库，在代码里逐元素构建 PDF 页面。

```
Markdown -> 自研 parser -> reportlab Flowables -> PDF
```

**优势**：
- 像素级控制：封面、页眉、水印、主题颜色、字体大小，全部可编程
- CJK 混排：自己实现字符级字体切换，完美控制
- 零外部工具：只需要 `pip install reportlab`，不需要 LaTeX 发行版
- 单文件部署：1451 行 Python，复制即用
- 14 种主题：每种主题不只是换颜色，而是整套排版风格

**劣势**：
- 开发成本高：1451 行代码是大量迭代的结果
- Markdown 解析不完整：自研 parser 只支持常用语法，复杂嵌套可能有 bug
- 表格排版受限：reportlab 的表格自动布局不如 LaTeX 智能

**代码量**：~1450 行 Python

### 方案 B：lovstudio:md2pdf（pandoc + XeLaTeX）

**架构**：用 pandoc 做 Markdown -> LaTeX 转换，用 XeLaTeX 做 LaTeX -> PDF 渲染。

```
Markdown -> pandoc -> LaTeX -> XeLaTeX -> PDF
```

**优势**：
- 排版质量：LaTeX 的排版算法是学术出版的黄金标准
- 表格处理：LaTeX 的表格自动分页、列宽计算远超 reportlab
- Markdown 兼容性：pandoc 支持几乎所有 Markdown 扩展语法
- 代码量少：Shell 脚本包装 pandoc 命令，核心逻辑很短

**劣势**：
- 重依赖：需要 pandoc + BasicTeX/TeX Live，安装包几百 MB
- 环境配置复杂：`tlmgr install` 各种 LaTeX 包，CJK 字体配置容易出错
- 可控性差：想自定义封面样式？写 LaTeX 模板，学习曲线陡峭
- 平台差异：macOS 用 BasicTeX，Linux 用 TeX Live，行为不完全一致

**代码量**：~80 行 Shell + LaTeX 模板

### 如何选择

```
你需要精确的像素级视觉控制?
  ├─ 是 -> reportlab 方案 (any2pdf)
  └─ 否
      你需要学术级排版质量?
        ├─ 是 -> pandoc + LaTeX 方案 (md2pdf)
        └─ 否
            你的用户环境能装 LaTeX?
              ├─ 是 -> pandoc 方案 (更省力)
              └─ 否 -> reportlab 方案 (依赖更轻)
```

实际上我们在生产环境中两个都保留了。`any2pdf` 是默认方案（依赖轻、可控性强），`md2pdf` 作为 fallback（表格处理更好）。SKILL.md 里根据文档内容选择：有复杂表格就用 pandoc，需要品牌化封面就用 reportlab。

> **核心洞察**：Skill 脚本不需要做到完美，需要做到**在特定场景下足够好**。`any2pdf` 的表格排版不如 LaTeX，但它的封面和主题系统远超 pandoc 方案。两个方案互补，比一个「什么都做」的方案更实用。

---

## 7.7 脚本与 SKILL.md 的协作模式

脚本写好了，怎么和 SKILL.md 配合？

### 模式一：SKILL.md 组装命令行

最常见的模式。SKILL.md 告诉 AI 助手根据用户需求组装 CLI 命令：

```markdown
## 执行步骤

1. 根据用户需求确定参数
2. 运行命令：
   ```bash
   python {{SKILL_DIR}}/scripts/md2pdf.py \
     --input <用户的文件> \
     --output <输出路径> \
     --title "<文档标题>" \
     --theme <选定主题> \
     --watermark "<水印文字>"
   ```
3. 检查输出，向用户报告
```

AI 助手的角色是「翻译官」-- 把用户的自然语言需求翻译成精确的命令行参数。

### 模式二：SKILL.md 做决策，脚本做执行

更复杂的模式。SKILL.md 包含决策逻辑（选主题、选方案、处理异常），脚本只负责执行：

```markdown
## 主题选择逻辑

- 学术论文 / 技术报告 -> `warm-academic` 或 `classic-thesis`
- 商务 PPT 配套 PDF -> `github-light` 或 `nord-frost`
- 中文党政公文 -> `chinese-red`
- 极简风格 -> `tufte`
- 用户指定 -> 直接使用

## 方案选择

- 文档包含超过 3 个复杂表格 -> 使用 pandoc 方案
- 需要品牌化封面 -> 使用 reportlab 方案
- 默认 -> reportlab 方案
```

这种分工让 SKILL.md 和脚本各做自己擅长的事：SKILL.md 做模糊的、需要理解上下文的决策；脚本做精确的、确定性的执行。

### 模式三：多脚本编排

一个 Skill 调用多个脚本，形成 pipeline：

```
1. 分析输入 (Python)
2. 生成图片 (image-gen Skill)
3. 组装幻灯片 (Node.js pptxgenjs)
4. 导出 PDF (pdf-lib)
```

`lovstudio:any2deck` 就是这种模式。SKILL.md 是总指挥，按步骤调用不同的工具。每个工具的输出是下一个工具的输入。

---

## 7.8 本章小结

脚本是 Skill 的「肌肉」，但不是每个 Skill 都需要肌肉。判断准则简单明了：AI 做不了的事才需要脚本。

设计脚本时，记住四个原则：

1. **单文件 CLI**：一个 `.py` / `.sh` / `.js` 文件搞定，不搞 package
2. **argparse 接口**：命令行参数是 SKILL.md 和脚本的唯一合约
3. **最小依赖**：一个核心库解决核心问题，其余用标准库
4. **头部声明一切**：功能、用法、依赖，读前 20 行就够

语言选择：

- **Python**：默认选择，适合大多数场景
- **Shell**：系统命令调用、10 行以内的胶水代码
- **Node.js**：前端相关库只有 JS 版本时的选择

方案选择的本质不是「哪个更好」，而是「在你的场景下哪个足够好」。`reportlab` 给你像素级控制但开发成本高，`pandoc` 给你学术级排版但依赖重。两者互补优于二选一。

下一章我们讨论 Skill 的测试与发布 -- 写好的脚本如何验证、如何交付给用户。
