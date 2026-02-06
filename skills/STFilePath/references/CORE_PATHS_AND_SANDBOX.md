Core paths & sandbox / containers

Search hints
- `rg -n "struct Sanbox" Sources/STFilePath`
- `rg -n "init\\(sanbox|applicationGroup|iCloud|ubiquityContainerIdentifier" Sources/STFilePath`

Use cases
1) App Group 共享文件（主 App 与扩展共享）
```swift
import STFilePath

let shared = try STFolder(applicationGroup: "group.com.example.app")
let file = shared.file("shared.json")
try file.createIfNotExists(with: Data("{}".utf8))
```

2) 临时目录做中间产物（处理完后删除）
```swift
import STFilePath

let tmp = try STFolder(sanbox: .temporary).folder("job-\(UUID().uuidString)").create()
defer { try? tmp.delete() }
let out = tmp.file("out.txt")
try out.create(with: Data("ok".utf8))
```

3) iCloud 容器目录（iCloud Drive 存储）
```swift
import STFilePath

let iCloud = try STFolder(iCloud: "iCloud.com.example.app")
let file = iCloud.file("notes.json")
```

Sandbox directories (Apple platforms, not Linux)
- `STFolder.Sanbox` lives in `Sources/STFilePath/STFolder+Sanbox.swift`.
- Note: the type name is `Sanbox` (spelling), and the initializer is `STFolder(sanbox:)`.

Examples

```swift
import STFilePath

let documents = try STFolder(sanbox: .document)
let library   = try STFolder(sanbox: .library)
let cache     = try STFolder(sanbox: .cache)
let temp      = try STFolder(sanbox: .temporary)
let home      = try STFolder(sanbox: .home)
```

App group container

```swift
import STFilePath

let groupFolder = try STFolder(applicationGroup: "group.com.example.app")
```

iCloud container

```swift
import STFilePath

let iCloud = try STFolder(iCloud: "iCloud.com.example.app")
```

Path string normalization (`~`, `~/`, schemes)
- `STPathProtocol.standardizedPath(_:)` handles:
  - `~` and `~/...` expansion
  - URL schemes like `http/https/ftp/sftp/ssh/s3`
  - `file://` URLs
  - raw file system paths
- Implementation: `Sources/STFilePath/STPathProtocol.swift`
