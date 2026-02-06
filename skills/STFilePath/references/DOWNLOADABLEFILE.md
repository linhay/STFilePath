DownloadableFile (async fetch/save pipeline)

Search hints
- `rg -n "protocol DownloadableFile" Sources/STFilePath/DownloadableFile`
- `rg -n "struct DFAnyFile|struct DFFileMap|class DFCurrentValueFile" Sources/STFilePath/DownloadableFile`

Use cases
1) 设置文件（JSON）读写（异步）
```swift
import Foundation
import STFilePath

struct Settings: Codable, Sendable { var enabled: Bool }
let file = STFile("/tmp/settings.json")
try file.createIfNotExists(with: Data("{}".utf8))

let settings = file.toDFAnyFile().codable(Settings.self)
Task {
  let s = try await settings.fetch()
  try await settings.save(.init(enabled: !s.enabled))
}
```

2) currentValueFile：UI 修改配置时自动保存（最后一次胜出）
```swift
import STFilePath

let file = STFile("/tmp/state.json")
try file.createIfNotExists(with: Data("{}".utf8))

let state = file.toDFAnyFile().codable([String: Int].self).currentValueFile([:])
Task { _ = try await state.fetch() }
state.value?["count"] = 1
state.value?["count"] = 2
```

Concept
- `DownloadableFile` is an abstraction over “a persisted model” that can be:
  - fetched asynchronously: `fetch() async throws -> Model`
  - saved asynchronously: `save(_:) async throws`
- It’s designed to compose via mapping/transforms.

Main building blocks
1) `DFAnyFile<Model>` (type-erased file)
- Build from closures: `DFAnyFile(fetch:save:)`
- Or wrap an `STFile` as raw data: `DFAnyFile(file: STFile)` (when `Model == Data`)
- Convenience: `STFile.toDFAnyFile() -> DFAnyFile<Data>`

2) `DFFileMap<File, To>`
- Created via `DownloadableFile.map(fetch:save:)`
- Lets you project a file into a different model type, transforming both fetch and save.

3) `codable(_:)` helper (when `Model == Data`)
- `file.toDFAnyFile().codable(MyCodable.self)` uses JSONEncoder/JSONDecoder defaults:
  - base64 for `Data`, iso8601 for `Date`, prettyPrinted+sortedKeys by default

4) `DFCurrentValueFile`
- Wraps another `DownloadableFile` and keeps a mutable `value` that auto-saves on set.
- It uses a `Task` that cancels the previous save (last write wins).

Example: Codable model in a JSON file

```swift
import Foundation
import STFilePath

struct Settings: Codable, Sendable {
    var enabled: Bool
    var updatedAt: Date
}

let file = STFile("/tmp/settings.json")
try file.createIfNotExists(with: Data("{}".utf8))

let settingsFile = file.toDFAnyFile().codable(Settings.self)
Task {
    let current = try await settingsFile.fetch()
    try await settingsFile.save(.init(enabled: !current.enabled, updatedAt: .init()))
}
```

Example: Current-value file pattern

```swift
import STFilePath

let file = STFile("/tmp/settings.json")
let df = file.toDFAnyFile().codable([String: String].self).currentValueFile([:])
Task { _ = try await df.fetch() }
df.value?["k"] = "v" // triggers save (async)
```

Where to change behavior
- Core protocol + helpers: `Sources/STFilePath/DownloadableFile/DownloadableFile.swift`
- Type erasure + current value: `Sources/STFilePath/DownloadableFile/DFAnyFile.swift`
- Mapping: `Sources/STFilePath/DownloadableFile/DFFileMap.swift`
- Tests: `Tests/STFilePathTests/DownloadableFileTests.swift`
