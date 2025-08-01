//
//  File.swift
//  
//
//  Created by linhey on 2024/4/22.
//

import Foundation

public extension STFile {
    /// [en] Accesses the file as a line-oriented file.
    /// [zh] 以面向行的文件形式访问文件。
    var lineFile: STLineFile { STLineFile.init(file: self) }
}

/// [en] A struct that provides line-oriented operations on a file.
/// [zh] 一个在文件上提供面向行操作的结构体。
public struct STLineFile {
    
    /// [en] The underlying file.
    /// [zh] 底层文件。
    public let file: STFile
    /// [en] A writer for appending new lines to the file.
    /// [zh] 用于向文件追加新行的写入器。
    public var newLineWriter: NewLineWriter {
        get throws {
            try .init(handle: file.handle(.updating))
        }
    }
    public init(file: STFile) {
        self.file = file
    }
    
    /// [en] Reads the lines of the file and decodes them as the specified type.
    /// [zh] 读取文件的行并将其解码为指定的类型。
    /// - Parameter kind: The type to decode the lines as.
    /// - Returns: An array of decoded models.
    /// - Throws: An error if the lines cannot be read or decoded.
    public func lines<Model: Decodable>(as kind: Model.Type) throws -> [Model] {
        let decoder = JSONDecoder()
        return try self.lines().map { data in
            try decoder.decode(Model.self, from: data)
        }
    }
    
    /// [en] Reads the lines of the file as an array of data.
    /// [zh] 以数据数组的形式读取文件的行。
    /// - Returns: An array of data, where each element is a line from the file.
    /// - Throws: An error if the lines cannot be read.
    public func lines() throws -> [Data] {
        var lines = [Data]()
        let handle = try file.handle(.reading)
        let reader = LineReader(handle: handle)
        while let line = reader.nextLine() {
            lines.append(line)
        }
        try handle.close()
        return lines
    }
    
    /// [en] A class for writing new lines to a file.
    /// [zh] 一个用于向文件写入新行的类。
    public class NewLineWriter {
        
        let handle: FileHandle
        let encoder = JSONEncoder()

        init(handle: FileHandle) {
            self.handle = handle
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        }
        
        /// [en] Appends a model to the file as a new line.
        /// [zh] 将模型作为新行追加到文件。
        /// - Parameter model: The model to append.
        /// - Throws: An error if the model cannot be encoded or appended.
        public func append(model: any Encodable) throws {
           let data = try encoder.encode(model)
           try append(data)
        }
        
        /// [en] Appends data to the file as a new line.
        /// [zh] 将数据作为新行追加到文件。
        /// - Parameter newLine: The data to append.
        /// - Throws: An error if the data cannot be appended.
        public func append(_ newLine: any DataProtocol) throws {
            // [en] Check if the file already ends with a newline character.
            // [zh] 检查文件是否已经以换行符结尾。
            if try handle.seekToEnd() > 0 {
                try handle.seek(toOffset: handle.offsetInFile - 1)
                let lastByte = try handle.read(upToCount: 1)
                if lastByte != "\n".data(using: .utf8) {
                    // [en] If the file does not end with a newline character, add one.
                    // [zh] 如果文件不是以换行符结尾，则添加一个换行符。
                    try handle.write(contentsOf: "\n".data(using: .utf8)!)
                }
            }
            try handle.write(contentsOf: newLine)
        }
    }
    
    private class LineReader {
        let handle: FileHandle
        var buffer = Data()
        
        init(handle: FileHandle) {
            self.handle = handle
        }
        
        func nextLine() -> Data? {
            while true {
                if let range = buffer.range(of: Data("\n".utf8)) {
                    let line = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                    buffer.removeSubrange(buffer.startIndex...range.lowerBound)
                    return line
                }
                
                let tmpData = handle.readData(ofLength: 1024)
                if tmpData.isEmpty {
                    return nil  // EOF reached
                }
                buffer.append(tmpData)
            }
        }
    }
}
