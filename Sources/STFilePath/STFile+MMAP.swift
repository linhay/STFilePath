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
    
    /// [en] Memory-maps the file.
    /// [zh] 内存映射文件。
    /// - Parameters:
    ///   - prot: The memory protection of the mapping.
    ///   - type: The type of mapping.
    ///   - shareType: The sharing type of the mapping.
    ///   - size: The size of the mapping. If `nil`, the file size is used.
    ///   - offset: The offset in the file to start the mapping from.
    /// - Returns: An `STFileMMAP` instance.
    /// - Throws: An error if the file cannot be memory-mapped.
    func mmap(prot: STFileMMAP.MMAPProt = [.read, .write],
              type: STFileMMAP.MMAPType = .file,
              shareType: STFileMMAP.MMAPShareType = .share,
              size: Int? = nil,
              offset: Int = 0) throws -> STFileMMAP {
        
        guard isExist else {
            throw STPathError(message: "[en] Cannot open '\(url.absoluteURL)' [zh] 无法打开 '\(url.absoluteURL)'")
        }
        
        let system = self.system
        let descriptor = try system.open(flag1: .readAndWrite, flag2: nil, mode: nil)
        do {
            let info = try system.stat(descriptor: descriptor)
            let fileSize = info.st_size
            let size = system.alignmentPageSize(from: size ?? Int(fileSize))
            
            guard size > 0 else {
                throw STPathError(message: "[en] size must be greater than 0 [zh] 大小必须大于 0")
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
    
    /// [en] The type of memory mapping.
    /// [zh] 内存映射的类型。
    struct MMAPType: OptionSet {
        public let rawValue: Int32
        
        /// [en] Mapped from a file or device.
        /// [zh] 从文件或设备映射。
        public static let file = MMAPType(rawValue: MAP_FILE)
        
        /// [en] Allocated from anonymous virtual memory.
        /// [zh] 从匿名虚拟内存分配。
        public static let anon = MMAPType(rawValue: MAP_ANON)
        
        /// [en] Allocated from anonymous virtual memory. This creates an anonymous mapping, ignoring the `fd` parameter, not involving a file, and the mapping area cannot be shared with other processes.
        /// [zh] 从匿名虚拟内存分配。这将创建一个匿名映射，忽略 `fd` 参数，不涉及文件，并且映射区域不能与其他进程共享。
        public static let anonymous = MMAPType(rawValue: MAP_ANONYMOUS)
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    /// [en] The sharing type of the memory mapping.
    /// [zh] 内存映射的共享类型。
    struct MMAPShareType: OptionSet {
        /// [en] Writes to the mapped area are copied back to the file and are shared with other processes that map the same file.
        /// [zh] 对映射区域的写入数据将复制回文件，并允许其他映射该文件的进程共享。
        public static let share     = MMAPShareType(rawValue: MAP_SHARED)
        /// [en] Writes to the mapped area create a copy of the mapped file (private "copy on write"). Any modifications to this area will not be written back to the original file content.
        /// [zh] 对映射区域的写入操作会产生一个映射文件的副本，即私有的“写入时复制”（copy on write）。对此区域作的任何修改都不会写回原来的文件内容。
        public static let `private` = MMAPShareType(rawValue: MAP_PRIVATE)
        public static let copy      = MMAPShareType(rawValue: MAP_COPY)
        
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    /// [en] The memory protection of the mapping.
    /// [zh] 映射的内存保护。
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
    
    /// [en] Synchronizes the memory-mapped region with the file.
    /// [zh] 将内存映射区域与文件同步。
    func sync() {
        msync(startPoint, Int(fileSize), descriptor)
    }
    
    /// [en] Reads data from the memory-mapped region.
    /// [zh] 从内存映射区域读取数据。
    /// - Parameter range: The range of bytes to read. If `nil`, the entire file is read.
    /// - Returns: The data read from the memory-mapped region.
    func read(range: Range<Int>? = nil) -> Data {
        if let range = range {
            return Data(bytes: startPoint + range.lowerBound, count: range.upperBound - range.lowerBound)
        }
        return Data(bytes: startPoint, count: .init(fileSize))
    }
    
    /// [en] Appends data to the memory-mapped region.
    /// [zh] 将数据追加到内存映射区域。
    /// - Parameter data: The data to append.
    /// - Throws: An error if the write operation fails.
    func append(data: Data) throws {
        try write(data: data, offset: Int(fileSize))
    }
    
    /// [en] Writes data to the memory-mapped region.
    /// [zh] 将数据写入内存映射区域。
    /// - Parameters:
    ///   - data: The data to write.
    ///   - offset: The offset to write the data at.
    /// - Throws: An error if the write operation fails.
    func write(data: Data, offset: Int = 0) throws {
        // [en] Check if the data to be written exceeds the mapped region size.
        // [zh] 检查要写入的数据是否超出映射区域大小。
        if data.count + offset > size {
            throw STPathError(message: "[en] The data to be written exceeds the mapped region size. Mapped region size: \(size) [zh] 写入数据超出映射区大小, 映射区size: \(size)")
        }

        // [en] Get the starting position for writing data.
        // [zh] 获取写入数据的起始位置。
        let point = startPoint + offset
        // [en] Copy the data to the mapped region.
        // [zh] 将数据复制到映射区域。
        var data = data
        Darwin.memcpy(point, &data, data.count)
        // [en] Check if the memcpy operation was successful.
        // [zh] 检查 memcpy 操作是否成功。
        if Darwin.errno != 0 {
            throw STPathError(posix: Darwin.errno)
        }
        // [en] Update the actual file size.
        // [zh] 更新实际文件大小。
        fileSize = .init(offset + data.count)
    }
    
}
#endif
