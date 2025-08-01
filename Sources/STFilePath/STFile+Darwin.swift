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
import Foundation
import Darwin

public extension STFile {
    
    /// [en] Provides access to Darwin-specific file operations.
    /// [zh] 提供对 Darwin 特定文件操作的访问。
    var system: System { System(filePath: self) }
        
    class System {
        
        let filePath: STFile
        
        init(filePath: STFile) {
            self.filePath = filePath
        }
        
    }
    
}

public extension STFile.System {

    /// [en] Opens the file with the specified flags and mode.
    /// [zh] 使用指定的标志和模式打开文件。
    /// - Parameters:
    ///   - flag1: The open type.
    ///   - flag2: The open flags.
    ///   - mode: The open mode.
    /// - Returns: The file descriptor.
    /// - Throws: An error if the file cannot be opened.
    func open(flag1: OpenType, flag2: OpenFlag?, mode: OpenMode?) throws -> Int32 {
        var flag: Int32 = flag1.rawValue
        
        if let flag2 = flag2 {
            flag |= flag2.rawValue
        }
        
        let result = Darwin.open(filePath.url.path, flag, mode?.rawValue ?? 0)
        if result < 0 {
            throw STPathError(posix: Darwin.errno)
        }
        return result
    }
    
    /// [en] Gets the status of the file.
    /// [zh] 获取文件的状态。
    /// - Parameter descriptor: The file descriptor.
    /// - Returns: The status of the file.
    /// - Throws: An error if the status cannot be retrieved.
    func stat(descriptor: Int32) throws -> Darwin.stat {
        var result = Darwin.stat()
        let flag = fstat(descriptor, &result)
        if flag != 0 {
            throw STPathError(message: "[en] Failed to get file attributes \n [zh] 赋值文件属性错误", code: Int(flag))
        }
        return result
    }
    
    /// [en] Aligns the given size to the page size.
    /// [zh] 将给定的大小与页面大小对齐。
    /// - Parameter size: The size to align.
    /// - Returns: The aligned size.
    func alignmentPageSize(from size: Int) -> Int {
        let pageSize = Int(vm_page_size)
        let count = size / pageSize + size % pageSize == 0 ? 0 : 1
        return pageSize * count
    }
    
    /// [en] Truncates the file to the specified size.
    /// [zh] 将文件截断为指定的大小。
    /// - Parameters:
    ///   - descriptor: The file descriptor.
    ///   - size: The new size of the file.
    /// - Throws: An error if the file cannot be truncated.
    func truncate(descriptor: Int32, size: Int) throws {
        if ftruncate(descriptor, .init(size)) == -1 {
           throw STPathError(posix: Darwin.errno)
        }
    }
    
    /// [en] Synchronizes the file's in-memory data to the storage device.
    /// [zh] 将文件的内存中数据同步到存储设备。
    /// - Parameter descriptor: The file descriptor.
    /// - Throws: An error if the file cannot be synchronized.
    func sync(descriptor: Int32) throws {
        if fsync(descriptor) == -1 {
           throw STPathError(posix: Darwin.errno)
        }
    }
    
}

public extension STFile.System {
    
    /// [en] The mode to open the file with.
    /// [zh] 打开文件的模式。
    struct OpenMode: OptionSet {
        /// [en] S_IRWXU 00700 permission, which means the file owner has read, write, and execute permissions.
        /// [zh] S_IRWXU 00700 权限，表示文件所有者具有读、写和执行权限。
        public static let irwxu  = OpenMode(rawValue: S_IRWXU)
        /// [en] S_IRUSR or S_IREAD, 00400 permission, which means the file owner has read permission.
        /// [zh] S_IRUSR 或 S_IREAD, 00400 权限，表示文件所有者具有读权限。
        public static let iruser = OpenMode(rawValue: S_IRUSR)
        public static let iread  = OpenMode(rawValue: S_IREAD)
        /// [en] S_IWUSR or S_IWRITE, 00200 permission, which means the file owner has write permission.
        /// [zh] S_IWUSR 或 S_IWRITE, 00200 权限，表示文件所有者具有写权限。
        public static let iwuser = OpenMode(rawValue: S_IWUSR)
        public static let iwrite = OpenMode(rawValue: S_IWRITE)
        /// [en] S_IXUSR or S_IEXEC, 00100 permission, which means the file owner has execute permission.
        /// [zh] S_IXUSR 或 S_IEXEC, 00100 权限，表示文件所有者具有执行权限。
        public static let ixuser = OpenMode(rawValue: S_IXUSR)
        public static let iexec  = OpenMode(rawValue: S_IEXEC)
        /// [en] S_IRWXG 00070 permission, which means the file's user group has read, write, and execute permissions.
        /// [zh] S_IRWXG 00070 权限，表示文件的用户组具有读、写和执行权限。
        public static let irwxg  = OpenMode(rawValue: S_IRWXG)
        /// [en] S_IRGRP 00040 permission, which means the file's user group has read permission.
        /// [zh] S_IRGRP 00040 权限，表示文件的用户组具有读权限。
        public static let irgrp  = OpenMode(rawValue: S_IRGRP)
        /// [en] S_IWGRP 00020 permission, which means the file's user group has write permission.
        /// [zh] S_IWGRP 00020 权限，表示文件的用户组具有写权限。
        public static let iwgrp  = OpenMode(rawValue: S_IWGRP)
        /// [en] S_IXGRP 00010 permission, which means the file's user group has execute permission.
        /// [zh] S_IXGRP 00010 权限，表示文件的用户组具有执行权限。
        public static let ixgrp  = OpenMode(rawValue: S_IXGRP)
        /// [en] S_IRWXO 00007 permission, which means other users have read, write, and execute permissions.
        /// [zh] S_IRWXO 00007 权限，表示其他用户具有读、写和执行权限。
        public static let irwxo  = OpenMode(rawValue: S_IRWXO)
        /// [en] S_IROTH 00004 permission, which means other users have read permission.
        /// [zh] S_IROTH 00004 权限，表示其他用户具有读权限。
        public static let iroth  = OpenMode(rawValue: S_IROTH)
        /// [en] S_IWOTH 00002 permission, which means other users have write permission.
        /// [zh] S_IWOTH 00002 权限，表示其他用户具有写权限。
        public static let iwoth  = OpenMode(rawValue: S_IWOTH)
        /// [en] S_IXOTH 00001 permission, which means other users have execute permission.
        /// [zh] S_IXOTH 00001 权限，表示其他用户具有执行权限。
        public static let ixoth  = OpenMode(rawValue: S_IXOTH)
        
        public let rawValue: mode_t
        public init(rawValue: mode_t) {
            self.rawValue = rawValue
        }
    }
    
    /// [en] The type of access to the file.
    /// [zh] 对文件的访问类型。
    public enum OpenType: Int32 {
        /// [en] O_RDONLY Open the file for reading only.
        /// [zh] O_RDONLY 以只读方式打开文件。
        case readOnly     = 0
        /// [en] O_WRONLY Open the file for writing only.
        /// [zh] O_WRONLY 以只写方式打开文件。
        case writeOnly    = 1
        /// [en] O_RDWR Open the file for reading and writing. These three flags are mutually exclusive and cannot be used at the same time, but they can be combined with the following flags using the OR (|) operator.
        /// [zh] O_RDWR 以可读写方式打开文件。上述三种旗标是互斥的，也就是不可同时使用，但可与下列的旗标利用OR(|)运算符组合。
        case readAndWrite = 2
        case accMode      = 3
    }
    
    /// [en] Flags for opening a file.
    /// [zh] 打开文件的标志。
    public struct OpenFlag: OptionSet {
        /// [en] If the file does not exist, it will be created automatically.
        /// [zh] 若欲打开的文件不存在则自动建立该文件。
        public static let create   = OpenFlag(rawValue: O_CREAT)
        /// [en] If O_CREAT is also set, this instruction will check if the file exists. If the file does not exist, it will be created; otherwise, it will cause an error when opening the file. In addition, if O_CREAT and O_EXCL are set at the same time, and the file to be opened is a symbolic link, the file will fail to open.
        /// [zh] 如果O_CREAT 也被设置，此指令会去检查文件是否存在。文件若不存在则建立该文件，否则将导致打开文件错误。此外，若O_CREAT 与O_EXCL 同时设置，并且欲打开的文件为符号连接，则会打开文件失败。
        public static let excl     = OpenFlag(rawValue: O_EXCL)
        /// [en] If the file to be opened is a terminal device, the terminal will not be treated as a process control terminal.
        /// [zh] 如果欲打开的文件为终端机设备时，则不会将该终端机当成进程控制终端机。
        public static let noctty   = OpenFlag(rawValue: O_NOCTTY)
        /// [en] If the file exists and is opened in a writable manner, this flag will clear the file length to 0, and the data originally stored in the file will disappear.
        /// [zh] 若文件存在并且以可写的方式打开时，此旗标会令文件长度清为0，而原来存于该文件的资料也会消失。
        public static let trunc    = OpenFlag(rawValue: O_TRUNC)
        /// [en] When reading and writing files, it will start from the end of the file, that is, the written data will be added to the back of the file in an appended manner.
        /// [zh] 当读写文件时会从文件尾开始移动，也就是所写入的数据会以附加的方式加入到文件后面。
        public static let append   = OpenFlag(rawValue: O_APPEND)
        /// [en] Open the file in a non-blocking manner, that is, it will return to the process immediately regardless of whether there is data to be read or waiting.
        /// [zh] 以不可阻断的方式打开文件，也就是无论有无数据读取或等待，都会立即返回进程之中。
        public static let nonBlock = OpenFlag(rawValue: O_NONBLOCK)
        /// [en] Same as O_NONBLOCK.
        /// [zh] 同O_NONBLOCK。
        public static let ndelay = OpenFlag(rawValue: O_NDELAY)
        /// [en] Open the file in a synchronous manner.
        /// [zh] 以同步的方式打开文件。
        public static let sync      = OpenFlag(rawValue: O_SYNC)
        /// [en] If the file pointed to by the pathname parameter is a symbolic link, the file will fail to open.
        /// [zh] 如果参数pathname 所指的文件为一符号连接，则会令打开文件失败。
        public static let nofollow  = OpenFlag(rawValue: O_NOFOLLOW)
        /// [en] If the file pointed to by the pathname parameter is not a directory, the file will fail to open.
        /// [zh] 如果参数pathname 所指的文件并非为一目录，则会令打开文件失败。
        public static let directory = OpenFlag(rawValue: O_DIRECTORY)
        
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
}
#endif
