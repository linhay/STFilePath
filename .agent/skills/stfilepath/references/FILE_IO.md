File & folder IO (CRUD, streaming, handles)

Search hints
- `rg -n "struct STFile|func create\\(|func createIfNotExists|func append\\(|func read\\(|func data\\(" Sources/STFilePath/STFile.swift`
- `rg -n "enum STFileOpenKind" Sources/STFilePath`
- `rg -n "struct STFolder|func create\\(|func file\\(|func folder\\(" Sources/STFilePath`

Use cases
1) 写配置文件（JSON）并确保文件存在
```swift
import Foundation
import STFilePath

struct Config: Codable, Sendable { var enabled: Bool }

let file = STFile("/tmp/config.json")
try file.createIfNotExists(with: Data("{}".utf8))
try file.overlay(model: Config(enabled: true))
```

2) 追加写日志（不关心文件是否存在）
```swift
import STFilePath

let file = STFile("/tmp/app.log")
try file.append(data: Data("hello\n".utf8))
```

3) 覆盖写（内容生成后一次性落盘）
```swift
import STFilePath

let file = STFile("/tmp/result.txt")
try file.overlay(with: "final output")
```

STFile basics
- Create: `create(with:)` / `createIfNotExists(with:)`
- Read (string): `read(_:encoding:) -> String`
- Write: `write(_:)`
- Append: `append(data:)` (creates file if missing)
- Move/copy: `move(to:)`, `copy(to:)`, `replace(_:)`
- Byte-level: `data()` / `data(range:)` (availability-gated) / file handle APIs

STFolder basics
- Build child paths (no existence check): `file(_:)`, `folder(_:)`, `subpath(_:)`
- Create: `create()` / `createIfNotExists()`

Streaming helpers
- `STFile.readLines(...)` (line-oriented reading)
- `STFile.readStream(...)` / async stream writing APIs in `STFile` (see `Sources/STFilePath/STFile.swift`)

Low-level handles
- Open kinds are defined by `STFileOpenKind` (`Sources/STFilePath/STFileOpenKind.swift`).
- `STFile.handle(_:)` returns a `FileHandle` configured for read/write/update depending on open kind.

Where to change behavior
- File operations: `Sources/STFilePath/STFile.swift`
- Folder operations: `Sources/STFilePath/STFolder+Folder.swift`
- Tests: `Tests/STFilePathTests/STFileTests.swift`, `Tests/STFilePathTests/STFolderTests.swift`
