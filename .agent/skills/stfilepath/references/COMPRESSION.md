Compression (Compression framework) and integration with DownloadableFile

Search hints
- `rg -n "struct STComparator|enum Algorithm|compress\\(|decompress\\(" Sources/STFilePath/Compression/STComparator.swift`
- `rg -n "func compression\\(" Sources/STFilePath/DownloadableFile/DownloadableFile.swift`

Use cases
1) 压缩缓存文件（落盘小、读取时自动解压）
```swift
import STFilePath

let file = STFile("/tmp/cache.bin")
try file.createIfNotExists(with: Data([1,2,3,4]))

let compressed = file.toDFAnyFile().compression(.lzfse)
Task {
    let raw = try await compressed.fetch()
    try await compressed.save(raw + [5,6,7])
}
```

2) 传输前压缩 Data（或写入磁盘前压缩）
```swift
import STFilePath

let data = Data("hello".utf8)
let zipped = try STComparator.compress(data, algorithm: .zlib)
```

3) 读取后解压（对已有压缩数据做反解）
```swift
import STFilePath

let zipped = Data(...) // 已压缩数据
let raw = try STComparator.decompress(zipped, algorithm: .zlib)
```

What exists
- Compression code is behind `#if canImport(Compression)`.
- `STComparator.Algorithm`: `lz4`, `zlib`, `lzma`, `lzfse`.
- `STComparator.compress(_:, algorithm:)` and `.decompress(_:, algorithm:)` operate on `Data`.

DownloadableFile integration (when `Model == Data`)
- `DownloadableFile.compression(_ algorithm:) -> DFFileMap<Self, Data>`
  - Note: This helper wraps the underlying file as a mapped view that decompresses on fetch and compresses on save.

Example

```swift
import STFilePath

let raw = STFile("/tmp/raw.bin")
try raw.createIfNotExists(with: Data([1,2,3]))

let compressed = raw.toDFAnyFile().compression(.lzfse)
Task {
    let data = try await compressed.fetch()
    try await compressed.save(data + [4,5])
}
```

Where to change behavior
- Core compression: `Sources/STFilePath/Compression/STComparator.swift`
- DownloadableFile helper: `Sources/STFilePath/DownloadableFile/DownloadableFile.swift`
