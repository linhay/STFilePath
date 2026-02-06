Caching (STKVCache) and UserDefaults helpers (STUserDefaults)

Search hints
- Cache: `rg -n "final class STKVCache" Sources/STFilePath/Surroundings/STKVCache.swift`
- UserDefaults wrapper: `rg -n "propertyWrapper\\s+public struct STUserDefaults" Sources/STFilePath/Surroundings/STUserDefaults.swift`

Use cases
1) 解析结果缓存（避免重复 JSON decode）
```swift
import Foundation
import STFilePath

let cache = STKVCache<String, Any>()
// 业务建议：定义明确的 Value 类型（这里仅展示用法）
```

2) Codable cache 落盘（重启恢复）
```swift
import Foundation
import STFilePath

let file = STFile("/tmp/cache.json")
try file.createIfNotExists(with: Data("[]".utf8))

let cache = STKVCache<String, Int>()
cache["a"] = 1
try cache.saveToDisk(with: file)

let restored = try STKVCache<String, Int>.decode(from: file)
_ = restored["a"]
```

3) 用户偏好（UserDefaults property wrapper）
```swift
import STFilePath

struct Settings {
    @STUserDefaults("enabled", default: false) var enabled: Bool
    @STUserDefaults("recentIDs", default: []) var recentIDs: [Int]
}
```

STKVCache
- In-memory cache built on `NSCache` with optional expiration.
- Codable support when `Key` and `Value` are Codable:
  - Can encode/decode the cache contents.
  - Can persist to disk using `saveToDisk(with:)` / `decode(from:)` with an `STFile`.

Example (basic)

```swift
import STFilePath

let cache = STKVCache<String, Int>()
cache.insert(1, forKey: "a", lifeTime: 60)
let v = cache.value(of: "a")
```

Example (persist to disk)

```swift
import Foundation
import STFilePath

let file = STFile("/tmp/cache.json")
try file.createIfNotExists(with: Data("[]".utf8))

let cache = STKVCache<String, Int>()
cache["a"] = 1
try cache.saveToDisk(with: file)

let restored = try STKVCache<String, Int>.decode(from: file)
```

STUserDefaults
- `@STUserDefaults(key, default: ...)` property wrapper with typed values.
- Supported out of the box:
  - `String`, `Int`, `Bool`, `Float`, `Double`, `URL`, `UUID`, `Data`
  - `Optional<Wrapped>` where `Wrapped: STUserDefaultsValue`
  - `Array<Element>` where `Element: Codable` (stored as binary plist)

Example

```swift
import STFilePath

struct Settings {
    @STUserDefaults("enabled", default: false) var enabled: Bool
    @STUserDefaults("recentIDs", default: []) var recentIDs: [Int]
}
```

Where to change behavior
- Cache: `Sources/STFilePath/Surroundings/STKVCache.swift`
- UserDefaults wrapper: `Sources/STFilePath/Surroundings/STUserDefaults.swift`
