Hashing (CryptoKit)

Search hints
- `rg -n "enum STHasherKind|func hash\\(with kind" Sources/STFilePath`

Use cases
1) 文件完整性校验（下载后校验 hash）
```swift
import STFilePath

let file = STFile("/tmp/download.bin")
let digest = try file.hash(with: .sha256)
print("sha256:", digest)
```

2) 去重/缓存 key（用内容 hash 做缓存键）
```swift
import STFilePath

let file = STFile("/tmp/input.dat")
let key = try file.hash(with: .md5) // 仅用于 key；安全场景请用 sha256+
```

3) 对内存数据直接算 hash（不落盘）
```swift
import STFilePath

let data = Data("hello".utf8)
let digest = try STHasherKind.sha256.hash(with: data)
```

What exists
- Hashing is available when `CryptoKit` can be imported (`#if canImport(CryptoKit)`).
- `STHasherKind` supports: `.sha256`, `.sha384`, `.sha512`, `.md5` (MD5 uses `Insecure.MD5()`).
- `STFile.hash(with kind: STHasherKind) -> String` returns a lowercase hex digest.

Examples

```swift
import STFilePath

let file = STFile("/tmp/data.bin")
let sha256 = try file.hash(with: .sha256)
let md5 = try file.hash(with: .md5)
```

Where to change behavior / add algorithms
- `Sources/STFilePath/STFile+CryptoKit.swift`
- Tests (if you add a new algorithm): add coverage in `Tests/STFilePathTests/STFileTests.swift` or a dedicated test file.
