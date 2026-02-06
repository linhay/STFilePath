Search (enumeration) and backup

Search hints
- `rg -n "enum SearchPredicate|func subFilePaths\\(|func allSubFilePaths\\(|func files\\(matching" Sources/STFilePath/STFolder\\+Search.swift`
- `rg -n "class STFolderBackup|func backup\\(options" Sources/STFilePath`

Use cases
1) 递归找所有 `.json`（跳过隐藏文件）
```swift
import STFilePath

let root = STFolder("/tmp/data")
let files = try root.files(
  matching: { $0.url.pathExtension == "json" },
  in: { _ in true }
)
let visible = files.filter { !$0.url.lastPathComponent.hasPrefix(".") }
print(visible.count)
```

2) 目录实时备份到多个目标目录
```swift
import STFilePath

let src = STFolder("/tmp/src")
let a = STFolder("/tmp/backup-a")
let b = STFolder("/tmp/backup-b")
let backup = src.backup(options: .init(watcher: .init(interval: .milliseconds(200)), targetFolders: [a, b]))
try backup.connect()
Task { try await backup.monitoring() }
```

3) 非递归列出当前目录文件（适合做简单清理脚本）
```swift
import STFilePath

let folder = STFolder("/tmp")
let files = try folder.files([.skipsHiddenFiles])
print(files.map(\.url.lastPathComponent))
```

Folder enumeration
- Non-recursive:
  - `STFolder.subFilePaths(_:) -> [STPath]`
  - `STFolder.files(_:) -> [STFile]`
  - `STFolder.folders(_:) -> [STFolder]`
- Recursive:
  - `STFolder.allSubFilePaths(_:) -> [STPath]`
  - Filtered recursion:
    - `STFolder.files(matching:in:) -> [STFile]` (recursive, with folder and file filters)

Predicates
- `STFolder.SearchPredicate` maps to `FileManager.DirectoryEnumerationOptions` + custom closures.

Backup
- Create: `STFolder.backup(options:) -> STFolderBackup`
- `STFolderBackup.connect()` does an initial sync then prepares watcher stream.
- `STFolderBackup.monitoring()` consumes folder watcher changes and applies deltas to targets.
- `STFolderBackup.stopMonitoring()` stops watcher.

Common gotchas
- Backup uses `relativePath(from:)` to map source files into target folder trees.
- Backup compares `STPathAttributes.modificationDate` for change detection; be careful if you change timestamp semantics.

Where to change behavior
- Search: `Sources/STFilePath/STFolder+Search.swift`
- Backup: `Sources/STFilePath/STFolderBackup.swift`
- Tests: `Tests/STFilePathTests/STFolderTests.swift` (search basics)
