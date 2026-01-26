---
name: stfilepath-zh
description: "STFilePath 仓库的开发者向导（中文）。当需要在该仓库中阅读、修改、测试或生成示例时使用。"
---

# STFilePath 技能（中文）

简要说明：本文件为开发者在 STFilePath 仓库中常用操作、示例、API 指南和故障排查的简明手册。

快速上手
- 本地编译：`swift build`
- 运行测试：`swift test`
- CI：见 `.github/workflows/swift.yml`（使用 macOS 与 `swift build`/`swift test`）

常见任务
- 查看实现：references/FILES.md
- 复制示例：references/EXAMPLES.md 或 scripts/example_usage.swift
- API 快速参考：references/API_REFERENCE.md

故障排查（简要）
- 监视器无事件：确认 watcher.connect() 与 monitoring() 已调用，检查权限
- 权限错误：iOS 需使用受支持的容器，macOS 检查文件系统权限

测试建议
- 在 Tests/STFilePathTests 添加基本 CRUD、哈希与 DownloadableFile 的单元测试
