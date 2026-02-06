STFilePath 函数教程（Cookbook，面向“直接写代码”）

Use cases
1) “写一个工具脚本做文件/目录操作”：直接看「2) STFile」+「3) STFolder」+「4) 搜索与枚举」
2) “做热更新/监听文件变化”：直接看「5) Watchers」并按建议加 timeout
3) “把 Codable 配置落盘并自动保存”：直接看「9) DownloadableFile」

目标：让你在不翻源码的情况下，能直接用 STFilePath 写出正确代码（包含常见坑与推荐写法）。

快速索引（按任务）
- 路径/对象创建：见「1. Path / File / Folder 创建」
- 文件 CRUD：见「2. STFile 常用函数」
- 文件夹操作与构建子路径：见「3. STFolder 常用函数」
- 递归查找/枚举：见「4. 搜索与枚举（STFolder+Search）」  
- 监听（watch）：见「5. Watchers（文件/文件夹/路径）」  
- 哈希：见「6. Hash（CryptoKit）」  
- 元数据/权限/xattr/软链接：见「7. Metadata / Permission / Xattr / Symlink」  
- JSON Lines：见「8. JSON Lines（JSONL）」  
- DownloadableFile：见「9. DownloadableFile（异步 fetch/save 管道）」  
- 压缩：见「10. Compression」  
- mmap / Darwin：见「11. MMAP & Darwin」  
- iOS/macOS 集成：见「12. Integrations」  
- 缓存与 UserDefaults：见「13. Caching & UserDefaults」  

说明
- 这里的“函数签名/行为”以当前仓库源码为准；如遇升级，优先更新本文件而不是让读者去翻源码。

---

## 1) Path / File / Folder 创建

### 1.1 用字符串创建

```swift
let file = STFile("/tmp/a.txt")
let folder = STFolder("/tmp/dir")
let path = STPath("/tmp")
```

特点
- `STPathProtocol.standardizedPath(_:)` 支持 `~` / `~/` 展开，以及 `file://...` URL。

### 1.2 用 URL 创建

```swift
let file = STFile(url)
let folder = STFolder(url)
let path = STPath(url)
```

### 1.3 沙盒/容器目录（Apple 平台）

```swift
let documents = try STFolder(sanbox: .document)
let temp = try STFolder(sanbox: .temporary)
let cache = try STFolder(sanbox: .cache)
```

常见坑
- 类型名是 `Sanbox`（拼写如此），构造器是 `STFolder(sanbox:)`。

---

## 2) STFile 常用函数（文件读写）

### 2.1 创建

```swift
try file.create(with: Data("hi".utf8))          // 若已存在会抛错
try file.createIfNotExists(with: Data("hi".utf8)) // 若存在则直接返回自身
```

建议
- 业务里通常用 `createIfNotExists`，避免“文件已存在”异常导致流程中断。

### 2.2 读（String）

```swift
let text: String = try file.read()
let text2 = try file.read([], encoding: .utf8)
```

说明
- `read()` 返回 `String`（不是 `Data`）。

### 2.3 读（Data）

```swift
let bytes: Data = try file.data()
```

### 2.4 写（覆盖）

```swift
try file.write(Data("new".utf8))
```

### 2.5 追加（append）

```swift
try file.append(data: Data("more".utf8))
```

行为
- 如果文件不存在，会先创建再写入。

### 2.6 覆盖（overlay）

常见写法（String / Data / Codable）

```swift
try file.overlay(with: "hello")       // String?
try file.overlay(with: Data("x".utf8)) // Data?
try file.overlay(model: model)         // Encodable -> JSON
```

适用场景
- “原子式更新配置文件/缓存文件”：先生成新内容，再覆盖写入。

### 2.7 移动/复制/替换

```swift
let moved = try file.move(to: otherFile)
let copied = try file.copy(to: otherFile)
try file.replace(otherFile) // 目标存在则先删再 copy
```

---

## 3) STFolder 常用函数（文件夹与子路径构建）

### 3.1 创建文件夹

```swift
try folder.create()
folder.createIfNotExists()
```

### 3.2 构建子路径（不检查存在）

```swift
let childFile = folder.file("a.txt")
let childFolder = folder.folder("subdir")
let childPath = folder.subpath("any")
```

说明
- `file(_:)`/`folder(_:)` 只是拼接路径，不会自动创建。

### 3.3 在 folder 内创建文件/文件夹

```swift
let f = try folder.create(file: "a.txt", data: Data("hi".utf8))
let d = try folder.create(folder: "sub")
```

### 3.4 open（不存在则创建空文件）

```swift
let f = try folder.open(name: "maybe.txt")
```

---

## 4) 搜索与枚举（STFolder+Search）

### 4.1 非递归枚举

```swift
let paths: [STPath] = try folder.subFilePaths()
let files: [STFile] = try folder.files()
let folders: [STFolder] = try folder.folders()
```

### 4.2 递归枚举

```swift
let all: [STPath] = try folder.allSubFilePaths()
```

### 4.3 带过滤的递归文件扫描（推荐）

```swift
let result: [STFile] = try folder.files(
    matching: { file in file.url.pathExtension == "json" },
    in: { subfolder in true }
)
```

---

## 5) Watchers（文件/文件夹/路径）

核心原则
- 永远给等待事件加 timeout，避免测试/业务挂起。
- 先启动消费 stream（或至少启动后台消费 Task），再触发文件系统变更；否则可能错过事件。
- macOS 文件夹 watch 多为 FSEvents，事件可能合并/延迟；delete 不一定表现为 `.deleted`（可能仅能观察到 `.changed`）。

### 5.1 File watcher（单文件）

```swift
let watcher = file.watcher()
let stream = watcher.stream() // AsyncThrowingStream<STPathChanged, Error>

Task {
  for try await ev in stream {
    print(ev.kind, ev.path.url.path)
  }
}

// ... later
watcher.stop()
```

### 5.2 Folder watcher（文件夹）

```swift
let watcher = folder.watcher(options: .init(interval: .milliseconds(200)))
let stream = try watcher.streamMonitoring() // AsyncThrowingStream<STFolderWatcher.Changed, Error>

Task {
  for try await ev in stream {
    print(ev.kind, ev.file.url.path)
  }
}

watcher.stopMonitoring()
```

### 5.3 Path watcher（统一入口）

```swift
let watcher = STPathWatcher(path: STPath("/tmp"))
Task { for try await ev in watcher.stream() { print(ev) } }
watcher.stop()
```

---

## 6) Hash（CryptoKit）

```swift
let sha = try file.hash(with: .sha256) // String hex
let md5 = try file.hash(with: .md5)
```

注意
- 受 `#if canImport(CryptoKit)` 影响；某些平台/环境可能不可用。

---

## 7) Metadata / Permission / Xattr / Symlink

### 7.1 attributes（元数据）

```swift
let attrs = file.attributes
print(attrs.modificationDate, attrs.size)
```

### 7.2 permission（快速权限判断）

```swift
let p = file.permission
if p.contains(.readable) { /* ... */ }
```

### 7.3 POSIX 权限（读写执行位）

```swift
let posix = try file.permissions()
try file.set(permissions: .default)
```

### 7.4 xattr（扩展属性，Darwin）

```swift
try file.extendedAttributes.set(name: "com.example.tag", value: Data("v".utf8))
let v = try file.extendedAttributes.value(of: "com.example.tag")
try file.extendedAttributes.remove(of: "com.example.tag")
```

### 7.5 软链接

```swift
let link = STPath("/tmp/link")
try link.createSymbolicLink(to: file)
let dest = try link.destinationOfSymbolicLink()
```

### 7.6 security-scoped（iOS/macOS 用户选择文件）

```swift
try file.startAccessingSecurityScopedResource()
defer { file.stopAccessingSecurityScopedResource() }
```

---

## 8) JSON Lines（JSONL）

写入（逐行 JSON）

```swift
struct Row: Codable { let id: Int }
let writer = try file.lineFile.newLineWriter
try writer.append(model: Row(id: 1))
try writer.append(model: Row(id: 2))
```

读取

```swift
let rows: [Row] = try file.lineFile.lines(as: Row.self)
```

---

## 9) DownloadableFile（异步 fetch/save）

### 9.1 把 STFile 当成 “Data 文件”

```swift
let df = file.toDFAnyFile() // DFAnyFile<Data>
let data = try await df.fetch()
try await df.save(data)
```

### 9.2 Codable 映射（推荐）

```swift
struct Model: Codable, Sendable { var a: Int }
let df = file.toDFAnyFile().codable(Model.self)
let model = try await df.fetch()
try await df.save(model)
```

### 9.3 currentValueFile（写入合并/最后一次胜出）

```swift
let f = file.toDFAnyFile().codable([String: Int].self).currentValueFile([:])
_ = try await f.fetch()
f.value?["k"] = 1 // 会触发异步保存（内部 cancel 上一次 save）
```

---

## 10) Compression

直接压缩/解压

```swift
let compressed = try STComparator.compress(data, algorithm: .lzfse)
let raw = try STComparator.decompress(compressed, algorithm: .lzfse)
```

与 DownloadableFile 结合（`Model == Data`）

```swift
let df = file.toDFAnyFile().compression(.lzfse)
let raw = try await df.fetch()     // 自动解压
try await df.save(raw + [1,2,3])   // 自动压缩写回
```

---

## 11) MMAP & Darwin

### 11.1 mmap（Darwin）

```swift
try file.withMmap { mmap in
  let data = mmap.read()
  try mmap.write(Data([0x01, 0x02]), at: 0)
  mmap.sync()
}
```

约束
- 映射大小不能超过文件大小；需要先 `file.setSize(newSize)` 扩容。

### 11.2 Darwin 低层 open/stat/truncate/sync

```swift
let fd = try file.system.open(flag1: .readAndWrite, flag2: nil, mode: nil)
defer { Darwin.close(fd) }
try file.system.sync(descriptor: fd)
```

---

## 12) Integrations（iOS/macOS）

### 12.1 iOS DocumentPicker（iOS 14+）

要点：`STDocumentPicker` 回调给你 `[STPath]`，通常用于用户选择文件后读写。

### 12.2 iOS QuickLook

`STPathQuickLookController` 可预览一个或多个 `STPathProtocol`。

### 12.3 macOS Finder + 关联应用

- `path.showInFinder()`
- `STFolder.selectInFinder(...)`
- `file.associatedApplications` + `file.open(with:)`

---

## 13) Caching & UserDefaults

### 13.1 STKVCache（带过期与落盘）

```swift
let cache = STKVCache<String, Int>()
cache.insert(1, forKey: "a", lifeTime: 60)
let v = cache["a"]
```

落盘（Key/Value 需 Codable）

```swift
try cache.saveToDisk(with: STFile("/tmp/cache.json"))
let restored = try STKVCache<String, Int>.decode(from: STFile("/tmp/cache.json"))
```

### 13.2 @STUserDefaults

```swift
struct Settings {
  @STUserDefaults("enabled", default: false) var enabled: Bool
  @STUserDefaults("recent", default: []) var recent: [Int]
}
```
