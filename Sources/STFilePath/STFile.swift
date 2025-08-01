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

/// [en] Represents a file path and provides file-specific operations.
/// [zh] 表示文件路径并提供文件特定的操作。
public struct STFile: STPathProtocol, Codable {
    
    /// [en] The type of the file system item, which is always `.file`.
    /// [zh] 文件系统项的类型，始终为 `.file`。
    public var type: STFilePathItemType = .file
    /// [en] The URL of the file.
    /// [zh] 文件的 URL。
    public let url: URL
    
    /// [en] Initializes a new `STFile` instance with the specified URL.
    /// [zh] 使用指定的 URL 初始化一个新的 `STFile` 实例。
    /// - Parameter url: The URL of the file.
    public init(_ url: URL) {
        self.url = url.standardized
    }
    
    /// [en] Initializes a new `STFile` instance with the specified path string.
    /// [zh] 使用指定的路径字符串初始化一个新的 `STFile` 实例。
    /// - Parameter path: The path string.
    public init(_ path: String) {
        self.init(Self.standardizedPath(path))
    }
    
    /// [en] Initializes a new `STFile` instance from a decoder.
    /// [zh] 从解码器初始化一个新的 `STFile` 实例。
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.url = try container.decode(URL.self)
    }
    
    /// [en] Encodes this `STFile` instance into the given encoder.
    /// [zh] 将此 `STFile` 实例编码到给定的编码器中。
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.url)
    }
    
}

public extension STFile {
    
    /// [en] Moves the file to a new location.
    /// [zh] 将文件移动到新位置。
    /// - Parameter file: The destination file path.
    /// - Returns: The new `STFile` instance at the destination.
    /// - Throws: An error if the move operation fails.
    @discardableResult
    func move(to file: STFile) throws -> STFile {
        try manager.moveItem(at: url, to: file.url)
        return file
    }
    
    /// [en] Replaces a destination file with this file.
    /// [zh] 用此文件替换目标文件。
    /// - Parameter file: The file to be replaced.
    /// - Throws: An error if the replacement fails.
    func replace(_ file: STFile) throws {
        if file.isExist {
            try file.delete()
        }
        try self.copy(to: file)
    }
    
    /// [en] Copies the file to a new location.
    /// [zh] 将文件复制到新位置。
    /// - Parameter file: The destination file path.
    /// - Returns: The new `STFile` instance at the destination.
    /// - Throws: An error if the copy operation fails.
    @discardableResult
    func copy(to file: STFile) throws -> STFile {
        try manager.copyItem(at: url, to: file.url)
        return file
    }
    
}

public extension STFile {
    
    /// [en] Reads the file content as a string.
    /// [zh] 以字符串形式读取文件内容。
    /// - Parameters:
    ///   - options: Reading options for the data.
    ///   - encoding: The string encoding to use.
    /// - Returns: The content of the file as a string.
    /// - Throws: An error if the file cannot be read.
    func read(_ options: Data.ReadingOptions = [], encoding: String.Encoding = .utf8) throws -> String {
        String(data: try data(options: options), encoding: encoding) ?? ""
    }
    
    /// [en] Writes data to the file.
    /// [zh] 将数据写入文件。
    /// - Parameter data: The data to write.
    /// - Throws: An error if the data cannot be written.
    func write(_ data: Data) throws {
        try data.write(to: url)
    }
    
}

public extension STFile {
    
    /// [en] The data contained in the file.
    /// [zh] 文件中包含的数据。
    /// - Parameter options: Reading options for the data.
    /// - Returns: The file's data.
    /// - Throws: An error if the data cannot be read.
    func data(options: Data.ReadingOptions = []) throws -> Data {
        try Data(contentsOf: url, options: options)
    }
    
    /// [en] Decodes the file's data into a specific type.
    /// [zh] 将文件数据解码为特定类型。
    /// - Parameter tranformed: A closure that takes the file's data and returns the decoded type.
    /// - Returns: The decoded object.
    /// - Throws: An error if decoding fails.
    func decode<T>(_ tranformed: (_ data: Data) throws -> T) throws -> T {
        try tranformed(try Data(contentsOf: url, options: []))
    }
    
    /// [en] Reads a specific range of data from the file.
    /// [zh] 从文件中读取特定范围的数据。
    /// - Parameter range: The closed range of bytes to read.
    /// - Returns: The data in the specified range, or `nil` if the file doesn't exist or the range is invalid.
    /// - Throws: An error if the file handle cannot be created.
    @available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
    func data(range: ClosedRange<Int>) throws -> Data? {
        guard self.isExist else {
            return nil
        }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        // [en] Calculate the size of the data to be read.
        // [zh] 计算要读取的数据的大小。
        let length = range.upperBound - range.lowerBound + 1
        // [en] Move to the start position of the file.
        // [zh] 移动到文件的开始位置。
        handle.seek(toFileOffset: UInt64(range.lowerBound))
        // [en] Read data of the specified range.
        // [zh] 读取指定范围的数据。
        let data = handle.readData(ofLength: length)
        return data.isEmpty ? nil : data
    }
    
    /// [en] Creates the file if it does not already exist.
    /// [zh] 如果文件不存在，则创建该文件。
    /// - Parameter data: The initial data to write to the file.
    /// - Returns: The `STFile` instance.
    /// - Throws: An error if the file cannot be created.
    func createIfNotExists(with data: Data? = nil) throws -> STFile {
        if isExist {
            return self
        } else {
            return try create(with: data)
        }
    }
    
    /// [en] Creates the file.
    /// [zh] 创建文件。
    /// - Parameter data: The initial data to write to the file.
    /// - Returns: The `STFile` instance.
    /// - Throws: A `STPathError` if the file already exists.
    @discardableResult
    func create(with data: Data? = nil) throws -> STFile {
        if isExist {
            throw STPathError(message: "[en] File exists, cannot create: \(url.path) \n [zh] 文件存在, 无法创建: \(url.path)")
        }
        try STFolder(url.deletingLastPathComponent()).create()
        manager.createFile(atPath: url.path, contents: data, attributes: nil)
        return self
    }
    
    /// [en] Appends data to the end of the file. Creates the file if it does not exist.
    /// [zh] 将数据追加到文件末尾。如果文件不存在，则会创建文件。
    /// - Parameter data: The data to append.
    /// - Throws: An error if the data cannot be appended.
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
    
    /// [en] A slice of a file stream containing data and its offset.
    /// [zh] 文件流的切片，包含数据及其偏移量。
    struct StreamSlice {
        /// [en] The offset of the data slice in the file.
        /// [zh] 数据切片在文件中的偏移量。
        public let offset: UInt64
        /// [en] The data slice.
        /// [zh] 数据切片。
        public let data: Data
    }
    
    /// [en] Writes an asynchronous stream of data to the file.
    /// [zh] 将异步数据流写入文件。
    /// - Parameters:
    ///   - handle: The file handle to write to.
    ///   - offset: The starting offset for writing.
    ///   - stream: The asynchronous stream of data.
    ///   - progress: An optional closure to track write progress.
    /// - Throws: An error if writing fails.
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
    
    /// [en] Reads the file line by line.
    /// [zh] 逐行读取文件。
    /// - Parameters:
    ///   - progress: An optional closure to track the number of lines read.
    ///   - splitBy: The characters to split lines by.
    ///   - call: An asynchronous closure called for each line.
    /// - Throws: An error if reading fails.
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

    /// [en] Reads the file as a stream of data chunks.
    /// [zh] 以数据块流的形式读取文件。
    /// - Parameters:
    ///   - handle: The file handle to read from.
    ///   - chunkSize: The size of each data chunk.
    ///   - slice: An asynchronous closure called for each data slice.
    ///   - finish: An optional asynchronous closure called when reading is finished.
    /// - Throws: An error if reading fails.
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
    
    /// [en] Joins the contents of multiple files into a single target file.
    /// [zh] 将多个文件的内容合并到一个目标文件中。
    /// - Parameter target: The target file to write the combined content to.
    /// - Returns: The target `STFile` instance.
    /// - Throws: An error if the join operation fails.
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
    
    /// [en] Overwrites the file's content with an encodable model. Creates the file if it does not exist.
    /// [zh] 使用可编码模型覆盖文件内容。如果文件不存在，则会创建文件。
    /// - Parameters:
    ///   - model: The encodable model to write.
    ///   - encoder: The JSON encoder to use.
    /// - Returns: The `STFile` instance.
    /// - Throws: An error if encoding or writing fails.
    @discardableResult
    func overlay(model: Encodable, encoder: JSONEncoder = .init()) throws -> Self {
        return try self.overlay(with: encoder.encode(model))
    }
    
    /// [en] Overwrites the file's content with a string.
    /// [zh] 用字符串覆盖文件内容。
    /// - Parameters:
    ///   - data: The string to write.
    ///   - using: The string encoding to use.
    /// - Throws: An error if writing fails.
    func overlay(with data: String?, using: String.Encoding = .utf8) throws {
        try overlay(with: data?.data(using: using))
    }
    
    /// [en] Overwrites the file's content with data. Creates the file if it does not exist.
    /// [zh] 用数据覆盖文件内容。如果文件不存在，则会创建文件。
    /// - Parameter with: The data to write.
    /// - Returns: The `STFile` instance.
    /// - Throws: An error if writing fails.
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
    
    /// [en] Gets a file handle for a specific type of operation.
    /// [zh] 获取用于特定类型操作的文件句柄。
    /// - Parameter kind: The kind of file operation.
    /// - Returns: A `FileHandle` for the specified operation.
    /// - Throws: An error if the file handle cannot be created.
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
