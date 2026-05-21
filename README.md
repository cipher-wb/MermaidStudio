# Mermaid Studio

> 一个离线单文件的 Mermaid 图表工坊。双击 HTML 就能用。

把 Mermaid 代码粘进左边，图就在右边。完全离线、不依赖 CDN、不需要服务器，整个工具就是一个 3.3 MB 的 HTML 文件。

## 使用

下载 [`mermaid-studio.html`](./mermaid-studio.html)，双击在浏览器中打开即可。无需安装任何依赖。

## 功能

- **实时渲染** — 输入即出图，防抖 320 ms
- **12 种图表示例** — 流程图、序列图、类图、状态图、ER 图、甘特图、饼图、用户旅程、Git 图、思维导图、时间线、象限图
- **画布交互** — 滚轮缩放（以光标为中心）、拖拽平移、双击或 ⊙ 适应窗口、`Ctrl + +/-/0` 快捷键
- **导出** — PNG（2 倍高清，带背景）、SVG、复制图片到剪贴板
- **友好的错误提示** — 识别行号 + 给出修复建议
- **自动保存草稿** — 关闭页面也不丢
- **深浅主题切换** — 暖米 / 暖深棕
- **沉浸阅读模式** — 左侧代码区可完全折叠 (`Ctrl + B`)，全屏看图

## 设计

"Anthropic warm paper" 风格：

| | |
| --- | --- |
| 主色 | 米色 `#F5F4ED` 纸面 |
| 文字 | 深棕 `#2A2620` |
| 强调 | Anthropic 橙 `#D97757` |
| 字体 | 衬线（Source Serif） / 无衬线（Inter） / 等宽（JetBrains Mono）混排 |

整套设计语言通过 CSS 变量在 `template.html` 顶部集中管理，调色只改 `:root.theme-warm` 和 `:root.theme-dim` 两个选择器中的变量。

## 项目结构

| 文件 | 角色 |
| --- | --- |
| `template.html` | 唯一源文件，所有修改在这里做 |
| `mermaid.min.js` | 锁定版本 v10.9.1 的 mermaid 库（离线） |
| `mermaid-studio.html` | 把上面两个合成的最终产物（约 3.3 MB） |

修改 `template.html` 后，用以下 PowerShell 命令重新生成 `mermaid-studio.html`：

```powershell
$enc = New-Object System.Text.UTF8Encoding($false)
$tmpl = [System.IO.File]::ReadAllText('.\template.html', $enc)
$lib  = [System.IO.File]::ReadAllText('.\mermaid.min.js', $enc)
$final = $tmpl.Replace('/*__MERMAID_LIB_INJECTION_POINT__*/', $lib)
[System.IO.File]::WriteAllText('.\mermaid-studio.html', $final, $enc)
```

> 注意：必须用 `[System.IO.File]::WriteAllText` + `UTF8Encoding($false)`（不带 BOM）。`Out-File` / `Set-Content` 会写入带 BOM 的 UTF-8，导致部分浏览器把 BOM 显示成首字符。

详细开发说明见 [`CLAUDE.md`](./CLAUDE.md)。

## 致谢

- [Mermaid](https://github.com/mermaid-js/mermaid) — 真正画图的人
- 视觉灵感来自 Anthropic、Substack 等暖色出版物风格
