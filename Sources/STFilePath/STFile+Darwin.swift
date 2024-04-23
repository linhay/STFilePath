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
    
    var system: System { System(filePath: self) }
        
    class System {
        
        let filePath: STFile
        
        init(filePath: STFile) {
            self.filePath = filePath
        }
        
    }
    
}

public extension STFile.System {

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
    
    func stat(descriptor: Int32) throws -> Darwin.stat {
        var result = Darwin.stat()
        let flag = fstat(descriptor, &result)
        if flag != 0 {
            throw STPathError(message: "赋值文件属性错误", code: Int(flag))
        }
        return result
    }
    
    /// 4k对齐
    private func alignmentPageSize(from size: Int) -> Int {
        let pageSize = Int(vm_page_size)
        let count = size / pageSize + size % pageSize == 0 ? 0 : 1
        return pageSize * count
    }
    
    /// truncate会将参数fd指定的文件大小改为参数length指定的大小
    func truncate(descriptor: Int32, size: Int) throws {
        if ftruncate(descriptor, .init(size)) == -1 {
           throw STPathError(posix: Darwin.errno)
        }
    }
    
    /// fsync函数同步内存中所有已修改的文件数据到储存设备。
    func sync(descriptor: Int32) throws {
        if fsync(descriptor) == -1 {
           throw STPathError(posix: Darwin.errno)
        }
    }
    
    func mmap(prot: MMAPProt = [.read, .write],
              type: MMAPType = .file,
              shareType: MMAPShareType = .share,
              size: Int? = nil,
              offset: Int = 0) throws -> MMAP {
        
        guard filePath.isExist else {
            throw STPathError(message: "Cannot open '\(filePath.url.absoluteURL)'")
        }
        
        let descriptor = try open(flag1: .readAndWrite, flag2: nil, mode: nil)
        do {
            let info = try stat(descriptor: descriptor)
            let fileSize = info.st_size
            let size = alignmentPageSize(from: size ?? Int(fileSize))
            
            guard size > 0 else {
                throw STPathError(message: "size 必须大于 0")
            }
            
            try truncate(descriptor: descriptor, size: size)
            try sync(descriptor: descriptor)
            
            return try MMAP(descriptor: descriptor,
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

public extension STFile.System {
    
    struct OpenMode: OptionSet {
        /// S_IRWXU 00700 权限, 代表该文件所有者具有可读、可写及可执行的权限.
        public static let irwxu  = OpenMode(rawValue: S_IRWXU)
        /// S_IRUSR 或S_IREAD, 00400 权限, 代表该文件所有者具有可读取的权限.
        public static let iruser = OpenMode(rawValue: S_IRUSR)
        public static let iread  = OpenMode(rawValue: S_IREAD)
        /// S_IWUSR 或S_IWRITE, 00200 权限, 代表该文件所有者具有可写入的权限.
        public static let iwuser = OpenMode(rawValue: S_IWUSR)
        public static let iwrite = OpenMode(rawValue: S_IWRITE)
        /// S_IXUSR 或S_IEXEC, 00100 权限, 代表该文件所有者具有可执行的权限.
        public static let ixuser = OpenMode(rawValue: S_IXUSR)
        public static let iexec  = OpenMode(rawValue: S_IEXEC)
        /// S_IRWXG 00070 权限, 代表该文件用户组具有可读、可写及可执行的权限.
        public static let irwxg  = OpenMode(rawValue: S_IRWXG)
        /// S_IRGRP 00040 权限, 代表该文件用户组具有可读的权限.
        public static let irgrp  = OpenMode(rawValue: S_IRGRP)
        /// S_IWGRP 00020 权限, 代表该文件用户组具有可写入的权限.
        public static let iwgrp  = OpenMode(rawValue: S_IWGRP)
        /// S_IXGRP 00010 权限, 代表该文件用户组具有可执行的权限.
        public static let ixgrp  = OpenMode(rawValue: S_IXGRP)
        /// S_IRWXO 00007 权限, 代表其他用户具有可读、可写及可执行的权限.
        public static let irwxo  = OpenMode(rawValue: S_IRWXO)
        /// S_IROTH 00004 权限, 代表其他用户具有可读的权限
        public static let iroth  = OpenMode(rawValue: S_IROTH)
        /// S_IWOTH 00002 权限, 代表其他用户具有可写入的权限.
        public static let iwoth  = OpenMode(rawValue: S_IWOTH)
        /// S_IXOTH 00001 权限, 代表其他用户具有可执行的权限.
        public static let ixoth  = OpenMode(rawValue: S_IXOTH)
        
        public let rawValue: mode_t
        public init(rawValue: mode_t) {
            self.rawValue = rawValue
        }
    }
    
    enum OpenType: Int32 {
        /// O_RDONLY 以只读方式打开文件
        case readOnly     = 0
        /// O_WRONLY 以只写方式打开文件
        case writeOnly    = 1
        /// O_RDWR 以可读写方式打开文件. 上述三种旗标是互斥的, 也就是不可同时使用, 但可与下列的旗标利用OR(|)运算符组合.
        case readAndWrite = 2
        case accMode      = 3
    }
    
    struct OpenFlag: OptionSet {
        /// 若欲打开的文件不存在则自动建立该文件.
        public static let create   = OpenFlag(rawValue: O_CREAT)
        /// 如果O_CREAT 也被设置, 此指令会去检查文件是否存在. 文件若不存在则建立该文件, 否则将导致打开文件错误. 此外, 若O_CREAT 与O_EXCL 同时设置, 并且欲打开的文件为符号连接, 则会打开文件失败.
        public static let excl     = OpenFlag(rawValue: O_EXCL)
        /// 如果欲打开的文件为终端机设备时, 则不会将该终端机当成进程控制终端机.
        public static let noctty   = OpenFlag(rawValue: O_NOCTTY)
        /// 若文件存在并且以可写的方式打开时, 此旗标会令文件长度清为0, 而原来存于该文件的资料也会消失.
        public static let trunc    = OpenFlag(rawValue: O_TRUNC)
        /// 当读写文件时会从文件尾开始移动, 也就是所写入的数据会以附加的方式加入到文件后面.
        public static let append   = OpenFlag(rawValue: O_APPEND)
        /// 以不可阻断的方式打开文件, 也就是无论有无数据读取或等待, 都会立即返回进程之中.
        public static let nonBlock = OpenFlag(rawValue: O_NONBLOCK)
        /// 同O_NONBLOCK.
        public static let ndelay = OpenFlag(rawValue: O_NDELAY)
        /// 以同步的方式打开文件.
        public static let sync      = OpenFlag(rawValue: O_SYNC)
        /// 如果参数pathname 所指的文件为一符号连接, 则会令打开文件失败.
        public static let nofollow  = OpenFlag(rawValue: O_NOFOLLOW)
        /// 如果参数pathname 所指的文件并非为一目录, 则会令打开文件失败
        public static let directory = OpenFlag(rawValue: O_DIRECTORY)
        
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
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
    
}
#endif
