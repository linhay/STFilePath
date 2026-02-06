STFilePath - important file map

Use cases
1) 我要加/改 watcher 行为：优先看 `Sources/STFilePath/*Watcher*.swift`、`Sources/STFilePath/*WatcherBackend*.swift`
2) 我要加/改 DownloadableFile：看 `Sources/STFilePath/DownloadableFile/*`，对应测试在 `Tests/STFilePathTests/DownloadableFileTests.swift`
3) 我要做平台集成：iOS 在 `Sources/STFilePath/ios/*`，macOS 在 `Sources/STFilePath/macos/*`

Repository structure (key files)

- Package.swift — Swift package manifest
- README.md / README_zh-CN.md — project documentation and usage examples
- Sources/STFilePath/STPath.swift — core path type and utilities
- Sources/STFilePath/STFile.swift — file operations
- Sources/STFilePath/STFolder+Folder.swift — folder operations (create/search)
- Sources/STFilePath/STFolderWatcher.swift — folder watching orchestrator
- Sources/STFilePath/STFileWatcher.swift — individual file watcher
- Sources/STFilePath/STPathWatcher.swift — generic path watcher
- Sources/STFilePath/WatcherBackend.swift — abstracts different monitoring techniques
- Sources/STFilePath/macos/FSEventsWatcher.swift — efficient macOS-only backend
- Sources/STFilePath/DispatchSourceWatcher.swift — cross-platform VNODE-based backend
- Sources/STFilePath/STFile+CryptoKit.swift — hashing (CryptoKit)
- Sources/STFilePath/STPathAttributes.swift — metadata wrapper for file attributes
- Sources/STFilePath/STPathPermission.swift — permission helpers (exists/read/write/execute/delete + POSIX)
- Sources/STFilePath/STPath+Metadata.swift — POSIX permissions + extended attributes (xattr)
- Sources/STFilePath/STPath+Link.swift — symlink helpers
- Sources/STFilePath/STJSONLines.swift — JSONL line-oriented read/write
- Sources/STFilePath/STFile+MMAP.swift — mmap support (Darwin only)
- Sources/STFilePath/STFile+Darwin.swift — low-level Darwin file APIs (open/stat/truncate/sync)
- Sources/STFilePath/DownloadableFile/* — DownloadableFile protocol and implementations
- Sources/STFilePath/Compression/* — comparator and compression utilities
- Sources/STFilePath/STPathProtocol.swift — core protocol and process identification (openingProcesses)
- Sources/STFilePath/Surroundings/* — STKVCache and STUserDefaults
- Sources/STFilePath/ios/* — iOS document picker & QuickLook preview
- Sources/STFilePath/macos/* — Finder selection + associated applications
- Tests/STFilePathTests/STWatcherTests.swift — comprehensive watcher and process tests
- Tests/STFilePathTests/* — unit tests; run `swift test` to execute

Notes
- For README examples, see README.md lines ~37-130 which include snippets for basic ops, hashing, watcher, and DownloadableFile.
- CI workflow: .github/workflows/swift.yml — mirrors expected build/test steps.
