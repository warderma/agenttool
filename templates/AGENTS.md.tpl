---
id: tpl-agents-md
type: template
scope: global
applies_to: [codex, cursor, claude-code]
enforcement: doc
last_verified: 2026-10-21
---

## 用途

- 目标路径：`<repo>/AGENTS.md`
- 依赖规则：`rules/rule-file-size.md`、`rules/rule-document-governance.md`、`rules/rule-change-evidence.md`

## 正文

```markdown
# 〈项目名〉 agent instructions

## 项目事实
- 主要语言/框架：〈例如 TypeScript / FastAPI〉
- 源码目录：〈例如 src, apps, packages〉
- 测试命令：`〈实际命令〉`
- 类型检查命令：`〈实际命令；没有则写 N/A〉`
- lint 命令：`〈实际命令；没有则写 N/A〉`

## 修改前
- 先只读检查关联实现、测试、配置与本目录指令。
- 说明将修改的文件、原因、验证办法和未解决假设。
- 不清楚需求、验收条件或风险边界时，先提问；不得自行扩展功能。

## 代码约束
- 受管源码文件不得超过 800 行；达到 650 行时优先按职责拆分。
- 保持现有命名、错误处理和模块边界；不做无关重构或批量格式化。
- 注释只说明意图、约束、权衡或非显然原因，不复述代码。

## 文档约束
- 仅在用户明确要求，或接口、架构、运行方式发生实质变化时创建/更新文档。
- 新文档只允许放在：〈例如 docs/prd, docs/plan, docs/adr〉。
- 目录外文档和无明确 owner 的文档必须先获批准。

## 子 agent
- 只委派可独立验证的调研、测试设计或审查；默认只读。
- 多 agent 不得修改重叠文件。委派结果必须包含证据、风险和未验证项。
- 主 agent 负责整合、最终修改和所有验证。

## 完成门禁
- 依次运行：格式化、lint、类型检查、测试，以及 `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/check-governance.ps1`（若已安装）。
- 最终报告必须列出改动文件、实际执行的命令和结果、未运行项及原因、已知风险。
- 不提交、推送、部署、访问生产系统或创建外部资源，除非用户明确要求。
```

## 使用说明

1. 复制代码块到目标项目根目录的 `AGENTS.md`。
2. 替换所有 `〈 〉` 占位符；没有命令时写 `N/A`，不要虚构。
3. 只保留能被该项目实际执行的门禁；再安装同目录的 hooks 模板。

## 已知限制

`AGENTS.md` 是指令层，不是强制执行层；文件大小和文档路径必须由 hook 或 CI 复核。
