
# STFilePath

[![Swift](https://img.shields.io/badge/swift-5.7-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg)](https://developer.apple.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

`STFilePath` 是一个功能强大且易于使用的 Swift 文件系统操作库。它提供了一个现代化的、面向对象的 API，简化了在 macOS 和 iOS 上的文件和文件夹管理。

## 特性

- **流式接口:** 将方法链接在一起，使代码清晰易读。
- **强类型路径:** 使用 `STFile` 和 `STFolder` 进行类型安全的文件和文件夹操作。
- **文件哈希:** 内置支持 SHA256、SHA512、SHA384 和 MD5 文件哈希。
- **文件监视:** 监视文件夹的更改（创建、删除、修改）。
- **异步操作:** 使用 async/await 和流高效地读写大文件。
- **跨平台:** 可在 macOS 和 iOS 上运行。
- **错误处理:** 全面的错误处理和描述性错误消息。
- **可下载文件:** 一种基于协议的方法，用于异步获取、保存和转换文件数据。

## 要求

- Swift 5.7+
- macOS 11.0+
- iOS 14.0+

## 安装

您可以使用 Swift Package Manager 将 `STFilePath` 添加到您的项目中。

在 Xcode 中，转到 `File` > `Add Packages...` 并输入仓库 URL：

```
https://github.com/your-username/STFilePath.git
```

## 使用

### 基本操作

```swift
import STFilePath

// 创建文件夹
let documents = STFolder.documents
let myFolder = try documents.folder(name: "MyFolder").create()

// 创建文件
let myFile = try myFolder.file(name: "hello.txt").create(with: "你好, 世界!".data(using: .utf8))

// 读取文件内容
let content = try myFile.read()
print(content) // "你好, 世界!"

// 追加到文件
try myFile.append(data: " 更多文本.".data(using: .utf8))

// 移动文件
let newFile = try myFile.move(to: myFolder.file(name: "new_hello.txt"))

// 删除文件
try newFile.delete()

// 删除文件夹
try myFolder.delete()
```

### 文件哈希

```swift
import STFilePath
import CryptoKit

let file = STFile("path/to/your/file")
let sha256 = try file.hash(with: .sha256)
print("SHA256: \(sha256)")
```

### 文件夹监视

```swift
import STFilePath

let folder = STFolder("path/to/your/folder")
let watcher = folder.watcher(options: .init(interval: .seconds(1)))

Task {
    do {
        for try await change in try watcher.streamMonitoring() {
            print("文件 \(change.file.name) 已被 \(change.kind)")
        }
    } catch {
        print("监视文件夹时出错: \(error)")
    }
}

try watcher.connect()
watcher.monitoring()
```

### 可下载文件

`DownloadableFile` 是一个协议，允许您使用可以从源（如网络或本地文件）获取然后保存的文件。它支持转换，使您可以轻松地解码、解压缩或以其他方式操作文件数据。

```swift
import STFilePath

struct MyModel: Codable {
    let name: String
    let value: Int
}

// 创建一个可以作为 MyModel 对象获取和保存的文件
let file = DFAnyFile(file: STFile("path/to/your/file.json"))
    .codable(MyModel.self)

Task {
    do {
        // 获取并解码模型
        let model = try await file.fetch()
        print("获取的模型: \(model)")

        // 修改并保存模型
        let newModel = MyModel(name: "new name", value: 2)
        try await file.save(newModel)
    } catch {
        print("错误: \(error)")
    }
}
```

## 许可证

`STFilePath` 在 MIT 许可下可用。有关更多信息，请参阅 [LICENSE](LICENSE) 文件。
