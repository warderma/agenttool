#!/usr/bin/env python3
"""Validate the governance artifacts in this repository without third-party packages."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTENT_DIRS = {"rules", "workflows", "templates", "tools", "reviews"}
EXPECTED_TYPE = {
    "rules": "rule",
    "workflows": "workflow",
    "templates": "template",
    "tools": "tool",
    "reviews": "review",
}
FILENAME_PREFIX = {"rule": "rule-", "workflow": "wf-"}
ENFORCEMENT_STATUSES = {"planned", "template-only", "installed", "verified"}
REQUIRED_BY_TYPE = {
    "rule": ("## 适用场景", "## 规则", "## 反例", "## 验证方式"),
    "workflow": ("## 适用场景", "## 步骤", "## 停止条件", "## 验证方式"),
    "template": ("## 用途", "## 正文", "## 使用说明", "## 已知限制"),
    "tool": ("## 这个工具在链路里的位置", "## 配置位置", "## 规则怎么落地", "## 已验证 / 未验证"),
    "review": ("## 审查对象", "## 结论摘要", "## 问题清单", "## 建议的处置顺序"),
}


def frontmatter(text: str) -> dict[str, str] | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end < 0:
        return None
    values: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            values[key.strip()] = value.strip()
    return values


def content_files() -> list[Path]:
    files: list[Path] = []
    for folder in CONTENT_DIRS:
        for path in (ROOT / folder).iterdir():
            if path.is_file() and path.name != "_TEMPLATE.md" and path.suffix in {".md", ".tpl"}:
                files.append(path)
    return sorted(files)


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    meta = frontmatter(text)
    label = path.relative_to(ROOT).as_posix()
    if meta is None:
        return [f"{label}: missing or malformed YAML frontmatter"]
    required_meta = ("id", "type", "scope", "applies_to", "enforcement", "last_verified")
    for key in required_meta:
        if not meta.get(key):
            errors.append(f"{label}: missing frontmatter field '{key}'")
    kind = meta.get("type")
    if kind not in REQUIRED_BY_TYPE:
        errors.append(f"{label}: unknown type '{kind}'")
        return errors
    expected_kind = EXPECTED_TYPE.get(path.parent.name)
    if expected_kind and kind != expected_kind:
        errors.append(f"{label}: type '{kind}' does not match directory type '{expected_kind}'")
    prefix = FILENAME_PREFIX.get(kind)
    if prefix and not path.name.startswith(prefix):
        errors.append(f"{label}: {kind} filename must start with '{prefix}'")
    if kind == "template" and not path.name.endswith(".tpl"):
        errors.append(f"{label}: template filename must end with '.tpl'")
    if path.suffix == ".tpl" and kind != "template":
        errors.append(f"{label}: .tpl file must use type 'template'")
    for heading in REQUIRED_BY_TYPE[kind]:
        if heading not in text:
            errors.append(f"{label}: missing required heading '{heading}'")
    if meta.get("enforcement") == "doc" and kind == "rule":
        verification = text.split("## 验证方式", 1)[-1]
        if not re.search(r"原因|尚未|无法|差异", verification):
            errors.append(f"{label}: doc-only rule must explain why enforcement is not automated")
    if meta.get("enforcement") in {"hook", "ci"}:
        status = meta.get("enforcement_status")
        if status not in ENFORCEMENT_STATUSES:
            errors.append(f"{label}: hook/ci artifact needs enforcement_status in {sorted(ENFORCEMENT_STATUSES)}")
    return errors


def main() -> int:
    files = content_files()
    errors = [error for path in files for error in validate(path)]
    seen_ids: dict[str, Path] = {}
    for path in files:
        meta = frontmatter(path.read_text(encoding="utf-8"))
        if meta and meta.get("id"):
            artifact_id = meta["id"]
            if artifact_id in seen_ids:
                errors.append(f"{path.relative_to(ROOT)}: duplicate id '{artifact_id}' also used by {seen_ids[artifact_id].relative_to(ROOT)}")
            else:
                seen_ids[artifact_id] = path
    if errors:
        print("Playbook validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print(f"Playbook validation passed ({len(files)} artifacts checked).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
