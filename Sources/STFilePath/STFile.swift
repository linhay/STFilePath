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

public struct STFile: STPathProtocol, Codable {
    
    public var type: STFilePathItemType = .file
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

public extension STFile {
    
    @discardableResult
    func move(to file: STFile) throws -> STFile {
        try manager.moveItem(at: url, to: file.url)
        return file
    }
    
    /// 替换目标文件夹中指定文件
    /// - Parameter file: 指定文件路径
    /// - Throws: FileManagerError
    func replace(_ file: STFile) throws {
        if file.isExist {
            try file.delete()
        }
        try self.copy(to: file)
    }
    
    /// 复制至目标文件夹
    /// - Parameter file: 指定文件路径
    /// - Throws: FileManagerError
    @discardableResult
    func copy(to file: STFile) throws -> STFile {
        try manager.copyItem(at: url, to: file.url)
        return file
    }
    
}

public extension STFile {
    
    func read(_ options: Data.ReadingOptions = [], encoding: String.Encoding = .utf8) throws -> String {
        String(data: try data(options: options), encoding: encoding) ?? ""
    }
    
    func write(_ data: Data) throws {
        try data.write(to: url)
    }
    
}

public extension STFile {
    
    /// 文件数据
    /// - Throws: Data error
    /// - Returns: data
    func data(options: Data.ReadingOptions = []) throws -> Data {
        try Data(contentsOf: url, options: options)
    }
    
    func decode<T>(_ tranformed: (_ data: Data) throws -> T) throws -> T {
        try tranformed(try Data(contentsOf: url, options: []))
    }
    
    @available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
    func data(range: ClosedRange<Int>) throws -> Data? {
        guard self.isExist else {
            return nil
        }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        // 计算要读取的数据的大小
        let length = range.upperBound - range.lowerBound + 1
        // 移动到文件的开始位置
        handle.seek(toFileOffset: UInt64(range.lowerBound))
        // 读取指定范围的数据
        let data = handle.readData(ofLength: length)
        return data.isEmpty ? nil : data
    }
    
    func createIfNotExists(with data: Data? = nil) throws -> STFile {
        if isExist {
            return self
        } else {
            return try create(with: data)
        }
    }
    
    /// 根据当前[FilePath]创建文件/文件夹
    /// - Throws: FilePathError - 文件/文件夹 存在, 无法创建
    @discardableResult
    func create(with data: Data? = nil) throws -> STFile {
        if isExist {
            throw STPathError(message: "文件存在, 无法创建: \(url.path)")
        }
        try STFolder(url.deletingLastPathComponent()).create()
        manager.createFile(atPath: url.path, contents: data, attributes: nil)
        return self
    }
    
    /// 追加数据到文件末尾(文件不存在则会创建文件)
    /// - Parameter data: 数据
    func append(data: Data?) throws {
        guard let data = data else {
            return
        }
        
        if (!isExist) {
            try create(with: data)
            return
        }
        
        let handle = try handle(.writing)
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }
    
    struct StreamSlice {
        public let offset: UInt64
        public let data: Data
    }
    
    func write(handle: FileHandle,
               offset: UInt64 = 0,
               stream: AsyncThrowingStream<Data, any Error>,
               progress: ((_ offset: UInt64) async throws -> Void)? = nil) async throws {
        try handle.seek(toOffset: offset)
        try await progress?(offset)
        for try await data in stream {
            try handle.write(contentsOf: data)
            try await progress?(try handle.offset())
        }
        try handle.close()
    }
    
    func readLines(progress: ((_ row: Int) -> Void)? = nil,
                   splitBy: [String] = ["\n", "\r"],
                   _ call: (_ line: String) async throws -> Void) async throws {
        var data = Data()
        var row = 0
        try await readStream(handle: self.handle(.reading)) { slice in
            if let char = String(data: slice.data, encoding: .utf8),
               splitBy.contains(char),
               let string = String(data: data, encoding: .utf8) {
                try await call(string)
                row += 1
                progress?(row)
                data = Data()
            } else {
                data += slice.data
            }
        }
        if let string = String(data: data, encoding: .utf8), !string.isEmpty {
            row += 1
            progress?(row)
            try await call(string)
        }
    }

    func readStream(handle: FileHandle,
                    chunkSize: Int = 1,
                    slice: (_ slice: StreamSlice) async throws -> Void,
                    finish: ((_ handle: FileHandle) async throws -> Void)? = nil) async throws {
        do {
            var offset = try handle.offset()
            while let data = try handle.read(upToCount: chunkSize) {
                if data.isEmpty {
                    break
                }
                
                try await slice(.init(offset: offset, data: data))
                try handle.seek(toOffset: offset + UInt64(data.count))
                offset = offset + UInt64(data.count)
            }
            try await finish?(handle)
        } catch {
            try await finish?(handle)
            throw error
        }
    }
    
}

public extension Array where Element == STFile {
    
    @discardableResult
    func joined(to target: STFile) async throws -> STFile {
        try target.overlay(with: .init())
        let to = try target.handle(.writing)
        defer { try? to.close() }
        
        for file in self {
            try await file.readStream(handle: file.handle(.reading)) { slice in
                try to.write(contentsOf: slice.data)
            } finish: { handle in
                try handle.close()
            }
        }
        try to.close()
        return target
    }
    
}

public extension STFile {
    
    /// 覆盖文件内容(文件不存在则会创建文件)
    /// - Parameter with: 数据
    @discardableResult
    func overlay(model: Encodable, encoder: JSONEncoder = .init()) throws -> Self {
        return try self.overlay(with: encoder.encode(model))
    }
    
    func overlay(with data: String?, using: String.Encoding = .utf8) throws {
        try overlay(with: data?.data(using: using))
    }
    
    /// 覆盖文件内容(文件不存在则会创建文件)
    /// - Parameter with: 数据
    @discardableResult
    func overlay(with data: Data?) throws -> Self {
        if (!isExist) {
            try create(with: data)
            return self
        }
        try delete()
        try create(with: data)
        return self
    }
    
}


public extension STFile {
    
    func handle(_ kind: STFileOpenKind) throws -> FileHandle {
        switch kind {
        case .writing:
            return try .init(forWritingTo: url)
        case .reading:
            return try .init(forReadingFrom: url)
        case .updating:
            return try .init(forUpdating: url)
        }
    }
    
}
