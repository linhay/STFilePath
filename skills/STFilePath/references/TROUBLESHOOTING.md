Troubleshooting & Common Issues

Use cases
1) `swift test` 卡住（常见于 watcher）：用 timeout 等待事件，参考 `Tests/STFilePathTests/WatcherTestSupport.swift`
2) iOS 读写用户选择文件失败：确认 security-scoped resource 流程（见下方第 7 点）
3) 权限/不可写：检查 `path.permission` 与 POSIX 权限（`set(permissions:)` / `permissions()`）

1) Folder watcher (FSEvents) latency and grouping
- Symptom: Events appear delayed or multiple events are reported together.
- Why: FSEvents groups events by latency; event granularity can differ from DispatchSource.
- Solution: Filter for the event kinds/paths you need; in tests, use timeouts + retry loops rather than assuming a single event.
- Note: FSEvents might report folder-level events alongside file-level events.

2) AsyncStream / Iterator hanging in tests
- Symptom: `swift test` hangs during watcher tests.
- Cause: `iterator.next()` waits indefinitely for the next event.
- Solution: Use a `TaskGroup` with a timeout when awaiting events in unit tests.

3) Swift 6 Concurrency Warnings
- Symptom: "Capture of 'self' in closure is not Sendable"
- Solution: All watcher types must be `Sendable`. If internal backends are not easily made `Sendable`, use `@unchecked Sendable` and ensure thread-safe access to the backend.

4) "Inaccessible due to internal protection level"
- Symptom: Compilation error when using `STFolder.Sanbox.url` in tests or other modules.
- Fix: Ensure properties intended for public use are explicitly marked `public`. For example, `Sanbox.url` was changed to `public`.

5) Mismatched watcher types / Ambiguity
- Symptom: "Ambiguous use of 'watcher()'" or "Cannot convert value of type 'STPathWatcher' to 'STFolderWatcher'".
- Solution: Be explicit about types when necessary, or ensure the compiler can infer the type. `tempFolder.watcher()` might return `STPathWatcher` via protocol extension; use `tempFolder.watcher(options:)` to get `STFolderWatcher`.

6) lsof / openingProcesses() returns empty
- Check: Ensure the file is actually open by a process. OS caches and immediate closes might make the window for detection very small. Give a small delay (`Task.sleep`) after opening a file before calling `openingProcesses()`.

7) iOS file access / security-scoped resources
- Symptom: Read/write fails for a file picked via `UIDocumentPicker`.
- Cause: You must call `startAccessingSecurityScopedResource()` before reading/writing, and stop when done (or rely on the picker flow).
- Tip: `STDocumentPicker` starts access for picked URLs; for long-lived access, persist bookmarks (outside this library’s scope).

8) JSON lines writer missing newline separation
- Symptom: Appended JSON objects end up concatenated.
- Cause: Writer only inserts a newline when the file has content and doesn’t end with `\n`.
- Solution: Use `STLineFile.NewLineWriter.append(...)` and ensure you always write line-delimited JSON objects (1 JSON per line).
