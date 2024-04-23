//
//  File.swift
//  
//
//  Created by linhey on 2024/4/22.
//

import Foundation

public extension STFile {
    var lineFile: STLineFile { STLineFile.init(file: self) }
}

public struct STLineFile {
    
    public let file: STFile
    public var newLineWriter: NewLineWriter {
        get throws {
            try .init(handle: file.handle(.updating))
        }
    }
    public init(file: STFile) {
        self.file = file
    }
    
    public func lines<Model: Decodable>(as kind: Model.Type) throws -> [Model] {
        let decoder = JSONDecoder()
        return try self.lines().map { data in
            try decoder.decode(Model.self, from: data)
        }
    }
    
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
    
    public class NewLineWriter {
        
        let handle: FileHandle
        let encoder = JSONEncoder()

        init(handle: FileHandle) {
            self.handle = handle
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        }
        
        public func append(model: any Encodable) throws {
           let data = try encoder.encode(model)
           try append(data)
        }
        
        public func append(_ newLine: any DataProtocol) throws {
            // 检查文件是否已经以换行符结尾
            if try handle.seekToEnd() > 0 {
                try handle.seek(toOffset: handle.offsetInFile - 1)
                let lastByte = try handle.read(upToCount: 1)
                if lastByte != "\n".data(using: .utf8) {
                    // 如果文件不是以换行符结尾，则添加一个换行符
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
