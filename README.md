
# STFilePath

[![Swift](https://img.shields.io/badge/swift-5.7-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg)](https://developer.apple.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

`STFilePath` is a powerful and easy-to-use Swift library for file system operations. It provides a modern, object-oriented API that simplifies file and folder management on macOS and iOS.

## Features

- **Fluent Interface:** Chain methods together for clean and readable code.
- **Strongly Typed Paths:** Use `STFile` and `STFolder` for type-safe file and folder operations.
- **File Hashing:** Built-in support for SHA256, SHA512, SHA384, and MD5 file hashing.
- **File Watching:** Monitor folders for changes (creations, deletions, modifications).
- **Asynchronous Operations:** Read and write large files efficiently with async/await and streams.
- **Cross-Platform:** Works on both macOS and iOS.
- **Error Handling:** Comprehensive error handling with descriptive error messages.
- **Downloadable Files:** A protocol-based approach for fetching, saving, and transforming file data asynchronously.

## Requirements

- Swift 5.7+
- macOS 11.0+
- iOS 14.0+

## Installation

You can add `STFilePath` to your project using Swift Package Manager.

In Xcode, go to `File` > `Add Packages...` and enter the repository URL:

```
https://github.com/your-username/STFilePath.git
```

## Usage

### Basic Operations

```swift
import STFilePath

// Create a folder
let documents = STFolder.documents
let myFolder = try documents.folder(name: "MyFolder").create()

// Create a file
let myFile = try myFolder.file(name: "hello.txt").create(with: "Hello, World!".data(using: .utf8))

// Read file content
let content = try myFile.read()
print(content) // "Hello, World!"

// Append to file
try myFile.append(data: " More text.".data(using: .utf8))

// Move file
let newFile = try myFile.move(to: myFolder.file(name: "new_hello.txt"))

// Delete file
try newFile.delete()

// Delete folder
try myFolder.delete()
```

### Skill

This repo includes a Codex skill for STFilePath under `skills/STFilePath`.
It contains reference docs and scripts for working on this library.

### File Hashing

```swift
import STFilePath
import CryptoKit

let file = STFile("path/to/your/file")
let sha256 = try file.hash(with: .sha256)
print("SHA256: \(sha256)")
```

### Folder Watcher

```swift
import STFilePath

let folder = STFolder("path/to/your/folder")
let watcher = folder.watcher(options: .init(interval: .seconds(1)))

Task {
    do {
        for try await change in try watcher.streamMonitoring() {
            print("File \(change.file.name) was \(change.kind)")
        }
    } catch {
        print("Error watching folder: \(error)")
    }
}

try watcher.connect()
watcher.monitoring()
```

### Downloadable Files

`DownloadableFile` is a protocol that allows you to work with files that can be fetched from a source (like a network or a local file) and then saved back. It supports transformations, allowing you to easily decode, decompress, or otherwise manipulate file data.

```swift
import STFilePath

struct MyModel: Codable {
    let name: String
    let value: Int
}

// Create a file that can be fetched and saved as a MyModel object
let file = DFAnyFile(file: STFile("path/to/your/file.json"))
    .codable(MyModel.self)

Task {
    do {
        // Fetch and decode the model
        let model = try await file.fetch()
        print("Fetched model: \(model)")

        // Modify and save the model
        let newModel = MyModel(name: "new name", value: 2)
        try await file.save(newModel)
    } catch {
        print("Error: \(error)")
    }
}
```

### Memory Mapping (mmap)

`STFile` supports scoped memory mapping for fast reads/writes.

```swift
import STFilePath

let file = STFile("path/to/data.bin")
try file.setSize(4096)

try file.withMmap { mmap in
    let data = mmap.read()
    print("bytes:", data.count)
    try mmap.write(Data([0x01, 0x02, 0x03]), at: 0)
    mmap.sync()
}
```

Notes:
- `offset` must be page-aligned (e.g. `getpagesize()`).
- Mapping size must be greater than 0 and within file bounds.
- If `size` is `nil`, the mapping size is `fileSize - offset`.
- Use `.share` to write back to disk, `.private` for copy-on-write.
- `MAP_SHARED` mappings can observe external process writes once they are flushed (platform behavior applies).

## License

`STFilePath` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
