---
id: rule-document-governance
type: rule
scope: global
applies_to: [codex, cursor, claude-code]
enforcement: hook
enforcement_status: template-only
last_verified: 2026-10-21
---

## 适用场景

当 AI 创建新的 `.md`、`.mdx` 或项目定义的文档文件时适用；用户明确要求的交付文档也适用，但仍需放入允许目录或获得显式豁免。

## 规则

- 仅在用户明确要求、接口/架构/运行方式发生实质变化，或现有文档已失实时新建或修改文档。
- 新建文档必须位于项目声明的允许目录，默认是 `docs/prd/`、`docs/plan/`、`docs/adr/` 或仓库根的既有入口文件。
- 文档必须说明 owner、目的和更新触发条件；不得创建无 owner 的日报、复盘或重复 README。
- 需要目录外文档时，先在计划中说明目标路径、原因和保留期限，再由人批准。

## 反例

```text
src/auth/NOTES.md               ← 在源码目录临时记笔记
docs/implementation-summary.md  ← 未请求、无 owner、与 README 重复
```

## 验证方式

在目标 Git 项目执行 `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/check-governance.ps1`。脚本检查本次新增 Markdown 的路径是否在 `ALLOWED_DOC_PREFIXES` 内；允许 `README.md`、`CHANGELOG.md`、`AGENTS.md` 与 `CLAUDE.md` 等根入口文件。规则的“是否必要”仍需依靠工作流中的人工审查，原因是意图不能由路径检查充分判定。

## 升级路径

将脚本接入 pull request CI，并要求 PR 描述列出新文档 owner 和理由；通过后可将 enforcement 提升为 `ci`。
