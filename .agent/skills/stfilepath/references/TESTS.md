Testing guidance and suggested unit tests

Use cases
1) 跑全量单测
```bash
swift test
```

2) 只跑 watcher 测试（最容易 flake/hang 的部分）
```bash
swift test --filter STFilePathTests.STFolderWatcherTests --filter STFilePathTests.STWatcherTests
```

3) 只跑某个具体用例（快速迭代）
```bash
swift test --filter STFilePathTests.STFolderWatcherTests/testWatcher
```

Run existing tests:
- `swift test`

Existing test coverage (where to look first)
- File ops: `Tests/STFilePathTests/STFileTests.swift`
- Folder ops + search: `Tests/STFilePathTests/STFolderTests.swift`
- Watchers: `Tests/STFilePathTests/STFolderWatcherTests.swift`, `Tests/STFilePathTests/STWatcherTests.swift`
- DownloadableFile: `Tests/STFilePathTests/DownloadableFileTests.swift`
- MMAP: `Tests/STFilePathTests/STFileMMAPTests.swift`
- Metadata/link: `Tests/STFilePathTests/STPath+MetadataTests.swift`, `Tests/STFilePathTests/STPath+LinkTests.swift`
- Paths/protocol: `Tests/STFilePathTests/STPathTests.swift`

Suggested tests to add (only if a feature lacks coverage)
1) Permissions + xattrs integration (Darwin-only)
- Set POSIX permissions via `set(permissions:)` and read back via `permissions()`.
- Write/read/remove a test xattr via `extendedAttributes`.

2) Compression round-trip (if `Compression` module available)
- Compress + decompress data via `STComparator` and assert equality.
- Optionally cover `DownloadableFile.compression(_:)`.

3) Watcher integration test (flaky — mark as integration)
- Start watcher on a temp folder, create a file, assert watcher reports create event. Run with retry/timeout.

Notes on flaky tests
- Watcher tests can be timing-sensitive. Use small timeouts and retries and mark them as integration or provide environment variable to skip on slow CI.
  - Prefer waiting on an `AsyncThrowingStream` with a timeout, rather than blocking indefinitely on `.next()`.
