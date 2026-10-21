---
id: rule-file-size
type: rule
scope: global
applies_to: [codex, cursor, claude-code]
enforcement: hook
enforcement_status: template-only
last_verified: 2026-10-21
---

## 适用场景

当任务创建或修改受项目源码后缀清单约束的文件时适用。生成文件、锁文件、第三方代码和迁移快照应由项目显式排除。

## 规则

- 单个受管源码文件不得超过 800 个物理行。
- 文件达到 650 行时，新增独立职责前必须评估拆分；不得以无意义空行、压缩代码或重复导出规避限制。
- 超限修复必须按职责拆分，并保持公开 API 和测试可验证。

## 反例

```text
src/services/order.ts  912 行  ← 将 API、校验、持久化和格式化堆在同一文件中
```

## 验证方式

在目标 Git 项目执行 `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/check-governance.ps1`。脚本对配置的源码后缀逐文件计数；任一文件超过 `MAX_LINES` 时以非零退出。未安装 PowerShell 7 时，可将命令中的 `pwsh` 替换为 Windows 自带的 `powershell`。

## 升级路径

当前以编辑后 hook 阻止回归。将同一命令加入 CI，才能获得 `enforcement: ci`；不能在没有实际 CI 配置时宣称已升级。
