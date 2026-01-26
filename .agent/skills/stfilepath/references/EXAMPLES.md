STFilePath Examples (basic → advanced)

1) Basic: create/read/append/delete

```swift
import STFilePath

let documents = try STFolder.Sanbox.document.url.asSTFolder() // Use Sanbox helper
let folder = try documents.folder("Example").create()
let file = try folder.file("hello.txt").create(with: "Hello".data(using: .utf8)!)
let content = try file.read()
try file.append(data: " world".data(using: .utf8)!)
try file.delete()
```

2) Hashing (SHA256)

```swift
let file = STFile(url)
let sha = try file.hash(with: .sha256)
print(sha)
```

3) Modern Watcher (Async Stream)

```swift
// Watch a folder recursively on macOS
let watcher = folder.watcher() 
let stream = try watcher.streamMonitoring()

Task {
    for try await change in stream {
        print("Changed: \(change.file.url.lastPathComponent) - \(change.kind)")
    }
}

// Watch a single file
let fileWatcher = file.watcher()
let fileStream = fileWatcher.stream()

Task {
    for try await event in fileStream {
        print("File event: \(event.kind) at \(event.path.url)")
    }
}
```

4) Identifying Opening Processes (macOS)

```swift
let apps = file.openingProcesses()
for app in apps {
    print("Process \(app.name) (PID: \(app.pid)) has this file open.")
}
```

5) DownloadableFile + Codable

```swift
struct MyModel: Codable { let name: String; let value: Int }

let df = DFAnyFile(file: STFile(url)).codable(MyModel.self)
Task {
    let model = try await df.fetch()
    var newModel = model
    newModel.value += 1
    try await df.save(newModel)
}
```

Notes
- Use `isExists` instead of deprecated `isExist`.
- Watchers on macOS are powered by `FSEvents` (recursive) or `DispatchSource` (single item).
- Concurrency: Watcher classes are `Sendable` but may use `@unchecked Sendable` for internal backend management.
