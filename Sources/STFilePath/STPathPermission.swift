
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

/// [en] A struct that represents the permissions of a path.
/// [zh] 一个表示路径权限的结构体。
public struct STPathPermission: OptionSet, Comparable, Sendable {
    
    public static func < (lhs: STPathPermission, rhs: STPathPermission) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    /// [en] No permissions.
    /// [zh] 没有权限。
    public static let none       = STPathPermission([])
    /// [en] The path exists.
    /// [zh] 路径存在。
    public static let exists     = STPathPermission(rawValue: 1 << 0)
    /// [en] The path is readable.
    /// [zh] 路径可读。
    public static let readable   = STPathPermission(rawValue: 1 << 1)
    /// [en] The path is writable.
    /// [zh] 路径可写。
    public static let writable   = STPathPermission(rawValue: 1 << 2)
    /// [en] The path is executable.
    /// [zh] 路径可执行。
    public static let executable = STPathPermission(rawValue: 1 << 3)
    /// [en] The path is deletable.
    /// [zh] 路径可删除。
    public static let deletable  = STPathPermission(rawValue: 1 << 4)

    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// [en] Initializes a new `STPathPermission` instance from a URL.
    /// [zh] 从 URL 初始化一个新的 `STPathPermission` 实例。
    /// - Parameter url: The URL of the path.
    public init(url: URL) {
        self.init(path: url.path)
    }
    
    /// [en] Initializes a new `STPathPermission` instance from a path string.
    /// [zh] 从路径字符串初始化一个新的 `STPathPermission` 实例。
    /// - Parameter path: The path string.
    public init(path: String) {
        let manager = FileManager.default
        var list = [STPathPermission]()
        
        guard manager.isExecutableFile(atPath: path) else {
            self.init(list)
            return
        }
        
        list.append(.exists)
        
        if manager.isReadableFile(atPath: path) {
            list.append(.readable)
        }
        
        if manager.isWritableFile(atPath: path) {
            list.append(.writable)
        }
        
        if manager.isDeletableFile(atPath: path) {
            list.append(.deletable)
        }
        
        if manager.isExecutableFile(atPath: path) {
            list.append(.executable)
        }
        
        self.init(list)
    }
    
}


public extension STPathPermission {
    
    /// [en] A struct that represents the permissions of a path on a POSIX system.
    /// [zh] 一个表示 POSIX 系统上路径权限的结构体。
    struct Posix: OptionSet, Comparable, Sendable {
        
        public static func < (lhs: STPathPermission.Posix, rhs: STPathPermission.Posix) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        public let rawValue: UInt16
        
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        public static let ownerRead      = Posix(rawValue: 0o400)
        public static let ownerWrite     = Posix(rawValue: 0o200)
        public static let ownerExecute   = Posix(rawValue: 0o100)
        public static let ownerAll: Posix = [.ownerRead, .ownerWrite, .ownerExecute]
        
        public static let groupRead      = Posix(rawValue: 0o040)
        public static let groupWrite     = Posix(rawValue: 0o020)
        public static let groupExecute   = Posix(rawValue: 0o010)
        public static let groupAll: Posix = [.groupRead, .groupWrite, .groupExecute]
        
        public static let othersRead     = Posix(rawValue: 0o004)
        public static let othersWrite    = Posix(rawValue: 0o002)
        public static let othersExecute  = Posix(rawValue: 0o001)
        public static let othersAll: Posix = [.othersRead, .othersWrite, .othersExecute]
        
        public static let all: Posix = [.ownerAll, .groupAll, .othersAll]
        public static let `default`: Posix = [.ownerAll, .groupRead, .groupExecute, .othersRead, .othersExecute]
        
        public init(fileURL: URL) throws {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            self.init(rawValue: attributes[.posixPermissions] as? UInt16 ?? 0)
        }
    }
    
}
