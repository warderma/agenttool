---
id: tool-codex
type: tool
scope: tool
applies_to: [codex]
enforcement: doc
last_verified: 2026-10-21
---

## 这个工具在链路里的位置

Codex 负责读取项目约束、执行代码变更、运行验证，并在适合时将独立工作委派给子 agent；它不应成为未验证结论的唯一来源。

## 配置位置

| 作用 | 路径 |
|---|---|
| 项目持久规则 | `<repo>/AGENTS.md` |
| 目录级覆盖规则 | `<repo>/<subdir>/AGENTS.md` |
| 项目可复用 skill | `<repo>/.codex/skills/<skill>/SKILL.md` |
| 用户可复用 skill | `~/.codex/skills/<skill>/SKILL.md` |
| 确定性质量检查 | 项目脚本与 CI；本 playbook 提供 `.codex/hooks/` 模板 |
| 生命周期 hooks | Codex Desktop 的受信任插件 hooks，或按当前版本 Hooks 设置配置 |

## 规则怎么落地

| rules/ 里的规则 | 在本工具上怎么写 | 生效强度 |
|---|---|---|
| `rule-file-size` | `AGENTS.md` 提示 + `check-governance.ps1` + CI | template-only hook；接入 CI 后为 ci |
| `rule-document-governance` | `AGENTS.md` 目录白名单 + diff 路径检查 + 人工 gate | template-only hook + doc |
| `rule-change-evidence` | `AGENTS.md` 的完成报告格式 + PR/任务模板 | doc，结构化检查后可升 ci |
| `wf-change-delivery` | 主 chat 作为编排者；只读子 agent 做调研/审查 | doc |

## 子 agent 使用约定

- 委派请求必须写明目标、允许范围、输入路径、是否允许写入、预期证据格式。
- 调研和审查 agent 默认只读；实现 agent 只拥有明确、不重叠的文件集。
- 主 agent 在合并结论前必须自己检查 diff 和验证输出，不能盲信子 agent 摘要。

## 这个工具做不到的事

- 单靠 `AGENTS.md` 不能可靠阻止违规写入；必须使用 hook/CI。
- hooks 能否在本机执行取决于用户信任和运行环境；不能把未触发的 hook 计为验证。
- 子 agent 的独立审查提高覆盖率，但不能代替测试、类型检查或人工风险决定。

## 已验证 / 未验证

- ✅ 已验证：本目录 `tools/validate_playbook.py` 可检查治理文档结构；`.codex/hooks/check-governance.ps1` 已在本仓库手动验证通过和拦截两种结果。
- ⚠️ 未验证：本仓库的 Codex hook 尚待在 Codex Hooks 页面审阅信任并触发，因此尚未声称它已自动运行。
- ❌ 已知不可用：没有项目 CI 配置时，无法宣称本地 hook 是不可绕过的门禁。

## 官方文档

- https://developers.openai.com/cookbook/examples/codex/iterating-development-workflows-with-codex
- https://developers.openai.com/plugins/build/plugins
- https://developers.openai.com/plugins/build/skills
