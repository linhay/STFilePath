STFilePath - API Quick Reference (short)

STFile (file-level operations)
- create(with: Data) -> create file with contents
- read() -> Data
- append(data: Data)
- delete()
- move(to: STFile)
- hash(with: HashAlgorithm) -> String
- watcher() -> STFileWatcher

STFolder (folder-level operations)
- folder(name: String) -> STFolder (path builder)
- file(name: String) -> STFile (path builder)
- create() -> create folder
- delete()
- watcher(options:) -> STFolderWatcher

STPath / STPathProtocol
- path string properties, checks for isExists, isFolderExists, isFileExists
- watcher() -> STPathWatcher (generic)
- openingProcesses() -> [STProcessInfo] (macOS only)

STProcessInfo
- pid: Int32
- name: String
- command: String

Watcher Classes (STFileWatcher, STFolderWatcher, STPathWatcher)
- streamMonitoring() / stream() -> AsyncThrowingStream of events
- stopMonitoring() / stop() -> terminates the stream

DownloadableFile / DFAnyFile
- .codable(Type.self) to transform to Codable handling
- fetch() async -> Type
- save(_:) async to persist transformed content

Where to find implementations
- Sources/STFilePath/STFile.swift
- Sources/STFilePath/STFolder+Folder.swift
- Sources/STFilePath/STFolderWatcher.swift
- Sources/STFilePath/STFileWatcher.swift
- Sources/STFilePath/STPathWatcher.swift
- Sources/STFilePath/STPathProtocol.swift
- Sources/STFilePath/DownloadableFile/*

Note: This reference is intentionally concise. For method signatures and exact parameter types, open the source files listed above.
