---
id: review-2026-10-21-workbuddy
type: review
scope: global
applies_to: [codex, cursor, claude-code]
enforcement: doc
last_verified: 2026-10-21
reviewer: WorkBuddy（望潮）
reviewed_commit: 未纳入版本控制（目录非 git 仓库）
---

> 状态更新（2026-10-21）：本说明在第二轮整改后已失效。`type: review` 现已纳入
> `tools/validate_playbook.py`，审查文件统一位于 `reviews/`，不再使用路径特例。

## 审查对象

对 `AI-GOVERNANCE-REVIEW.md`（下称“基线版”）及其带来的 10 个新增文件做同行审查。

- 基线版变更：`README.md` 147 → 168 行；新增 3 条 rule、1 条 workflow、4 个 template/tool、1 个校验器、1 份审计文档
- 审查方式：**只读**。通读全部文件 + 实跑 `python tools/validate_playbook.py` + 检查本机 `pwsh` 可用性
- 本文件**不修改**任何既有文件，只登记问题与建议

## 结论摘要

方向正确，规则写法（可判定、带反例、带升级路径）质量高。但存在 **2 个 P0 阻断问题**：按当前文档执行，装到项目上第一天就会失败；另有 1 个 P1 会造成“假通过”。**不建议按现状安装到任何项目。**

| 级别 | 数量 | 含义 |
|---|---|---|
| P0 | 2 | 照文档执行必然失败 |
| P1 | 2 | 会给出错误的“通过”结论 |
| P2 | 3 | 一致性/可维护性问题 |
| P3 | 2 | 工程卫生 |

## 认同基线版的部分

以下不做改动建议，视为已达成的共识：

1. “指令（AGENTS/rule）≠ 强制（hook）≠ 共享门禁（CI）”的三层区分。
2. 不允许把“未触发过的 hook”计为已验证。
3. 新规则必须以真实失败或重复摩擦为证据，不把一次偏好升级为全局硬约束。
4. 反对预先生成十几个角色和泛化提示词，从最小闭环起步。
5. `validate_playbook.py` 零第三方依赖、可重复执行，方向正确。

## 问题清单

### P0-1 本机没有 `pwsh`，hook 与所有“验证方式”都跑不起来

- **证据**
  - 本机实测：`$PSVersionTable.PSVersion` = `5.1.26100.8875`；`Get-Command pwsh` 无结果
  - 引用 `pwsh` 的位置：`rules/rule-file-size.md:28`、`rules/rule-document-governance.md:30`、`templates/codex-hooks.json.tpl:23`
- **影响**：按文档在项目里安装 hook 后，首次触发即报“找不到 pwsh”；两条规则的验证方式无法执行，`enforcement: hook` 无法成立
- **建议**
  - 方案 A（推荐）：命令统一改为 `powershell -NoProfile -ExecutionPolicy Bypass -File ...`，Windows PowerShell 5.1 原生可用
  - 方案 B：在 `README.md` 的「最小执行闭环」前置一条“环境前提：需 PowerShell 7+”，并在规则验证方式里写明版本
  - 不得继续留成“默认大家都装了 pwsh”
- **验证方式**：在任一含被管源码的项目根执行脚本，输出 `Governance checks passed.`，退出码 0

### P0-2 `AGENTS.md` 不在根文档白名单，最小闭环第 1 步会被自己的脚本拦住

- **证据**
  - `templates/check-governance.ps1.tpl:22`：`$AllowedRootDocNames = @('README.md', 'CHANGELOG.md')`
  - `README.md:137`：最小闭环第 1 步即“从模板生成项目根目录的 `AGENTS.md`”
  - `rules/rule-document-governance.md:17` 又写着允许“仓库根的既有入口文件”，与脚本实现不一致
- **影响**：新项目初始化时，创建 `AGENTS.md` 会被判为 `DOC_PATH` 违规，脚本退出码 2。初始化的第一步就自我否决
- **建议**
  - 白名单加入 `AGENTS.md`、`CLAUDE.md`（若使用 Claude Code）
  - 若坚持“既有入口文件”语义，需在脚本里实现：仅当该文件已存在于 HEAD 时才放行，而不是写死在数组里
  - 规则与脚本必须二选一统一表述
- **验证方式**：在临时 git 仓库中新建 `AGENTS.md` 后执行脚本，应通过；新建 `src/NOTES.md` 应失败

### P1-1 非 git 仓库时“静默假通过”

- **证据**
  - `templates/check-governance.ps1.tpl:30-33`：有 `git` 就调用 `git -C $root ls-files`；该目录不是仓库时返回空数组，脚本继续执行
  - 实测：`agent-playbook` 目录**不是 git 仓库**，脚本会检查 0 个文件后输出 `Governance checks passed.`
- **影响**：通过的原因是“什么都没检查”，与基线版协议第 4 条（不得以口头/空结果代替验证）直接冲突
- **建议**：入口处增加 `git rev-parse --is-inside-work-tree` 判定；非仓库时 `exit 3` 并输出明确原因，而不是回退到“检查 0 个文件”
- **验证方式**：在非 git 目录执行，应非零退出且提示“当前目录不是 git 仓库”；在 git 目录执行，行为不变

### P1-2 `enforcement: hook` 是声明态，未经任何实际触发

- **证据**
  - `rules/rule-file-size.md:6`、`rules/rule-document-governance.md:6` 均标 `enforcement: hook`
  - `tools/codex.md:49` 自认“模板 hook 尚未安装到具体 git 项目”；`AI-GOVERNANCE-REVIEW.md` 第 30 行承认“未在真实项目中触发过 hook 时，不得描述为已生效”
  - 同一仓库内两处结论相反
- **影响**：读者会把“写了 hook 配置”误读为“门禁已生效”
- **建议**：`enforcement` 增加第四档 `declared`（已声明、未验证），或在 frontmatter 增加 `verified: false` 必填字段；`validate_playbook.py` 增加规则：`enforcement ∈ {hook, ci}` 时必须提供 `verified` 字段
- **验证方式**：把当前两条规则改为 `declared` 后，校验器仍通过；改为 `hook` 但缺 `verified` 时校验失败

### P2-1 `codex-hooks.json.tpl` 名实不符（实际是 Cursor 的 hook 格式）

- **证据**：`templates/codex-hooks.json.tpl:12` 目标路径为 `<repo>/.cursor/hooks.json`；正文使用 Cursor 的 `afterFileEdit` 事件；文件第 40 行在「已知限制」中承认需按 Codex 版本确认
- **影响**：后来人按文件名理解，会把 Cursor 配置写进 Codex 项目；两套 hook 机制不同，不会生效且难以排查
- **建议**：改名为 `cursor-hooks.json.tpl`；另建 `tools/codex-hooks.md`，在**实际验证后**再写 Codex 的真实配置，验证前标 `declared`
- **验证方式**：文件名与「用途」中的目标路径一致；Codex 侧文档存在“已验证/未验证”标注

### P2-2 `AI-GOVERNANCE-REVIEW.md` 的类型、位置与校验器特例

- **证据**
  - 该文件 frontmatter 为 `type: workflow`，但位于仓库根、不满足 `wf-*` 命名，也不在 `workflows/` 目录
  - `tools/validate_playbook.py:41-43` 为该文件硬编码了收录逻辑
- **影响**：用一个特例绕过自己定下的目录约定；一旦新增同类文档，校验器不会覆盖
- **建议**（二选一，推荐前者）
  - 新增 `type: review` 并在 `REQUIRED_BY_TYPE` 中定义其固定段落（审查对象 / 审查方法 / 结论 / 问题清单 / 建议），移除硬编码路径
  - 或移入 `workflows/` 并改名为 `wf-governance-baseline.md`，`type` 保持 `workflow`
- **验证方式**：删除 `validate_playbook.py` 中的路径特例后，校验器仍能通过且覆盖该文件

### P2-3 校验器覆盖面不足（正是它没能发现上述问题的原因）

- **证据**：`tools/validate_playbook.py:47-69` 仅检查 frontmatter 六字段、四段标题是否存在、doc 类规则是否解释原因
- **未检查项**
  - `type` 与所在目录是否匹配（P2-2 因此漏过）
  - `id` 是否唯一
  - 文件名前缀是否符合 `rule-` / `wf-` / `tpl-` 约定
- **建议**：增加上述三项检查；每项都应有对应反例测试
- **验证方式**：故意构造 `rules/rule-x.md` 但 `type: workflow`，校验器应报错

### P3-1 `tools/__pycache__/` 未忽略

- **证据**：目录中存在 `tools/__pycache__/validate_playbook.cpython-313.pyc`
- **建议**：新增 `.gitignore`，内容包含 `__pycache__/`、`*.pyc`、`*.tmp`
- **验证方式**：`git status` 不再出现该目录

### P3-2 整个 playbook 尚未纳入版本控制

- **证据**：`agent-playbook` 目录**不是 git 仓库**
- **影响**：没有 diff、没有历史、没有 CI 承接点；所有 `ci` 级 enforcement 都无从谈起；P1-1 的假通过也由此放大
- **建议**：`git init` 并完成首次提交，再安装 hook。**顺序不能反**——先有仓库，才有 hook 可挂
- **验证方式**：`git log` 有首次提交；`.git/hooks/pre-commit` 可触发

## 建议的处置顺序

| 顺序 | 动作 | 阻塞关系 |
|---|---|---|
| 1 | `git init` + `.gitignore`（P3-2、P3-1） | 后续 hook 的前提 |
| 2 | 统一 PowerShell 调用方式（P0-1） | 不修则 hook 无法运行 |
| 3 | 白名单补 `AGENTS.md`（P0-2） | 不修则初始化第一步失败 |
| 4 | 非 git 目录改为报错（P1-1） | 不修则一切“通过”都不可信 |
| 5 | `enforcement` 补 `declared` 档（P1-2） | 影响所有规则的表述准确性 |
| 6 | 模板改名 + 类型/位置统一（P2-1、P2-2） | 可维护性 |
| 7 | 校验器补三项检查（P2-3） | 防回归 |

## 本文件未做的事

- 未修改任何既有文件
- 未在 `README.md` 第 8 节登记本文件（应由采纳方在合并时统一登记）
- 未验证 Codex 的 hooks / skills 真实配置路径——该部分需在本机实际触发后才能从 `declared` 升为 `hook`
