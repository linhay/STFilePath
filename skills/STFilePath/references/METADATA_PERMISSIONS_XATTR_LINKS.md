Metadata, permissions, extended attributes, links, security-scoped resources

Search hints
- Attributes: `rg -n "class STPathAttributes" Sources/STFilePath`
- Permissions: `rg -n "struct STPathPermission|func permissions\\(\\)|set\\(permissions" Sources/STFilePath`
- Xattrs: `rg -n "ExtendedAttributes|setxattr|getxattr|listxattr" Sources/STFilePath`
- Symlinks: `rg -n "isSymbolicLink|createSymbolicLink|destinationOfSymbolicLink" Sources/STFilePath`
- Security-scoped: `rg -n "startAccessingSecurityScopedResource|stopAccessingSecurityScopedResource" Sources/STFilePath`

Use cases
1) 给脚本文件加可执行权限（POSIX）
```swift
import STFilePath

let script = STFile("/tmp/run.sh")
try script.createIfNotExists(with: Data("#!/bin/sh\necho hi\n".utf8))
try script.set(permissions: .default)
```

2) 用 xattr 给文件打标签（Darwin）
```swift
import Foundation
import STFilePath

let file = STFile("/tmp/a.txt")
try file.createIfNotExists(with: Data("x".utf8))
try file.extendedAttributes.set(name: "com.example.tag", value: Data("blue".utf8))
```

3) 用 symlink 做“current”指针（例如当前版本目录）
```swift
import STFilePath

let current = STPath("/tmp/current")
let v2 = STFolder("/tmp/app/v2")
try current.delete() // 若存在旧链接/旧文件（可选）
try current.createSymbolicLink(to: v2)
```

File attributes
- `STPathProtocol.attributes -> STPathAttributes`
- Includes common properties (name, size, timestamps, etc.) plus a large surface mirroring `FileAttributeKey`.

Permissions (two layers)
1) Quick “can I?” permissions:
- `STPathProtocol.permission -> STPathPermission` with flags:
  - `.exists`, `.readable`, `.writable`, `.executable`, `.deletable`

2) POSIX permission bits:
- `STPathPermission.Posix` option set.
- `STPathProtocol.permissions() throws -> STPathPermission.Posix`
- `STPathProtocol.set(permissions:) throws`

Extended attributes (xattr)
- Darwin-only implementation.
- API is via `STPathProtocol.extendedAttributes`:
  - `set(name:value:)`, `value(of:)`, `remove(of:)`, `list()`

Symlinks
- `isSymbolicLink: Bool`
- `createSymbolicLink(to destination: any STPathProtocol)`
- `destinationOfSymbolicLink() throws -> STPath`

Security-scoped resources (Apple platforms)
- `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`
- Use around reads/writes for user-picked files (e.g., UIDocumentPicker).

Where to change behavior
- `Sources/STFilePath/STPathAttributes.swift`
- `Sources/STFilePath/STPathPermission.swift`
- `Sources/STFilePath/STPath+Metadata.swift`
- `Sources/STFilePath/STPath+Link.swift`
- Tests: `Tests/STFilePathTests/STPath+MetadataTests.swift`, `Tests/STFilePathTests/STPath+LinkTests.swift`
