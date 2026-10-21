---
id: tpl-codex-check-governance-ps1
type: template
scope: global
applies_to: [codex]
enforcement: hook
enforcement_status: template-only
last_verified: 2026-10-21
---

## 用途

- 目标路径：`<repo>/.codex/hooks/check-governance.ps1`
- 依赖规则：`rules/rule-file-size.md`、`rules/rule-document-governance.md`

## 正文

```powershell
# Requires a Git work tree. Project instances should record their source template
# version and local parameter overrides directly above this comment.
param(
  [int]$MaxLines = 800,
  [string[]]$SourceExtensions = @('.ts', '.tsx', '.js', '.jsx', '.py', '.go', '.rs', '.java', '.cs'),
  [string[]]$AllowedDocPrefixes = @('docs/prd/', 'docs/plan/', 'docs/adr/'),
  [string[]]$AllowedRootDocNames = @('README.md', 'CHANGELOG.md', 'AGENTS.md', 'CLAUDE.md'),
  [switch]$HookMode
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$violations = [System.Collections.Generic.List[string]]::new()

git -C $root rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
  $message = "GIT_REQUIRED: governance checks require a Git work tree at $root"
  if ($HookMode) { @{ continue = $false; stopReason = $message; systemMessage = $message } | ConvertTo-Json -Compress; exit 0 }
  Write-Error $message
  exit 3
}

function Get-TrackedFiles {
  return @(git -C $root ls-files --cached --others --exclude-standard)
}

foreach ($relativePath in Get-TrackedFiles) {
  $normalized = $relativePath.Replace('\', '/')
  $fullPath = Join-Path $root $relativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { continue }
  $extension = [IO.Path]::GetExtension($normalized).ToLowerInvariant()
  if ($SourceExtensions -contains $extension) {
    $lineCount = @(Get-Content -LiteralPath $fullPath).Count
    if ($lineCount -gt $MaxLines) { $violations.Add("SOURCE_LIMIT: $normalized has $lineCount lines (max $MaxLines)") }
  }
}

$newDocs = @()
if (Get-Command git -ErrorAction SilentlyContinue) {
  $statusLines = @(git -C $root status --porcelain --untracked-files=all)
  foreach ($line in $statusLines) {
    if ($line -match '^(\?\?|A[ MADRCU])\s+(.+\.(md|mdx))$') { $newDocs += $Matches[2] }
  }
}
foreach ($doc in $newDocs) {
  $normalized = $doc.Replace('\', '/')
  $allowed = ($AllowedDocPrefixes | Where-Object { $normalized.StartsWith($_) }).Count -gt 0
  $allowed = $allowed -or ($AllowedRootDocNames -contains $normalized)
  if (-not $allowed) { $violations.Add("DOC_PATH: new document outside allowed prefixes: $normalized") }
}

if ($violations.Count -gt 0) {
  if ($HookMode) {
    $message = $violations -join '; '
    @{ continue = $false; stopReason = 'Governance validation failed'; systemMessage = $message } | ConvertTo-Json -Compress
    exit 0
  }
  $violations | ForEach-Object { [Console]::Error.WriteLine($_) }
  exit 2
}
if ($HookMode) { @{ continue = $true; systemMessage = 'Governance checks passed.' } | ConvertTo-Json -Compress }
else { Write-Output 'Governance checks passed.' }
```

## 使用说明

1. 复制代码块并按项目语言、构建目录和文档目录修改参数默认值。
2. 在 Git 仓库中从项目根运行：`pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/check-governance.ps1`。
3. 新增文档检查使用 `git status --porcelain`，因此能检查工作区内尚未提交的新增文件。处理重命名或复杂暂存状态时，CI 应使用项目自己的 diff 逻辑复核。

## 已知限制

脚本只能检查路径和行数，无法判定文档是否必要、代码是否职责过多或测试是否有效。这些仍由工作流审查和项目测试覆盖。未安装 PowerShell 7 时，将 `pwsh` 换成 Windows 自带的 `powershell`。
