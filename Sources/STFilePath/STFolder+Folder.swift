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

public struct STFolder: STPathProtocol {
    
    public let type: STFilePathItemType = .folder
    public let url: URL
    
    public init(_ url: URL) {
        self.url = url.standardized
    }
        
    public init(_ path: String) {
        self.init(Self.standardizedPath(path))
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.url = try container.decode(URL.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.url)
    }
    
}

public extension STFolder {
    
    /// 当前文件夹下的路径 (不校验存在性)
    /// - Parameter name: 文件名
    /// - Returns: STFile
    func subpath(_ name: String) -> STPath {
        STPath(url.appendingPathComponent(name))
    }
    
    /// 当前文件夹下的文件 (不校验存在性)
    /// - Parameter name: 文件名
    /// - Returns: STFile
    func file(_ name: String) -> STFile {
        STFile(url.appendingPathComponent(name, isDirectory: false))
    }
    
    /// 当前文件夹下的文件夹 (不校验存在性)
    /// - Parameter name: 文件夹名
    /// - Returns: STFile
    func folder(_ name: String) -> STFolder {
        STFolder(url.appendingPathComponent(name, isDirectory: true))
    }
    
    /// 当前文件夹下的路径 (校验存在性)
    /// - Parameter name: 文件名
    /// - Returns: STFile
    func subpathIfExist(name: String) -> STPath? {
        let item = subpath(name)
        return item.isExist ? item : nil
    }
    
    /// 当前文件夹下的文件 (校验存在性)
    /// - Parameter name: 文件名
    /// - Returns: STFile
    func fileIfExist(name: String) -> STFile? {
        let item = file(name)
        return item.isExist ? item : nil
    }
    
    /// 当前文件夹下的文件夹 (校验存在性)
    /// - Parameter name: 文件夹名
    /// - Returns: STFile
    func folderIfExist(name: String) -> STFolder? {
        let item = folder(name)
        return item.isExist ? item : nil
    }
    
    /// 当前文件夹下存在的文件 (不存在则创建空白文件)
    /// - Parameter name: 文件名
    /// - Returns: STFile
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
    
    /// 根据当前[FilePath]文件夹
    /// - Throws: FilePathError - 文件夹 存在, 无法创建
    @discardableResult
    func create() throws -> STFolder {
        try manager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return self
    }
    
    func createIfNotExists() -> STFolder {
        _ = try? create()
        return self
    }
    
    @discardableResult
    func create(file name: String, data: Data? = nil) throws -> STFile {
        return try STFile(url.appendingPathComponent(name, isDirectory: false)).create(with: data)
    }
    
    /// 在当前路径下创建文件夹
    /// - Parameter name: 文件夹名
    /// - Throws: FileManager error
    /// - Returns: 创建文件夹的 FilePath
    @discardableResult
    func create(folder name: String) throws -> STFolder {
        return try STFolder(url.appendingPathComponent(name, isDirectory: true)).create()
    }
    
}
