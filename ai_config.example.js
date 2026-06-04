/* ============================================================================
 * 团队默认 AI 接口配置模板（Mermaid 图表工坊 · AI 助手）
 * ----------------------------------------------------------------------------
 * 用法：把本文件【复制】为同目录下的  ai_config.js  ，填好 Key 即可。
 *      mermaid-studio.html 启动时会自动读取 ai_config.js，同事打开零配置直接用。
 *      （改完源码后跑 .\build.ps1，外置 ai_config.js 不参与构建、无需重建。）
 *
 * 安全：
 *   • ai_config.js 已写进 .gitignore（git）/ svn:ignore（svn）—— 不会进仓库、
 *     不会随分享出去的 mermaid-studio.html 外泄。
 *   • 真正的 Key 只放在 ai_config.js（你本机这一份），绝不要写进 template.html /
 *     mermaid-studio.html / 本 .example —— 那些文件会进仓库、会被分享。
 *   • 写进 ai_config.js 的 Key 是明文，凡是拿到这个文件的人都能用、花费都算这把
 *     Key，请只用「团队内部可共享」的 Key，别用个人付费私钥。
 *   • 不想共享？不创建 ai_config.js 即可，AI 助手会回退为「每人在 ⚙ 设置里各填各的」。
 *   • 个人优先：谁在设置弹窗里填过自己的配置，就以个人的为准，本文件只当兜底默认。
 *
 * protocol：Claude 用 'claude'；DeepSeek / OpenAI / 通义千问 等用 'openai'。
 * ========================================================================== */
window.AI_TEAM_DEFAULTS = {
  provider: 'deepseek',                       // 'deepseek' | 'openai' | 'claude' | 'qwen' | 'custom'
  protocol: 'openai',                         // 'openai' 或 'claude'
  baseURL : 'https://api.deepseek.com/v1',    // 接口地址 Base URL
  model   : 'deepseek-chat',                  // 模型名
  apiKey  : ''                                // ←★ 把团队共享 Key 粘到这里（留空 = 每人各填）
};
