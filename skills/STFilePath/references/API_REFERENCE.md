STFilePath - API Quick Reference (accurate, terse)

If you need deeper coverage by area, open the matching reference file:
- File/folder IO: `references/FILE_IO.md`
- Sandbox/containers: `references/CORE_PATHS_AND_SANDBOX.md`
- Watchers: `references/WATCHERS.md`
- Hashing: `references/HASHING.md`
- Metadata/permissions/xattrs/symlinks: `references/METADATA_PERMISSIONS_XATTR_LINKS.md`
- MMAP & Darwin: `references/MMAP_AND_DARWIN.md`
- DownloadableFile: `references/DOWNLOADABLEFILE.md`
- Search/backup: `references/SEARCH_AND_BACKUP.md`
- JSON Lines: `references/JSON_LINES.md`
- Integrations: `references/INTEGRATIONS_IOS_MACOS.md`

Use cases
1) 我想“直接写代码”而不是翻源码：先看 `references/FUNCTION_COOKBOOK.md`
2) 我想快速复制粘贴：看 `references/EXAMPLES.md`
3) 我想改库实现/补测试：先看 `references/FILES.md`（定位实现与测试文件）

Search hints
- Core protocol: `rg -n "protocol STPathProtocol" Sources/STFilePath`
- Core types: `rg -n "struct STPath|struct STFile|struct STFolder" Sources/STFilePath`
- Watchers: `rg -n "Watcher|ST(Folder|File|Path)Watcher|WatcherBackend" Sources/STFilePath`
- DownloadableFile: `rg -n "protocol DownloadableFile|DFAnyFile|DFFileMap|DFCurrentValueFile" Sources/STFilePath`

Core types
- `STPathProtocol`: shared URL-based API for paths (exists/type/relativePath, attributes, permission, etc.). Implementation: `Sources/STFilePath/STPathProtocol.swift`
- `STPath`: type-erased path (file/folder/notExist), can expose `referenceType` as `STFilePathReferenceType`. Implementation: `Sources/STFilePath/STPath.swift`
- `STFile`: file path + file ops. Implementation: `Sources/STFilePath/STFile.swift`
- `STFolder`: folder path + folder ops. Implementation: `Sources/STFilePath/STFolder+Folder.swift`

Path classification & reference
- `STFilePathItemType`: `.file/.folder/.notExist`. Implementation: `Sources/STFilePath/STFilePathItemType.swift`
- `STFilePathReferenceType`: `.file(STFile)` / `.folder(STFolder)`. Implementation: `Sources/STFilePath/STFilePathReferenceType.swift`

Watchers (AsyncThrowingStream-based)
- `STFileWatcher(file: STFile).stream() -> AsyncThrowingStream<STPathChanged, Error>` and `.stop()`. Implementation: `Sources/STFilePath/STFileWatcher.swift`
- `STFolderWatcher(folder: STFolder, options:).streamMonitoring() -> AsyncThrowingStream<STFolderWatcher.Changed, Error>` and `.stopMonitoring()`. Implementation: `Sources/STFilePath/STFolderWatcher.swift`
- `STPathWatcher(path: STPath).stream() -> AsyncThrowingStream<STPathChanged, Error>` and `.stop()`. Implementation: `Sources/STFilePath/STPathWatcher.swift`
- Backends:
  - macOS folder/path: FSEvents (`Sources/STFilePath/macos/FSEventsWatcher.swift`)
  - file + non-macOS: DispatchSource (`Sources/STFilePath/DispatchSourceWatcher.swift`)
  - common event model: `Sources/STFilePath/WatcherBackend.swift` (`STPathChanged`, `STPathChangeKind`)

Hashing (CryptoKit)
- `STHasherKind`: `.sha256/.sha384/.sha512/.md5` (md5 uses `Insecure.MD5`). Implementation: `Sources/STFilePath/STFile+CryptoKit.swift`
- `STFile.hash(with kind: STHasherKind) -> String` (hex digest). Implementation: `Sources/STFilePath/STFile+CryptoKit.swift`

Metadata / permissions / xattrs / symlinks
- Attributes wrapper: `STPathAttributes` via `STPathProtocol.attributes`. Implementation: `Sources/STFilePath/STPathAttributes.swift`
- Convenience permissions:
  - `STPathProtocol.permission -> STPathPermission` (exists/readable/writable/executable/deletable). Implementation: `Sources/STFilePath/STPathProtocol.swift`, `Sources/STFilePath/STPathPermission.swift`
  - POSIX permissions helpers: `STPathProtocol.permissions()` / `set(permissions:)` and `STPathPermission.Posix`. Implementation: `Sources/STFilePath/STPath+Metadata.swift`, `Sources/STFilePath/STPathPermission.swift`
- Extended attributes (Darwin only): `STPathProtocol.extendedAttributes` with `set/value/remove/list`. Implementation: `Sources/STFilePath/STPath+Metadata.swift`
- Symlink helpers: `isSymbolicLink`, `createSymbolicLink(to:)`, `destinationOfSymbolicLink()`. Implementation: `Sources/STFilePath/STPath+Link.swift`
- Security-scoped resource helpers (Apple platforms): `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`. Implementation: `Sources/STFilePath/STPathProtocol.swift`

Search & enumeration
- `STFolder.files(...) / folders(...) / subFilePaths(...) / allSubFilePaths(...)`. Implementation: `Sources/STFilePath/STFolder+Search.swift`
- `STFolder.SearchPredicate` and custom filters. Implementation: `Sources/STFilePath/STFolder+Search.swift`
- Recursive file scanning with filters: `STFolder.files(matching:in:)`. Implementation: `Sources/STFilePath/STFolder+Search.swift`

Backup
- `STFolder.backup(options:) -> STFolderBackup`, `connect()`, `monitoring() async`, `stopMonitoring()`. Implementation: `Sources/STFilePath/STFolderBackup.swift`

JSON Lines
- `STFile.lineFile -> STLineFile`, `STLineFile.lines()` / `lines(as:)`, `STLineFile.NewLineWriter.append(...)`. Implementation: `Sources/STFilePath/STJSONLines.swift`

DownloadableFile
- `DownloadableFile` protocol: `fetch()` / `save(_:) async`. Implementation: `Sources/STFilePath/DownloadableFile/DownloadableFile.swift`
- `DFAnyFile<Model>` type erasure and `DFAnyFile(file: STFile)` when `Model == Data`. Implementation: `Sources/STFilePath/DownloadableFile/DFAnyFile.swift`
- `DFFileMap<File, To>` mapping via `map(fetch:save:)` and helpers like `.codable(...)`, `.compression(...)`. Implementation: `Sources/STFilePath/DownloadableFile/DFFileMap.swift`, `Sources/STFilePath/DownloadableFile/DownloadableFile.swift`
- `DFCurrentValueFile`: debounced-ish “last write wins” wrapper that saves on `value` set. Implementation: `Sources/STFilePath/DownloadableFile/DFAnyFile.swift`
- Convenience: `STFile.toDFAnyFile() -> DFAnyFile<Data>`. Implementation: `Sources/STFilePath/DownloadableFile/DFAnyFile.swift`

Compression (if `Compression` module available)
- `STComparator.compress/decompress(_:algorithm:)`. Implementation: `Sources/STFilePath/Compression/STComparator.swift`
- `DownloadableFile.compression(_:)` for `Model == Data`. Implementation: `Sources/STFilePath/DownloadableFile/DownloadableFile.swift`

MMAP & Darwin file APIs (Darwin only)
- `STFile.withMmap(...) { STFileMMAP in ... }`, `STFile.setSize(_:)`. Implementation: `Sources/STFilePath/STFile+MMAP.swift`
- `STFile.system -> STFileSystem` (`open/stat/truncate/sync/...`). Implementation: `Sources/STFilePath/STFile+Darwin.swift`

Integrations
- iOS: `STDocumentPicker` (UIDocumentPicker) and `STPathQuickLookController` (QuickLook). Implementation: `Sources/STFilePath/ios/*`
- macOS: Finder helpers (`showInFinder`, `selectInFinder`) and associated apps (`associatedApplications`, `open(with:)`). Implementation: `Sources/STFilePath/macos/*`
