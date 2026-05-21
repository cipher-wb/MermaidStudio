# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

一个纯本地的单文件工具：粘贴 Mermaid 代码 → 渲染图。最终产物 `mermaid-studio.html` 通过双击在浏览器中以 `file://` 协议打开运行，完全离线，不依赖任何 CDN 或本地服务器。

## 三个文件的角色

| 文件 | 角色 | 改不改 |
| --- | --- | --- |
| `template.html` | 唯一源文件。包含全部 HTML / CSS / JS，以及占位符 `/*__MERMAID_LIB_INJECTION_POINT__*/` |  **所有修改在这里做** |
| `mermaid.min.js` | 从 jsdelivr 下载的 mermaid v10.9.1，本地保留 | **保持原样，不要重新下载或升级**（v11+ 有破坏性 API 变更） |
| `mermaid-studio.html` | 把上面两个文件注入合成的最终产物，约 3.3 MB | **永不直接编辑**，只通过下方的重建命令重新生成 |

## 工作流：改完 template.html 自动重建

每次修改 `template.html` 后，立刻执行以下 PowerShell 命令重新生成 `mermaid-studio.html`，不要等用户提示：

```powershell
$enc = New-Object System.Text.UTF8Encoding($false)
$tmpl = [System.IO.File]::ReadAllText('F:\AI\mermaid解析\template.html', $enc)
$lib  = [System.IO.File]::ReadAllText('F:\AI\mermaid解析\mermaid.min.js', $enc)
$final = $tmpl.Replace('/*__MERMAID_LIB_INJECTION_POINT__*/', $lib)
[System.IO.File]::WriteAllText('F:\AI\mermaid解析\mermaid-studio.html', $final, $enc)
```

注意点：

- **必须用 `[System.IO.File]::WriteAllText` + `UTF8Encoding($false)`**。`Out-File` / `Set-Content` 默认写入 UTF-8 with BOM，会污染 HTML 并让某些浏览器把 BOM 当作首字符显示在页面顶部。
- 占位符 `/*__MERMAID_LIB_INJECTION_POINT__*/` 必须保留在 `template.html` 中（位于 `<script>` 标签内的注释里），它是注入锚点。
- 用 `String.Replace`（不是正则替换）。mermaid.min.js 含有 `$`、反引号等字符，正则会误伤。

## 路径里有中文

工作目录是 `F:\AI\mermaid解析`，含中文字符。在 PowerShell / Bash 命令里始终用单引号包裹路径（`'F:\AI\mermaid解析\template.html'`）。

## 设计系统在哪

整套视觉风格（"Anthropic warm paper"：米色 `#F5F4ED` + Anthropic 橙 `#D97757` + 衬线/无衬线/等宽混排）通过 CSS 变量统一控制，全部在 `template.html` 顶部 `<style>` 块里的 `:root.theme-warm` 和 `:root.theme-dim` 两个选择器中。**改色/改字号/改圆角统一改这里的变量，不要在样式表各处分散修改。**

mermaid 自身的图表配色在 JS 中的 `buildMermaidConfig()` 函数里（`themeVariables` 对象），分 warm 和 dim 两套；与上面的 CSS 变量需要同步调整。

## 不存在的东西

- 没有 package.json、没有测试、没有 CI、没有构建工具链。所有"构建"就是上面那一段 PowerShell。
- 仓库托管在 GitHub: https://github.com/cipher-wb/MermaidStudio
- 不要主动引入 npm / node / 任何打包器；离线单文件是硬约束。
