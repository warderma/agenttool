---
id: review-2026-10-21-workbuddy-round2
type: review
scope: global
applies_to: [codex, cursor, claude-code]
enforcement: doc
last_verified: 2026-10-21
reviewer: WorkBuddy（望潮）
reviewed_commit: 仓库已 git init，但尚无任何提交，全部文件为 untracked
---

## 审查对象

对 `reviews/review-2026-10-21-workbuddy.md`（下称“第一轮”）所列 9 个问题的**整改结果**做二次复核，并检查本轮新安装的运行产物。

- 整改产物：`.codex/hooks.json`（19 行）、`.codex/hooks/check-governance.ps1`（58 行）、`.gitignore`、`reviews/` 目录化、`tools/validate_playbook.py` 83 → 112 行、`templates/check-governance.ps1.tpl` 79 → 95 行、`templates/codex-hooks.json.tpl` 40 → 48 行
- 审查方式：**只读** + 实跑校验器与治理脚本 + 读 `openai/codex` 官方仓库源码核实 Codex hooks 契约（文档站 `developers.openai.com` 返回 403，故以源码为准）
- 本文件**不修改**任何既有文件，只登记问题与建议

## 结论摘要

整改质量高：第一轮 9 个问题中 **7 个已真正修复**，其中 `commandWindows`、`.codex/hooks.json` 两个关键点经官方源码证实**完全正确**（第一轮怀疑的“名实不符”已不成立）。`enforcement_status` 老实标 `template-only`、没有夸大为 `verified`，符合基线版第 2 条协议。

但本轮发现 **1 个 P0：hook 装在了正确位置、schema 全对，却永远不会被触发**——`matcher` 写的是 Codex 里不存在的工具名。这意味着两条 `enforcement: hook` 的规则仍然只是纸面规则，且比第一轮更隐蔽（第一轮是“没装”，现在是“装了但不响”）。

| 级别 | 数量 | 含义 |
|---|---|---|
| P0 | 1 | 装了但不触发，治理链路实际断裂 |
| P1 | 1 | 覆盖范围缺口，最该被校验的产物裸奔 |
| P2 | 2 | 语义退化 / 实例与模板漂移 |
| P3 | 3 | 死代码、空档位、陈旧注释 |

**结论：在 P0-A 修复并实测触发一次之前，不得把任何规则标为 `verified`，也不建议把本套模板装到真实项目上作为唯一门禁。**

## 实跑证据

全部在 `D:\APP\AI\agent-playbook` 下执行：

```
$ python tools/validate_playbook.py
Playbook validation passed (7 artifacts checked).          exit=0

$ powershell -NoProfile -ExecutionPolicy Bypass -File .codex\hooks\check-governance.ps1
Governance checks passed.                                   exit=0

$ powershell -NoProfile -ExecutionPolicy Bypass -File .codex\hooks\check-governance.ps1 -HookMode
{"systemMessage":"Governance checks passed.","continue":true}   exit=0
```

环境事实（用于判断上面这些“通过”的可信度）：

```
codex-cli 0.163.0
$ codex features list  →  hooks   stable   true
Windows PowerShell 5.1.26100.8875（pwsh 仍未安装）
```

## 已核实的 Codex hooks 契约

以下不是推测，均来自 `openai/codex` 仓库源码（本机无法访问文档站，改用源码）：

| 事实 | 源码位置 |
|---|---|
| 项目级 hooks 文件确实是 `<repo>/.codex/hooks.json` | `codex-rs/hooks/src/engine/discovery.rs`：`config_folder.join("hooks.json")`，`ConfigLayerSource::Project { dot_codex_folder }` |
| 事件键为 PascalCase（`PostToolUse` 等 14 个） | `codex-rs/config/src/hook_config.rs`：`HookEventsToml` 逐个 `#[serde(rename = "PostToolUse")]` |
| 顶层只允许 `description` + `hooks`，其余字段报错 | 同文件：`HooksFile` 带 `#[serde(deny_unknown_fields)]` |
| handler 用 `type` 打标签 | 同文件：`#[serde(tag = "type")] enum HookHandlerConfig`，变体 `command` / `mcp_tool` / `prompt` / `agent` |
| `timeout` 就是正确字段名（映射到内部 `timeout_sec`） | 同文件：`#[serde(default, rename = "timeout")] timeout_sec` |
| `commandWindows` 是真实字段，Windows 上优先于 `command` | `discovery.rs`：`if cfg!(windows) { command_windows.unwrap_or(command) }` |
| `matcher` 在纯字母/`_`/`|` 时按**精确相等**比较，不做正则 | `codex-rs/hooks/src/engine/matcher.rs`：`Exact` 分支 `pattern.split('|').any(|c| c == input)` |
| Codex 规范工具名含 `Bash` 与 `apply_patch` | `codex-rs/core/src/hook_runtime.rs:233`：`tool_name.name() == "Bash" || tool_name.name() == "apply_patch"` |

第一轮把 `templates/codex-hooks.json.tpl` 判为“名实不符（实为 Cursor 格式）”——**该结论在本轮被推翻**：改成 `.codex/hooks.json` 后，路径、事件名、字段名全部与源码一致。这是本轮唯一需要撤回的第一轮结论。

## 第一轮问题对账

| 编号 | 问题 | 状态 | 本轮证据 |
|---|---|---|---|
| P0-1 | 本机无 `pwsh`，hook 跑不起来 | 已修复 | 新增 `commandWindows`，源码确认 Windows 优先取它 |
| P0-2 | `AGENTS.md` 不在根文档白名单 | 已修复 | 实例与模板均含 `AGENTS.md`、`CLAUDE.md` |
| P1-1 | 非 git 目录静默假通过 | 已修复 | 改为 `GIT_REQUIRED` → `exit 3`；HookMode 返回 `continue:false` |
| P1-2 | `enforcement: hook` 从未触发 | **未修复** | 见 P0-A：仍然是“从未触发”，且原因更隐蔽 |
| P2-1 | hooks 模板名实不符 | 已修复 | `.codex/hooks.json` 是真路径，见上表 |
| P2-2 | 校验器为 `AI-GOVERNANCE-REVIEW.md` 硬编码特例 | 已修复 | 特例代码已删除，`reviews/` 成为一等类型 |
| P2-3 | 校验器不查 type↔目录 / 前缀 / id 唯一 | 已修复 | 新增 `EXPECTED_TYPE`、`FILENAME_PREFIX`、`seen_ids` |
| P3-1 | `__pycache__` 未忽略 | 已修复 | `.gitignore` 已含 3 条规则 |
| P3-2 | 未纳入版本控制 | 部分修复 | 已 `git init`，但**0 次提交**，见 P2-B |

## 问题清单

### P0-A `matcher` 用了 Codex 中不存在的工具名，hook 永不触发

- **证据**
  - `.codex/hooks.json:6`：`"matcher": "Edit|Write"`
  - `templates/codex-hooks.json.tpl:24`：同一处
  - `matcher.rs` 的 `Exact` 语义要求 **完全相等**；`hook_runtime.rs:233` 表明 Codex 的编辑工具规范名是 `apply_patch`、shell 是 `Bash`
  - 在本机 `codex.exe` 中检索 JSON 字面量 `Edit"`：0 处；说明不存在名为 `Edit` / `Write` 的工具或别名
- **影响**：`PostToolUse` 分组永远匹配不到任何工具调用。`rule-file-size`、`rule-document-governance` 两条 `enforcement: hook` 规则实际强度退化为 `doc`，而文档仍宣称有脚本兜底。这是比第一轮“没装 hook”更危险的状态：**没人会再去查它为什么不响**
- **建议**：`"matcher": "apply_patch"`；若还想覆盖 shell 产生的文件变更，用 `"apply_patch|Bash"`
- **验证方式**：把 hook 命令临时改为写 marker（如 `Add-Content -Path $env:TEMP\hook-fired.txt`），在 Codex 中让 agent 改任意一个文件，marker 文件出现即证明触发。**这一步必须做完才允许把 `enforcement_status` 从 `template-only` 升为 `verified`**

### P1-B 校验器完全不覆盖 `templates/*.tpl`

- **证据**：`tools/validate_playbook.py:45-51` 的 `content_files()` 只做 `glob("*.md")`；实跑输出的扫描清单为 7 个 `.md`，`templates/` 下的 3 个 `.tpl` **一个都没被检查**
- **连带后果**：`validate()` 中 `if kind == "template" and not path.name.endswith(".tpl")` 这条分支永远不可能命中（能进循环的一定是 `.md`），属逻辑死区
- **影响**：`templates/` 恰恰是唯一会被复制到真实项目里的产物，却在校验范围之外。模板段落缺失、frontmatter 写错都不会被发现
- **建议**：`content_files()` 改为扫描目录下所有文件（或 `*` 再按扩展名判断），仅排除 `_TEMPLATE.md`
- **验证方式**：临时删掉 `templates/AGENTS.md.tpl` 的 `## 已知限制` 段，校验器应报错；当前实现下它会静默通过

### P2-B 零提交使“新增文档”检查退化为全量校验

- **证据**：`git log` → `your current branch 'master' does not have any commits yet`；`git status --porcelain` 将 19 个文件全部标为 `??`
- **影响**：`.codex/hooks/check-governance.ps1:36-46` 依赖 `git status` 判定“新增 md”，在零提交阶段所有文档都是“新增”，每次检查都在做全量白名单校验。文档量上来后噪音会掩盖真实违规；同时 `git ls-files --cached` 为空，行数检查完全依赖 `--others` 分支
- **建议**：完成一次初始提交。提交后不需要改代码，语义自动恢复
- **验证方式**：`git log` 有首个提交后，`check-governance.ps1` 的 DOC_PATH 只针对工作区增量生效

### P2-C 实例脚本与模板已分叉，且无一致性检查

- **证据**
  - 实例 `.codex/hooks/check-governance.ps1:3-4`：`$SourceExtensions = @('.py')`、`$AllowedDocPrefixes = @('rules/','workflows/','templates/','tools/','reviews/')`
  - 模板 `templates/check-governance.ps1.tpl:21-22`：`@('.ts','.tsx','.js','.jsx','.py','.go','.rs','.java','.cs')`、`@('docs/prd/','docs/plan/','docs/adr/')`
- **影响**：分叉本身是合理的（实例已按本项目调参），但没有任何地方记录“实例基于模板哪一版”，也没有检查两者公共逻辑是否同步。模板修 bug 时实例不会跟着改，这是这类“复制式模板”最常见的腐化路径
- **建议**：在实例文件头部加一行注释登记来源模板与版本日期；或在校验器里加一条“实例与模板的公共函数体必须一致”的弱检查
- **验证方式**：修改模板中行数统计逻辑，能看到实例文件被提示“来自旧版模板”

### P3-D 模板里的 git 缺失回退分支不可达

- **证据**：`templates/check-governance.ps1.tpl:31-37` 已在无 git 时 `exit 3`；随后 `:39-47` 的 `Get-TrackedFiles` 仍保留 `Get-Command git` 判定与 `Get-ChildItem -Recurse` 兜底
- **影响**：死代码。读者会误以为“没装 git 也能降级运行”，与上方 `GIT_REQUIRED` 的严格立场自相矛盾
- **建议**：删掉兜底分支，或在文件头明确写“本脚本要求 git，无 git 直接失败”并把兜底一并删除，二选一
- **验证方式**：全文检索 `Get-ChildItem -Recurse`，不应存在于 `templates/check-governance.ps1.tpl`

### P3-E 没有任何 CI，`enforcement: ci` 档位空转

- **证据**：仓库内无 `.github/workflows/`、无任何流水线配置
- **影响**：`README.md` 第 3 节把 `ci` 列为“绕不过”的最高强度，但当前不存在任何 `ci` 载体；`templates/codex-hooks.json.tpl` 的「已知限制」也自己承认“必须接入 CI 才能阻止绕过本地 hook”
- **建议**：加一个最小 CI（单文件即可），只跑 `python tools/validate_playbook.py` 与 `check-governance.ps1`；或者在 README 中把 `ci` 明确标注为“本仓库尚未启用”
- **验证方式**：提交一个故意超 800 行的源文件，CI 变红

### P3-F 第一轮审查文档顶部的说明已失效

- **证据**：`reviews/review-2026-10-21-workbuddy.md:12-14` 写着“`type: review` 目前不在 `REQUIRED_BY_TYPE` 中，因此本文件不被校验器检查”
- **影响**：本轮实跑显示 7 个被检文件中已包含 2 个 review，该说明与现状相反。审查记录里留下过时结论，会让后来者重复判断
- **建议**：删除该说明，或改为“本说明已于第二轮复核时失效，review 类型已纳入校验”
- **验证方式**：`python tools/validate_playbook.py` 的扫描清单包含 `reviews/*.md`

## 待实测项（本文件未验证，不得当作结论）

1. `matcher` 改成 `apply_patch` 后 hook 是否真的被调用——需要一次真实的 Codex 编辑动作。
2. `PostToolUse` 返回 `{"continue": false}` 在 Codex 中是否能真正中止后续执行（Claude 语义如此，Codex 是否一致未验证）。
3. Codex 是否提供“信任项目 hook”的 UI 交互，以及未信任时 hook 是被跳过还是被拒绝。`templates/codex-hooks.json.tpl` 的使用说明第 3 步默认存在该交互，本轮未能证实。

## 建议的处置顺序

| 顺序 | 动作 | 阻塞关系 |
|---|---|---|
| 1 | `matcher` 改 `apply_patch`（P0-A） | 不修则一切 hook 讨论都是空谈 |
| 2 | marker 实测触发一次（P0-A 验证方式） | 决定两条规则能否标 `installed` / `verified` |
| 3 | 完成首次提交（P2-B） | 恢复增量语义，同时让 diff 可审 |
| 4 | 校验器覆盖 `.tpl`（P1-B） | 模板是最需要防回归的产物 |
| 5 | 清理模板死代码（P3-D） | 与 `GIT_REQUIRED` 立场保持一致 |
| 6 | 加最小 CI 或明确标注“未启用”（P3-E） | `ci` 档位才有意义 |
| 7 | 实例登记来源模板版本（P2-C）、修正陈旧注释（P3-F） | 可维护性 |

## 本文件未做的事

- 未修改任何既有文件（含 `README.md`、规则、模板、脚本）
- 未执行 `codex exec` 或任何真实编辑动作——会消耗账号额度，需先获得同意
- 未在 `README.md` 第 8 节登记本文件，按第一轮的同一约定交由采纳方统一登记
- 未安装 PowerShell 7，`pwsh` 在本机仍不可用
