---
id: rule-<短横线描述>
type: rule
scope: global
applies_to: [codex, cursor, claude-code]
enforcement: doc
last_verified: 2026-10-21
---

## 适用场景

<!-- 越具体越好，最好能写成 if 条件。例：当 agent 要新建 .md 文件时 -->

## 规则

<!-- 祈使句，一条一句，必须能被程序判定。
     好：单个源码文件不超过 800 行。
     坏：代码要保持整洁。 -->

- 
- 

## 反例

<!-- 给出具体文件名 / 代码片段，不要抽象描述 -->

```text
src/service/user.ts  912 行  ← 违规
```

## 验证方式

<!-- 跑什么命令、看什么输出。没有就写“尚未上脚本，原因是 ___” -->

```bash
# 例：扫描超限文件
git ls-files 'src/**/*.ts' | xargs wc -l | awk '$1 > 800'
```

## 升级路径

<!-- 这条规则怎么从 doc 变成 hook / ci -->
