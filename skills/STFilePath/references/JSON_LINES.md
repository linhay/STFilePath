JSON Lines (JSONL) / line-oriented file access

Search hints
- `rg -n "struct STLineFile|NewLineWriter|lineFile" Sources/STFilePath/STJSONLines.swift`

Use cases
1) 结构化日志（每行一个 JSON，适合后续 grep/解析）
```swift
import Foundation
import STFilePath

struct LogRow: Codable { let t: Double; let level: String; let msg: String }

let file = STFile("/tmp/app.jsonl")
try file.createIfNotExists()
let writer = try file.lineFile.newLineWriter
try writer.append(model: LogRow(t: Date().timeIntervalSince1970, level: "INFO", msg: "start"))
```

2) 批量读取并 decode 为模型数组
```swift
import STFilePath

let rows: [LogRow] = try STFile("/tmp/app.jsonl").lineFile.lines(as: LogRow.self)
```

3) 只拿原始行（Data），自己做过滤/聚合
```swift
import STFilePath

let lines: [Data] = try STFile("/tmp/app.jsonl").lineFile.lines()
let nonEmpty = lines.filter { !$0.isEmpty }
```

What exists
- `STFile.lineFile -> STLineFile`
- `STLineFile.lines() throws -> [Data]` reads the file split by `\n` (newline not included).
- `STLineFile.lines(as: Model.Type) throws -> [Model]` decodes each line as JSON using `JSONDecoder`.
- `STLineFile.newLineWriter` provides `append(model:)` and `append(_:)`:
  - Appends a newline if the file has content and doesn't end with `\n`.
  - Note: the writer does not automatically append a trailing `\n` after each write; it ensures separation.

Example

```swift
import Foundation
import STFilePath

struct Row: Codable { let id: Int; let name: String }

let file = STFile("/tmp/rows.jsonl")
try file.createIfNotExists()

let writer = try file.lineFile.newLineWriter
try writer.append(model: Row(id: 1, name: "A"))
try writer.append(model: Row(id: 2, name: "B"))

let rows: [Row] = try file.lineFile.lines(as: Row.self)
```

Where to change behavior
- `Sources/STFilePath/STJSONLines.swift`
