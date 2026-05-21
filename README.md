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

| 路径 | 角色 |
| --- | --- |
| `template.html` | 唯一前端源文件，所有 UI / 逻辑修改在这里做 |
| `mermaid.min.js` | 锁定版本 v10.9.1 的 mermaid 库（离线） |
| `fengshen-diagrams/*.mmd` | 业务图表，每个文件一张，构建时自动汇入下拉菜单 |
| `build.ps1` | 把上面三类源打包成 `mermaid-studio.html` 的构建脚本 |
| `mermaid-studio.html` | 最终产物（约 3.3 MB），双击即用 |

修改任何源（`template.html` 或 `fengshen-diagrams/*.mmd`）之后，回到项目根目录运行：

```powershell
.\build.ps1
```

`build.ps1` 用 `$PSScriptRoot` 自定位，**SVN / git checkout 到任何路径都能运行**，不依赖固定目录。

## 添加业务图表

下拉菜单"**载入封神图表**"的内容来自 [`fengshen-diagrams/`](./fengshen-diagrams) 文件夹。

```text
1. 在 fengshen-diagrams/ 新建一个 .mmd 文件     战斗循环.mmd
2. (可选) 首行写自定义显示名                    %% title: 战斗循环 · 主流程
3. 接下来写 Mermaid 代码                        graph TD ...
4. 在项目根运行 build.ps1                       .\build.ps1
5. 双击 mermaid-studio.html，下拉里已经有了
```

详见 [`fengshen-diagrams/README.md`](./fengshen-diagrams/README.md)。

> **为什么需要 build 步骤？** 浏览器在 `file://` 协议下不能列目录、也不能 fetch 兄弟文件（CORS 安全限制）。所以图表清单是构建时**静态嵌入**到 HTML 里的。这换来的好处是：最终 HTML 完全自包含，团队同事拿到 HTML 双击就能看到所有图表，不需要额外文件夹。

详细开发说明见 [`CLAUDE.md`](./CLAUDE.md)。

## 致谢

- [Mermaid](https://github.com/mermaid-js/mermaid) — 真正画图的人
- 视觉灵感来自 Anthropic、Substack 等暖色出版物风格
