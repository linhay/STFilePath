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

#if canImport(Darwin)
import Darwin
import Foundation

extension STFile {
    
    func mmap(prot: STFileMMAP.MMAPProt = [.read, .write],
              type: STFileMMAP.MMAPType = .file,
              shareType: STFileMMAP.MMAPShareType = .share,
              size: Int? = nil,
              offset: Int = 0) throws -> STFileMMAP {
        
        guard isExist else {
            throw STPathError(message: "Cannot open '\(url.absoluteURL)'")
        }
        
        let system = self.system
        let descriptor = try system.open(flag1: .readAndWrite, flag2: nil, mode: nil)
        do {
            let info = try system.stat(descriptor: descriptor)
            let fileSize = info.st_size
            let size = system.alignmentPageSize(from: size ?? Int(fileSize))
            
            guard size > 0 else {
                throw STPathError(message: "size 必须大于 0")
            }
            
            try system.truncate(descriptor: descriptor, size: size)
            try system.sync(descriptor: descriptor)
            
            return try STFileMMAP(descriptor: descriptor,
                                  prot: prot,
                                  type: type,
                                  shareType: shareType,
                                  fileSize: fileSize,
                                  size: size,
                                  offset: offset)
        } catch {
            close(descriptor)
            throw error
        }
        
    }
    
}

// MARK: - Error
public class STFileMMAP {
    
    struct MMAPType: OptionSet {
        public let rawValue: Int32
        
        /// Mapped from a file or device
        /// 从文件或设备映射
        public static let file = MMAPType(rawValue: MAP_FILE)
        
        /// Allocated from anonymous virtual memory
        public static let anon = MMAPType(rawValue: MAP_ANON)
        
        /// Allocated from anonymous virtual memory
        /// 建立匿名映射，此时会忽略参数fd，不涉及文件，而且映射区域无法和其他进程共享
        public static let anonymous = MMAPType(rawValue: MAP_ANONYMOUS)
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    struct MMAPShareType: OptionSet {
        /// 对应射区域的写入数据会复制回文件内，而且允许其他映射该文件的进程共享。
        public static let share     = MMAPShareType(rawValue: MAP_SHARED)
        /// 对应射区域的写入操作会产生一个映射文件的复制，即私人的"写入时复制" (copy on write)对此区域作的任何修改都不会写回原来的文件内容
        public static let `private` = MMAPShareType(rawValue: MAP_PRIVATE)
        public static let copy      = MMAPShareType(rawValue: MAP_COPY)
        
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    struct MMAPProt: OptionSet {
        public let rawValue: Int32
        
        public static let none  = MMAPProt(rawValue: 0 << 0)
        public static let read  = MMAPProt(rawValue: 1 << 0)
        public static let write = MMAPProt(rawValue: 1 << 1)
        public static let exec  = MMAPProt(rawValue: 1 << 2)
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    let prot: MMAPProt
    let type: MMAPType
    let shareType: MMAPShareType
    let size: Int
    let offset: Int
    
    private(set) var fileSize: off_t
    
    let startPoint: UnsafeMutableRawPointer
    let descriptor: Int32
    
    init(descriptor: Int32,
         prot: MMAPProt,
         type: MMAPType,
         shareType: MMAPShareType,
         fileSize: off_t,
         size: Int,
         offset: Int = 0) throws {
        
        self.descriptor = descriptor
        self.prot = prot
        self.type = type
        self.shareType = shareType
        self.size = size
        self.offset = offset
        self.fileSize = fileSize
        self.startPoint = Darwin.mmap(nil,
                                      size,
                                      prot.rawValue,
                                      type.rawValue|shareType.rawValue,
                                      descriptor,
                                      .init(offset))
        if startPoint == MAP_FAILED {
            close(descriptor)
            throw STPathError(posix: Darwin.errno)
        }
    }
    
    deinit {
        close(descriptor)
        munmap(startPoint, size)
    }
    
}


public extension STFileMMAP {
    
    func sync() {
        msync(startPoint, Int(fileSize), descriptor)
    }
    
    func read(range: Range<Int>? = nil) -> Data {
        if let range = range {
            return Data(bytes: startPoint + range.lowerBound, count: range.upperBound - range.lowerBound)
        }
        return Data(bytes: startPoint, count: .init(fileSize))
    }
    
    func append(data: Data) throws {
        try write(data: data, offset: Int(fileSize))
    }
    
    // 写入数据
    func write(data: Data, offset: Int = 0) throws {
        // 检查要写入的数据是否超出映射区域大小
        if data.count + offset > size {
            throw STPathError(message: "写入数据超出映射区大小, 映射区size: \(size)")
        }

        // 获取写入数据的起始位置
        let point = startPoint + offset
        // 将数据复制到映射区域
        var data = data
        Darwin.memcpy(point, &data, data.count)
        // 检查 memcpy 操作是否成功
        if Darwin.errno != 0 {
            throw STPathError(posix: Darwin.errno)
        }
        // 更新实际文件大小
        fileSize = .init(offset + data.count)
    }
    
}
#endif
