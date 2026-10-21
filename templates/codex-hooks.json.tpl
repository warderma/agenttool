---
id: tpl-codex-hooks-json
type: template
scope: global
applies_to: [codex]
enforcement: hook
enforcement_status: template-only
last_verified: 2026-10-21
---

## 用途

- 目标路径：`<repo>/.codex/hooks.json`
- 依赖规则：`rules/rule-file-size.md`、`rules/rule-document-governance.md`

## 正文

```json
{
  "description": "Run repository governance checks after Codex file edits.",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "apply_patch|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -Command \"$root = git rev-parse --show-toplevel; & (Join-Path $root '.codex/hooks/check-governance.ps1') -HookMode\"",
            "commandWindows": "powershell -NoProfile -ExecutionPolicy Bypass -Command \"$root = git rev-parse --show-toplevel; & (Join-Path $root '.codex/hooks/check-governance.ps1') -HookMode\"",
            "timeout": 20,
            "statusMessage": "Checking repository governance"
          }
        ]
      }
    ]
  }
}
```

## 使用说明

1. 将 JSON 代码块保存到目标路径；复制 `check-governance.ps1.tpl` 为 `.codex/hooks/check-governance.ps1`。
2. 根据项目修改脚本中的源码后缀和允许文档目录。
3. 在 Codex 中打开 Hooks 页面，审阅并信任该项目 hook；新建临时超限文件或目录外 Markdown，确认 hook 停止后续执行并报告问题；验证完再删除测试文件。

## 已知限制

这是 Codex 的项目 hook 结构。`PostToolUse` 在编辑之后运行，因此它能停止后续 agent 执行、报告违规，但不能撤销已经写入的文件；必须接入 CI 才能阻止绕过本地 hook 的提交。
