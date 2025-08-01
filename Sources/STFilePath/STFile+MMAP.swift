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

// MARK: - Scoped MMAP API
public extension STFile {
    
    /// [en] Safely interacts with a memory-mapped file within a closure.
    /// The memory map is automatically created, and resources are guaranteed to be released
    /// when the closure completes.
    /// [zh] 在闭包内安全地与内存映射文件交互。
    /// 内存映射会自动创建，并在闭包完成时保证资源被释放。
    ///
    /// - Parameters:
    ///   - prot: The memory protection of the mapping. Defaults to read/write.
    ///   - shareType: The sharing type of the mapping. Defaults to shared.
    ///   - size: The size of the mapping. If `nil`, the current file size is used.
    ///   - offset: The offset in the file to start the mapping from.
    ///   - body: A closure that receives the `STFileMMAP` instance for interaction.
    /// - Returns: The value returned by the `body` closure.
    /// - Throws: An error if the file cannot be memory-mapped or if the `body` closure throws an error.
    func withMmap<
    T>(
        prot: STFileMMAP.MMAPProt = [.read, .write],
        shareType: STFileMMAP.MMAPShareType = .share,
        size: Int? = nil,
        offset: Int = 0,
        _ body: (STFileMMAP) throws -> T
    ) throws -> T {
        let mmap = try STFileMMAP(file: self, prot: prot, shareType: shareType, size: size, offset: offset)
        defer {
            mmap.close()
        }
        return try body(mmap)
    }
    
    /// [en] Resizes the file to the specified size.
    /// [zh] 将文件调整为指定大小。
    ///
    /// - Parameter newSize: The target size in bytes.
    /// - Throws: An error if the file cannot be resized.
    func setSize(_ newSize: Int) throws {
        let descriptor = try self.system.open(flag1: .readAndWrite, flag2: nil, mode: nil)
        defer { Darwin.close(descriptor) }
        try self.system.truncate(descriptor: descriptor, size: newSize)
    }
}


// MARK: - STFileMMAP Class
public class STFileMMAP {
    
    // MARK: - Nested Types
    
    /// [en] The memory protection of the mapping.
    /// [zh] 映射的内存保护。
    public struct MMAPProt: OptionSet, Sendable {
        public let rawValue: Int32
        public static let none  = MMAPProt(rawValue: PROT_NONE)
        public static let read  = MMAPProt(rawValue: PROT_READ)
        public static let write = MMAPProt(rawValue: PROT_WRITE)
        public static let exec  = MMAPProt(rawValue: PROT_EXEC)
        public init(rawValue: Int32) { self.rawValue = rawValue }
    }
    
    /// [en] The sharing type of the memory mapping.
    /// [zh] 内存映射的共享类型。
    public struct MMAPShareType: OptionSet, Sendable {
        public let rawValue: Int32
        /// [en] Writes to the mapped area are copied back to the file and are shared with other processes that map the same file.
        /// [zh] 对映射区域的写入数据将复制回文件，并允许其他映射该文件的进程共享。
        public static let share = MMAPShareType(rawValue: MAP_SHARED)
        /// [en] Writes to the mapped area create a copy of the mapped file (private "copy on write"). Any modifications to this area will not be written back to the original file content.
        /// [zh] 对映射区域的写入操作会产生一个映射文件的副本，即私有的“写入时复制”（copy on write）。对此区域作的任何修改都不会写回原来的文件内容。
        public static let `private` = MMAPShareType(rawValue: MAP_PRIVATE)
        public init(rawValue: Int32) { self.rawValue = rawValue }
    }
    
    // MARK: - Properties
    
    /// [en] The size of the mapped memory region in bytes.
    /// [zh] 映射内存区域的大小（字节）。
    public let size: Int
    
    private let startPoint: UnsafeMutableRawPointer
    private let descriptor: Int32
    private var isClosed = false
    
    // MARK: - Initialization
    
    fileprivate init(file: STFile,
                     prot: MMAPProt,
                     shareType: MMAPShareType,
                     size: Int?,
                     offset: Int) throws {
        
        guard file.isExist else {
            throw STPathError(message: "[en] Cannot open non-existent file at \'\(file.url.path)\' [zh] 无法打开不存在的文件 \'\(file.url.path)\'")
        }
        
        self.descriptor = try file.system.open(flag1: .readAndWrite, flag2: nil, mode: nil)
        
        do {
            let info = try file.system.stat(descriptor: descriptor)
            let fileSize = info.st_size
            let mapSize = size ?? Int(fileSize)
            
            guard mapSize > 0 else {
                throw STPathError(message: "[en] Mapping size must be greater than 0 [zh] 映射大小必须大于 0")
            }
            
            if mapSize > fileSize {
                throw STPathError(message: "[en] Mapping size (\(mapSize)) cannot exceed file size (\(fileSize)). Use file.setSize() first. [zh] 映射大小 (\(mapSize)) 不能超过文件大小 (\(fileSize))。请先使用 file.setSize()。")
            }
            
            self.size = mapSize
            self.startPoint = Darwin.mmap(nil,
                                          self.size,
                                          prot.rawValue,
                                          shareType.rawValue | MAP_FILE,
                                          descriptor,
                                          .init(offset))
            
            if startPoint == MAP_FAILED {
                Darwin.close(descriptor)
                throw STPathError(posix: Darwin.errno)
            }
        } catch {
            Darwin.close(descriptor)
            throw error
        }
    }
    
    deinit {
        close()
    }
    
    // MARK: - Public Methods
    
    /// [en] Explicitly closes the memory map and the file descriptor.
    /// [zh] 显式关闭内存映射和文件描述符。
    public func close() {
        guard !isClosed else { return }
        isClosed = true
        munmap(startPoint, size)
        Darwin.close(descriptor)
    }
    
    /// [en] Synchronizes the memory-mapped region with the file on disk.
    /// [zh] 将内存映射区域与磁盘上的文件同步。
    public func sync() {
        msync(startPoint, size, MS_SYNC)
    }
    
    /// [en] Provides safe, typed access to the memory-mapped buffer.
    /// [zh] 为内存映射缓冲区提供安全的、类型化的访问。
    /// - Parameters:
    ///   - type: The type to bind the memory to (e.g., `UInt8.self`).
    ///   - body: A closure that receives a type-safe `UnsafeMutableBufferPointer`.
    /// - Returns: The value returned by the `body` closure.
    public func withUnsafeMutableBufferPointer<T, R>(as type: T.Type, _ body: (UnsafeMutableBufferPointer<T>) throws -> R) throws -> R {
        let buffer = UnsafeMutableRawBufferPointer(start: startPoint, count: size)
        return try buffer.withMemoryRebound(to: T.self, body)
    }
    
    /// [en] Reads data from the memory-mapped region.
    /// [zh] 从内存映射区域读取数据。
    /// - Parameter range: The range of bytes to read. If `nil`, the entire mapped region is read.
    /// - Returns: The data read from the memory-mapped region.
    public func read(range: Range<Int>? = nil) -> Data {
        let readRange = range ?? 0..<size
        precondition(readRange.lowerBound >= 0 && readRange.upperBound <= size, "Read range is out of bounds")
        return Data(bytes: startPoint + readRange.lowerBound, count: readRange.count)
    }
    
    /// [en] Writes data to the memory-mapped region.
    /// [zh] 将数据写入内存映射区域。
    /// - Parameters:
    ///   - data: The data to write.
    ///   - offset: The offset to write the data at.
    /// - Throws: An error if the write operation would exceed the mapped region size.
    public func write(_ data: Data, at offset: Int = 0) throws {
        let writeCount = data.count
        guard offset >= 0, offset + writeCount <= size else {
            throw STPathError(message: "[en] The data to be written exceeds the mapped region size. Mapped size: \(size), trying to write \(writeCount) bytes at offset \(offset). [zh] 写入数据超出映射区大小。映射大小: \(size)，尝试在偏移量 \(offset) 处写入 \(writeCount) 字节。")
        }
        
        let point = startPoint + offset
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            if let baseAddress = buffer.baseAddress {
                memcpy(point, baseAddress, writeCount)
            }
        }
    }
}
#endif
