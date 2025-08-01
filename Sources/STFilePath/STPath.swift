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

public struct STPath: STPathProtocol, Codable {
    
    /// [en] A unique identifier for the path.
    /// [zh] 路径的唯一标识符。
    public var id: URL { url }
    
    /// [en] The default file manager.
    /// [zh] 默认的文件管理器。
    private var manager: FileManager { FileManager.default }
    
    /// [en] The type of the file system item at the path.
    /// [zh] 路径上文件系统项的类型。
    public var type: STFilePathItemType {
        guard isExist else {
            return .notExist
        }
        if isExistFolder {
            return .folder
        }
        if isExistFile {
            return .file
        }
        
        return .notExist
    }
    
    /// [en] The reference type of the file system item.
    /// [zh] 文件系统项的引用类型。
    public var referenceType: STFilePathReferenceType? {
        switch type {
        case .file:
            return .file(.init(url))
        case .folder:
            return .folder(.init(url))
        case .notExist:
            return nil
        }
    }
    
    /// [en] The URL of the path.
    /// [zh] 路径的 URL。
    public var url: URL
    
    /// [en] Initializes a new `STPath` instance with the specified URL.
    /// [zh] 使用指定的 URL 初始化一个新的 `STPath` 实例。
    /// - Parameter url: The URL of the path.
    public init(_ url: URL) {
        self.url = url.standardized
    }
    
    /// [en] Initializes a new `STPath` instance with the specified path string.
    /// [zh] 使用指定的路径字符串初始化一个新的 `STPath` 实例。
    /// - Parameter path: The path string.
    public init(_ path: String) {
        self.init(Self.standardizedPath(path))
    }
    
    /// [en] Initializes a new `STPath` instance from a decoder.
    /// [zh] 从解码器初始化一个新的 `STPath` 实例。
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.url = try container.decode(URL.self)
    }
    
    /// [en] Encodes this `STPath` instance into the given encoder.
    /// [zh] 将此 `STPath` 实例编码到给定的编码器中。
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.url)
    }
    
}
