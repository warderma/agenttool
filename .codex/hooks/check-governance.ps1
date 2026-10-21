# Source template: templates/check-governance.ps1.tpl (2026-10-21).
# Local overrides: this playbook governs Python only and keeps governance docs in its top-level directories.
param(
  [int]$MaxLines = 800,
  [string[]]$SourceExtensions = @('.py'),
  [string[]]$AllowedDocPrefixes = @('rules/', 'workflows/', 'templates/', 'tools/', 'reviews/'),
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
$statusLines = @(git -C $root status --porcelain --untracked-files=all)
foreach ($line in $statusLines) {
  if ($line -match '^(\?\?|A[ MADRCU])\s+(.+\.(md|mdx))$') { $newDocs += $Matches[2] }
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
