MMAP and Darwin-specific file operations

Search hints
- `rg -n "withMmap|class STFileMMAP|setSize\\(" Sources/STFilePath/STFile\\+MMAP.swift`
- `rg -n "struct STFileSystem|func open\\(|func truncate\\(|func sync\\(" Sources/STFilePath/STFile\\+Darwin.swift`

Use cases
1) 大文件局部修改（避免一次性读入内存）
```swift
import STFilePath

let file = STFile("/tmp/large.bin")
try file.createIfNotExists(with: Data(repeating: 0, count: 1024 * 1024))

try file.withMmap { mmap in
    try mmap.write(Data([0x01, 0x02, 0x03]), at: 128)
    mmap.sync()
}
```

2) 先扩容再 mmap（映射大小不能超过文件大小）
```swift
import STFilePath

let file = STFile("/tmp/grow.bin")
try file.createIfNotExists(with: Data(repeating: 0, count: 16))
try file.setSize(1024)
try file.withMmap { _ in }
```

3) 以类型安全方式操作 buffer（例如逐字节修改）
```swift
import STFilePath

let file = STFile("/tmp/buf.bin")
try file.createIfNotExists(with: Data(repeating: 0, count: 64))
try file.withMmap { mmap in
    try mmap.withUnsafeMutableBufferPointer(as: UInt8.self) { buf in
        buf[0] = 0xFF
    }
    mmap.sync()
}
```

Memory mapping (Darwin only)
- API: `STFile.withMmap(prot:shareType:size:offset:_:)`
  - Ensures `close()` is called via `defer`.
- `STFile.setSize(_:)` truncates/expands the file using `ftruncate`.
- `STFileMMAP` supports:
  - `read(range:) -> Data`
  - `write(_:at:)`
  - `sync()`
  - `withUnsafeMutableBufferPointer(as:_:)`

Important constraints
- Mapping size must be > 0.
- Mapping size cannot exceed file size; call `file.setSize(newSize)` first to grow.

Darwin file APIs
- `STFile.system -> STFileSystem` exposes:
  - `open(flag1:flag2:mode:) -> Int32`
  - `stat(descriptor:) -> Darwin.stat`
  - `truncate(descriptor:size:)`
  - `sync(descriptor:)`
  - plus open flags/modes helpers

Where to change behavior
- `Sources/STFilePath/STFile+MMAP.swift`
- `Sources/STFilePath/STFile+Darwin.swift`
- Tests: `Tests/STFilePathTests/STFileMMAPTests.swift`
