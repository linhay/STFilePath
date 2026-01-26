Troubleshooting & Common Issues

1) Folder watcher (FSEvents) latency and grouping
- Symptom: Events appear delayed or multiple events are reported together.
- Solution: FSEvents groups events by latency (default was 0.2s, now 0.01s). Use a loop to filter for specific file events in tests.
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
