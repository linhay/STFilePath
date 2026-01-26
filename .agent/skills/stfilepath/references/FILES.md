STFilePath - important file map

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
- Sources/STFilePath/DownloadableFile/* — DownloadableFile protocol and implementations
- Sources/STFilePath/Compression/* — comparator and compression utilities
- Sources/STFilePath/STPath+Metadata.swift — metadata helpers and hashing
- Sources/STFilePath/STPathProtocol.swift — core protocol and process identification (openingProcesses)
- Tests/STFilePathTests/STWatcherTests.swift — comprehensive watcher and process tests
- Tests/STFilePathTests/* — unit tests; run `swift test` to execute

Notes
- For README examples, see README.md lines ~37-130 which include snippets for basic ops, hashing, watcher, and DownloadableFile.
- CI workflow: .github/workflows/swift.yml — mirrors expected build/test steps.
