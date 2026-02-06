Watchers (file / folder / path) and event model

Search hints
- `rg -n "class STFileWatcher|class STFolderWatcher|class STPathWatcher" Sources/STFilePath`
- `rg -n "enum STPathChangeKind|struct STPathChanged|protocol WatcherBackend" Sources/STFilePath`
- `rg -n "FSEventsWatcher|DispatchSourceWatcher" Sources/STFilePath`

Use cases
1) 热重载配置（文件变化触发重新读取）
```swift
import STFilePath

let file = STFile("/tmp/config.json")
let watcher = file.watcher()
Task {
  for try await _ in watcher.stream() {
    let json = try? file.read()
    print("config updated:", json ?? "<nil>")
  }
}
```

2) 监听目录并做增量同步（适合配合 `STFolderBackup`）
```swift
import STFilePath

let src = STFolder("/tmp/src")
let dst = STFolder("/tmp/dst")
let backup = src.backup(options: .init(watcher: .init(interval: .milliseconds(200)), targetFolders: [dst]))
try backup.connect()
Task { try await backup.monitoring() }
```

3) 单元测试里等待事件（一定要加 timeout，避免 hang）
- 参考：`Tests/STFilePathTests/WatcherTestSupport.swift`

High-level APIs
- File watcher:
  - Create: `STFile.watcher()` (`Sources/STFilePath/STFile+Watcher.swift`)
  - Consume: `STFileWatcher.stream() -> AsyncThrowingStream<STPathChanged, Error>`
  - Stop: `STFileWatcher.stop()`
- Folder watcher:
  - Create: `STFolder.watcher(options:) -> STFolderWatcher`
  - Consume: `streamMonitoring() -> AsyncThrowingStream<STFolderWatcher.Changed, Error>`
  - Stop: `stopMonitoring()`
- Unified path watcher:
  - Create: `STPathWatcher(path: STPath)`
  - Consume: `stream() -> AsyncThrowingStream<STPathChanged, Error>`
  - Stop: `stop()`

Event model
- `STPathChangeKind`: `.created/.modified/.deleted/.renamed`
- `STPathChanged`: `{ kind: STPathChangeKind, path: STPath }`
- Folder watcher wraps backend events into:
  - `STFolderWatcher.ChangeKind`: `.added/.deleted/.changed`
  - `STFolderWatcher.Changed`: `{ kind, file: STFile }`

Backends & platform behavior
- macOS:
  - Folder watcher uses FSEvents (`FSEventsWatcher`) for recursive folder watching.
  - `STPathWatcher` uses FSEvents when `path.isFolderExists == true`.
- Non-macOS and file watcher:
  - Uses `DispatchSourceWatcher` (vnode-based).

Common gotchas
- Timing: watcher tests can be flaky; always use timeouts and allow event coalescing.
- Lifetime: keep the consuming task alive; streams stop when the watcher is stopped/deinited.
- Deprecations:
  - `STFolderWatcher.connect()` and `monitoring()` are deprecated; prefer `streamMonitoring()`.

Where to change behavior
- Event model: `Sources/STFilePath/WatcherBackend.swift`
- Backends: `Sources/STFilePath/DispatchSourceWatcher.swift`, `Sources/STFilePath/macos/FSEventsWatcher.swift`
- Public watchers: `Sources/STFilePath/STFileWatcher.swift`, `Sources/STFilePath/STFolderWatcher.swift`, `Sources/STFilePath/STPathWatcher.swift`
- Tests: `Tests/STFilePathTests/STFolderWatcherTests.swift`, `Tests/STFilePathTests/STWatcherTests.swift`
