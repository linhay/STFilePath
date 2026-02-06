STFilePath Examples (API-accurate snippets)

Use cases
1) 基础文件 CRUD：见「1) Basic: create/read/append/delete」
2) 监听变更：见「3) Folder watcher」与「4) Path watcher」
3) 数据模型落盘：见「5) DownloadableFile + Codable」与「6) JSON lines」

If you need a deep-dive (including gotchas and where to change code), open:
- IO: `references/FILE_IO.md`
- Watchers: `references/WATCHERS.md`
- Hashing: `references/HASHING.md`
- DownloadableFile: `references/DOWNLOADABLEFILE.md`
- JSON Lines: `references/JSON_LINES.md`
- Search/backup: `references/SEARCH_AND_BACKUP.md`

1) Basic: create/read/append/delete

```swift
import Foundation
import STFilePath

let documents = try STFolder(sanbox: .document)
let folder = try documents.folder("Example").create()
let file = try folder.file("hello.txt").create(with: Data("Hello".utf8))

let content = try file.read() // String
try file.append(data: Data(" world".utf8))
try file.delete()
```

2) Hashing (CryptoKit, SHA256)

```swift
import STFilePath

let file = STFile("/tmp/demo.txt")
let sha = try file.hash(with: .sha256) // String hex digest
print(sha)
```

3) Folder watcher (Async stream)

```swift
import STFilePath

let temp = try STFolder(sanbox: .temporary)
let folder = try temp.folder("WatchDemo").create()

let watcher = folder.watcher(options: .init(interval: .milliseconds(200)))
let stream = try watcher.streamMonitoring()

Task {
    for try await change in stream {
        print("\(change.kind): \(change.file.url.lastPathComponent)")
    }
}
```

4) Path watcher (unified; folder uses FSEvents on macOS)

```swift
import STFilePath

let path = STPath("/tmp")
let watcher = STPathWatcher(path: path)

Task {
    for try await event in watcher.stream() {
        print("\(event.kind): \(event.path.url.path)")
    }
}
```

5) DownloadableFile + Codable

```swift
import Foundation
import STFilePath

struct MyModel: Codable, Sendable { var name: String; var value: Int }

let file = STFile("/tmp/model.json")
try file.createIfNotExists(with: Data("{}".utf8))

let df = file.toDFAnyFile().codable(MyModel.self)
Task {
    let model = try await df.fetch()
    try await df.save(.init(name: model.name, value: model.value + 1))
}
```

6) JSON lines (append + read)

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
print(rows.count)
```

7) Extended attributes (Darwin only)

```swift
import Foundation
import STFilePath

let file = STFile("/tmp/xattr.txt")
try file.createIfNotExists(with: Data("hi".utf8))

try file.extendedAttributes.set(name: "com.example.tag", value: Data("demo".utf8))
let v = try file.extendedAttributes.value(of: "com.example.tag")
print(String(decoding: v, as: UTF8.self))
```
