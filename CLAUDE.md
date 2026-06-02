# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

一个纯本地的单文件工具：粘贴 Mermaid 代码 → 渲染图。最终产物 `mermaid-studio.html` 通过双击在浏览器中以 `file://` 协议打开运行，完全离线，不依赖任何 CDN 或本地服务器。

## ⚠️ README 是给同事看的，改动要同步

`README.md` 是面向**使用者 / 同事**的文档（这个项目会分享出去给别人用）。`CLAUDE.md`（本文件）是给开发者 / Claude 看的内部说明，两者受众不同。

**规则：只要改动会影响使用者的体验或使用方式，必须同步更新 `README.md`。** 包括但不限于：

- 功能增删改（按钮、快捷键、导出格式、主题等）
- 使用步骤、构建命令、添加图表的流程变化
- 项目结构 / 文件角色变化
- 设计风格（配色、字体）调整

改完源码后顺手核对一遍 README 里对应的描述是否还对得上，对不上就改。不要让 README 与实际行为脱节——同事是照着 README 用的。

## 项目文件角色

| 路径 | 角色 | 改不改 |
| --- | --- | --- |
| `template.html` | 唯一前端源文件。含全部 HTML / CSS / JS + 两个占位符 | **所有 UI / 逻辑修改在这里做** |
| `mermaid.min.js` | jsdelivr 下载的 mermaid v10.9.1，离线 vendored | **保持原样**，不要重新下载或升级（v11+ 有破坏性 API 变更） |
| `fengshen-diagrams/*.mmd` | 业务图表，每个文件一张，扫描后注入到下拉菜单 | 用户随时增删改，提交 SVN |
| `build.ps1` | 唯一的构建入口，把上面三者合成最终产物 | 改这里的逻辑要小心，团队都依赖它 |
| `watch.ps1` | 可选 · 文件监听器，保存源文件后自动调用 `build.ps1`（防抖 400ms） | 用户自己开窗口跑，Claude 不主动启动它 |
| `mermaid-studio.html` | 自包含 3.3 MB+ 单文件成品（双击运行） | **永不直接编辑**，每次都从 build.ps1 重生成 |

## 工作流：改完任何上面的源就立刻重建

不要等用户提示。每次修改 `template.html` 或 `fengshen-diagrams/*.mmd` 之后，立即跑（在项目根目录）：

```powershell
.\build.ps1
```

> **不要写死绝对路径。** 这个项目会分享给同事、checkout 到各自机器上的不同目录。脚本全部用 `$PSScriptRoot` 自定位，文档和命令一律用相对路径（`.\build.ps1`）或 `$PSScriptRoot`，**任何文件里都不要出现 `F:\...` 这类本机绝对路径**。

`build.ps1` 内部做了三件事：
1. 读 `template.html`、`mermaid.min.js`、`fengshen-diagrams/*.mmd`
2. 把 mermaid 库注入到 `/*__MERMAID_LIB_INJECTION_POINT__*/`
3. 把所有 `.mmd` 文件打包成 `window.FENGSHEN_DIAGRAMS = [...]` JSON，注入到 `/*__FENGSHEN_DIAGRAMS_INJECTION_POINT__*/`
4. 用 `[System.IO.File]::WriteAllText` + `UTF8Encoding($false)` 写出 `mermaid-studio.html`（不带 BOM）

注意：

- `build.ps1` 用 `$PSScriptRoot` 自定位，可以在任何工作目录下调用（`.\build.ps1`，或从别处 `& '<本机路径>\build.ps1'`——本机路径只在临时命令里用，不要写进任何文件）。
- 两个占位符 `/*__MERMAID_LIB_INJECTION_POINT__*/` 与 `/*__FENGSHEN_DIAGRAMS_INJECTION_POINT__*/` 必须保留在 `template.html` 的 `<script>` 标签里，删掉就构建会报错。
- 占位符替换用 `String.Replace`（字面），不用正则——mermaid.min.js 里含有 `$`、反引号等字符，正则会误伤。
- `.mmd` 文件首行如果是 `%% title: 自定义名称`，会用这个名字作为下拉显示文案；否则用文件名（去 `.mmd` 后缀）。

## 团队同步（SVN）

仓库会上 SVN。任何人 checkout 后双击 `mermaid-studio.html` 直接可用（它是自包含的）。想加业务图表的人：

1. 在 `fengshen-diagrams/` 里加 `.mmd` 文件
2. 跑 `.\build.ps1`（在项目根目录）
3. `svn commit` 把 `.mmd` 文件 **和** 重新生成的 `mermaid-studio.html` 一起提交
4. 队友 `svn update` 后双击 HTML 就能看到新图表

**不要只提交 `.mmd` 不提交 `mermaid-studio.html`**——队友打开的是 HTML，HTML 才是带图表清单的那份。

## 路径里有中文

项目所在目录可能含中文字符（每台机器不同）。在 PowerShell / Bash 命令里始终用单引号包裹路径，并优先用相对路径（`'.\template.html'`）；需要绝对路径时用 `$PSScriptRoot` 拼，**不要把任何人的本机绝对路径写进文件**。

## 添加业务图表（fengshen-diagrams/）

下拉菜单"**载入封神图表**"的内容来自 `fengshen-diagrams/*.mmd`。在 file:// 协议下浏览器不能列目录、也不能 fetch 兄弟文件，所以这个清单是构建时静态嵌入的，**必须跑 `build.ps1` 才能让新加的图表出现在下拉里**。

## 设计系统在哪

整套视觉风格（"Anthropic warm paper"：米色 `#F5F4ED` + Anthropic 橙 `#D97757` + 衬线/无衬线/等宽混排）通过 CSS 变量统一控制，全部在 `template.html` 顶部 `<style>` 块里的 `:root.theme-warm` 和 `:root.theme-dim` 两个选择器中。**改色/改字号/改圆角统一改这里的变量，不要在样式表各处分散修改。**

mermaid 自身的图表配色在 JS 中的 `buildMermaidConfig()` 函数里（`themeVariables` 对象），分 warm 和 dim 两套；与上面的 CSS 变量需要同步调整。

## 不存在的东西

- 没有 package.json、没有测试、没有 CI、没有构建工具链。所有"构建"就是上面那一段 PowerShell。
- 仓库托管在 GitHub: https://github.com/cipher-wb/MermaidStudio
- 不要主动引入 npm / node / 任何打包器；离线单文件是硬约束。
