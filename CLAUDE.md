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

## AI 助手子系统（自然语言生成图表）

顶部「✦ AI 助手」按钮在右侧展开对话面板，用户用自然语言描述，调用其自配的大模型生成 Mermaid 代码，**自动填入代码区并渲染**。全部逻辑在 `template.html` 的 IIFE 内、`// AI 助手` 分隔块（紧挨 `bootstrap()` 之前），复用了现成的 `codeEl.value=...; saveDraft(); updateGutter(); autoFitOnNextRender=true; scheduleRender();` 渲染链路，以及 `toast()` / `safeGet` / `safeSet` / `STORAGE`。

- **同层面板，不是悬浮抽屉。** 最初做成 `position:fixed` 滑出抽屉 + `.ai-scrim` 模糊遮罩，用户反馈"遮住后面看不清"，已改为**同层并排面板**：`<div class="stage">` 用 flex 容纳 `.workspace`（`flex:1`）+ `.ai-resizer` + `.ai-panel`（折叠时 `flex:0 0 0`，展开时 `flex-basis: var(--ai-panel-w)`，由 `.stage.ai-open` 切换）。展开/收起切 `stageEl` 的 `ai-open` 类，宽度可拖 `.ai-resizer` 调整（`width = stageRect.right - clientX`，钳在 280–720px 且 ≤70% 舞台宽），开合状态 + 宽度存 `STORAGE.AI_PANEL`。每次开合/拖动后 `refitSoon()` 重新 `fitToView`。**唯一还保留遮罩模糊的是模型设置弹窗 `.ai-modal-scrim`——那是真·模态对话框，符合预期，别去掉。** 移动端（≤900px）`.stage` 改纵向堆叠，面板变成底部一行，拖动条隐藏。

要点：

- **没有 .env，也不可能有。** `file://` 下浏览器读不到兄弟文件（和封神图表同样的限制）。最初需求提的 `.env` 方案行不通，改为**网页内设置弹窗 + localStorage**。配置存 `STORAGE.AI_CONFIG`，对话历史存 `STORAGE.AI_CHAT`。Key 只在本机浏览器，**绝不写文件、不进 `mermaid-studio.html`**——分享 HTML 不会泄露 Key。
- **两种接口协议**：`openai`（`POST {baseURL}/chat/completions`，`Authorization: Bearer`）和 `claude`（`POST {baseURL}/messages`，头带 `x-api-key` + `anthropic-version` + `anthropic-dangerous-direct-browser-access: true`）。预设 `AI_PRESETS` 里 DeepSeek / OpenAI / 通义千问走 openai，Claude 走 claude。
- **流式**：`readSSE()` 统一解析 `data:` 行；非流式（content-type 不是 event-stream）回退到整包 JSON。
- **CORS 是硬伤**：`file://` 直连云端 API 受跨域限制，部分服务商会被浏览器拦截（不是 bug）。`corsHint()` 在失败时给出提示。README 里有详细说明和绕过方案（本地模型 / 代理 / 扩展）。
- **生成结果强校验 + 自动修复**：模型有时会输出 PlantUML（`@startuml`/`start`/`:动作;`/`if-then-else-endif`/`note right:`）而非 Mermaid，导致 "No diagram type detected"。对策两层：①`AI_SYSTEM_PROMPT` 里加了大段硬性约束（禁 PlantUML、列出合法首行声明、给出"用户说什么→用哪种 Mermaid 图"映射）；②运行时 `validateMermaid()` 先用 `window.mermaid.parse()`（外加 `PLANTUML_MARKERS` 正则做高置信度拦截以生成更清晰的报错）校验，不过就走 `validateAndApply()` 把报错回传模型自动修复，最多 `MAX_REPAIR`(2) 次。**只有校验通过的代码才 `applyMermaidToCanvas`**；修不好则保留原图不覆盖。修复轮**在同一个 assistant 气泡里原地重写**（不要新开气泡——否则历史里出现连续 assistant 消息，Claude API 严格交替会 400）。改这块逻辑后注意保持 user/assistant 交替。
- **改了 AI 逻辑同样要 `.\build.ps1` 重建**，并核对 README 的「AI 助手」章节是否还对得上。

## 设计系统在哪

整套视觉风格（"Anthropic warm paper"：米色 `#F5F4ED` + Anthropic 橙 `#D97757` + 衬线/无衬线/等宽混排）通过 CSS 变量统一控制，全部在 `template.html` 顶部 `<style>` 块里的 `:root.theme-warm` 和 `:root.theme-dim` 两个选择器中。**改色/改字号/改圆角统一改这里的变量，不要在样式表各处分散修改。**

mermaid 自身的图表配色在 JS 中的 `buildMermaidConfig()` 函数里（`themeVariables` 对象），分 warm 和 dim 两套；与上面的 CSS 变量需要同步调整。

## 不存在的东西

- 没有 package.json、没有测试、没有 CI、没有构建工具链。所有"构建"就是上面那一段 PowerShell。
- 仓库托管在 GitHub: https://github.com/cipher-wb/MermaidStudio
- 不要主动引入 npm / node / 任何打包器；离线单文件是硬约束。
