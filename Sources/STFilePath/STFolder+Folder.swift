// MIT License
//
// Copyright (c) 2020 linhey
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// [en] Represents a folder path and provides folder-specific operations.
/// [zh] 表示文件夹路径并提供文件夹特定的操作。
public struct STFolder: STPathProtocol {
    
    /// [en] The type of the file system item, which is always `.folder`.
    /// [zh] 文件系统项的类型，始终为 `.folder`。
    public let type: STFilePathItemType = .folder
    /// [en] The URL of the folder.
    /// [zh] 文件夹的 URL。
    public let url: URL
    
    /// [en] Initializes a new `STFolder` instance with the specified URL.
    /// [zh] 使用指定的 URL 初始化一个新的 `STFolder` 实例。
    /// - Parameter url: The URL of the folder.
    public init(_ url: URL) {
        self.url = url.standardized
    }
        
    /// [en] Initializes a new `STFolder` instance with the specified path string.
    /// [zh] 使用指定的路径字符串初始化一个新的 `STFolder` 实例。
    /// - Parameter path: The path string.
    public init(_ path: String) {
        self.init(Self.standardizedPath(path))
    }
    
    /// [en] Initializes a new `STFolder` instance from a decoder.
    /// [zh] 从解码器初始化一个新的 `STFolder` 实例。
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.url = try container.decode(URL.self)
    }
    
    /// [en] Encodes this `STFolder` instance into the given encoder.
    /// [zh] 将此 `STFolder` 实例编码到给定的编码器中。
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.url)
    }
    
}

public extension STFolder {
    
    /// [en] Returns a path for a sub-item in the current folder (without checking for existence).
    /// [zh] 返回当前文件夹中子项的路径（不检查是否存在）。
    /// - Parameter name: The name of the sub-item.
    /// - Returns: An `STPath` instance for the sub-item.
    func subpath(_ name: String) -> STPath {
        STPath(url.appendingPathComponent(name))
    }
    
    /// [en] Returns a file path in the current folder (without checking for existence).
    /// [zh] 返回当前文件夹中的文件路径（不检查是否存在）。
    /// - Parameter name: The name of the file.
    /// - Returns: An `STFile` instance for the file.
    func file(_ name: String) -> STFile {
        STFile(url.appendingPathComponent(name, isDirectory: false))
    }
    
    /// [en] Returns a folder path in the current folder (without checking for existence).
    /// [zh] 返回当前文件夹中的文件夹路径（不检查是否存在）。
    /// - Parameter name: The name of the folder.
    /// - Returns: An `STFolder` instance for the folder.
    func folder(_ name: String) -> STFolder {
        var name = name
        if name.hasPrefix("/") {
            name.removeFirst()
        }
        return STFolder(url.appendingPathComponent(name, isDirectory: true))
    }
    
    /// [en] Returns a path for a sub-item in the current folder if it exists.
    /// [zh] 如果当前文件夹中的子项存在，则返回其路径。
    /// - Parameter name: The name of the sub-item.
    /// - Returns: An `STPath` instance if the sub-item exists, otherwise `nil`.
    func subpathIfExist(name: String) -> STPath? {
        let item = subpath(name)
        return item.isExist ? item : nil
    }
    
    /// [en] Returns a file path in the current folder if it exists.
    /// [zh] 如果当前文件夹中的文件存在，则返回其文件路径。
    /// - Parameter name: The name of the file.
    /// - Returns: An `STFile` instance if the file exists, otherwise `nil`.
    func fileIfExist(name: String) -> STFile? {
        let item = file(name)
        return item.isExist ? item : nil
    }
    
    /// [en] Returns a folder path in the current folder if it exists.
    /// [zh] 如果当前文件夹中的文件夹存在，则返回其文件夹路径。
    /// - Parameter name: The name of the folder.
    /// - Returns: An `STFolder` instance if the folder exists, otherwise `nil`.
    func folderIfExist(name: String) -> STFolder? {
        let item = folder(name)
        return item.isExist ? item : nil
    }
    
    /// [en] Opens a file in the current folder. If the file does not exist, it creates an empty file.
    /// [zh] 打开当前文件夹中的文件。如果文件不存在，则创建一个空文件。
    /// - Parameter name: The name of the file.
    /// - Returns: An `STFile` instance for the file.
    /// - Throws: An error if the file cannot be created.
    func open(name: String) throws -> STFile {
        let file = STFile(url.appendingPathComponent(name, isDirectory: false))
        if file.isExist {
            return file
        } else {
            try create(file: name)
        }
        return file
    }
    
}


public extension STFolder {
    
    /// [en] Creates the folder.
    /// [zh] 创建文件夹。
    /// - Returns: The `STFolder` instance.
    /// - Throws: An error if the folder cannot be created.
    @discardableResult
    func create() throws -> STFolder {
        try manager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return self
    }
    
    /// [en] Creates the folder if it does not already exist.
    /// [zh] 如果文件夹不存在，则创建该文件夹。
    /// - Returns: The `STFolder` instance.
    func createIfNotExists() -> STFolder {
        _ = try? create()
        return self
    }
    
    /// [en] Creates a file in the current folder.
    /// [zh] 在当前文件夹中创建一个文件。
    /// - Parameters:
    ///   - name: The name of the file.
    ///   - data: The initial data to write to the file.
    /// - Returns: The `STFile` instance for the created file.
    /// - Throws: An error if the file cannot be created.
    @discardableResult
    func create(file name: String, data: Data? = nil) throws -> STFile {
        return try STFile(url.appendingPathComponent(name, isDirectory: false)).create(with: data)
    }
    
    /// [en] Creates a subfolder in the current folder.
    /// [zh] 在当前文件夹中创建一个子文件夹。
    /// - Parameter name: The name of the subfolder.
    /// - Returns: The `STFolder` instance for the created subfolder.
    /// - Throws: An error if the subfolder cannot be created.
    @discardableResult
    func create(folder name: String) throws -> STFolder {
        return try STFolder(url.appendingPathComponent(name, isDirectory: true)).create()
    }
    
}
