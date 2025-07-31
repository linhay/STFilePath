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

// STPathProtocol: 文件路径协议，定义文件路径所需的基本属性和方法。
public protocol STPathProtocol: Identifiable, Hashable {
    
    // 文件类型
    // Type of file
    var type: STFilePathItemType { get }

    // 文件路径的URL
    // URL for the file path
    var url: URL { get }

    // 文件id，方便在数组中处理重复数据
    // Unique identifier for the file to handle duplicate data in an array
    var id: URL {get }

    // 使用文件路径的URL初始化协议
    // Initialize the protocol using the URL for the file path
    init(_ url: URL) throws
    
}

public extension STPathProtocol {
    
    var isExistFolder: Bool {
        do {
            return try Self.isFolder(url)
        } catch {
            return false
        }
    }
    
    var isExistFile: Bool {
        do {
            return try Self.isFile(url)
        } catch {
            return false
        }
    }

    static func isFile(_ url: URL) throws -> Bool {
        return try isFile(url.path)
    }
    
    static func isFile(_ path: String) throws -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                return false
            } else {
                return true
            }
        } else {
            throw STPathError(message: "目标路径文件不存在: \(path)")
        }
    }
    
    static func isFolder(_ url: URL) throws -> Bool {
        return try isFolder(url.path)
    }
    
    static func isFolder(_ path: String) throws -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                return true
            } else {
                return false
            }
        } else {
            throw STPathError(message: "目标路径文件不存在: \(path)")
        }
    }
    
}

public extension STPathProtocol {
    
    var asFile: STFile? {
        if let type = self as? STFile {
            return type
        } else if let path = self as? STPath, path.isExistFile {
            return .init(url)
        } else if type == .file {
            return .init(url)
        } else {
            return nil
        }
    }
    
    var asFolder: STFolder? {
        if let type = self as? STFolder {
            return type
        } else if let path = self as? STPath, path.isExistFolder {
            return .init(url)
        } else if type == .folder {
            return .init(url)
        } else {
            return nil
        }
    }
    
}

extension STPathProtocol {
    
    // path属性：返回文件路径的字符串
    // path property: Returns the file path as a string
    public var path: String { url.path }
    
    // path属性：返回文件路径的字符串
    // path property: Returns the file path as a string
    public var id: URL { url }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }
    
}

extension STPathProtocol {
    var manager: FileManager { FileManager.default }
}

#if !os(Linux)
public extension STPathProtocol {
    
    func stopAccessingSecurityScopedResource() {
        url.stopAccessingSecurityScopedResource()
    }
   
    @discardableResult
    func startAccessingSecurityScopedResource() throws -> Bool {
        return url.startAccessingSecurityScopedResource()
    }
    
}
#endif

public extension STPathProtocol {

    func relativePath(from base: STFile) -> String {
        relativePath(from: base.parentFolder()!)
    }
    
    func relativePath(from base: STFolder, prefix: String = "") -> String {
        let destComponents = url.standardized.pathComponents
        let baseComponents = base.url.standardized.pathComponents
        // Find number of common path components:
        var i = 0
        while i < destComponents.count && i < baseComponents.count
            && destComponents[i] == baseComponents[i] {
                i += 1
        }
        // Build relative path:
        var relComponents = Array(repeating: "..", count: baseComponents.count - i)
        relComponents.append(contentsOf: destComponents[i...])
        return prefix + relComponents.joined(separator: "/")
    }
    
    static func standardizedPath(_ path: String) -> URL {
        if path == "~" {
#if os(Linux)
            return URL(fileURLWithPath: "/")
#else
            return STFolder.Sanbox.home.url
#endif
        } else if path.hasPrefix("~/") {
            var components = path.split(separator: "/").map({ $0.description })
            components = Array(components.dropFirst())
#if os(Linux)
            let home = [String]()
#else
            let home = STFolder.Sanbox.home.url.path.split(separator: "/").map(\.description)
#endif
            components.insert(contentsOf: home, at: 0)
            return URL(fileURLWithPath: Self.standardizedPath(components))
        } else if let url = URL(string: path),
                  url.scheme != nil,
                  !url.isFileURL {
            return url
        } else {
            return URL(fileURLWithPath: path)
        }
    }
    
    private static func standardizedPath<S>(_ components: [S]) -> String where S: StringProtocol {
        var result = [S]()
        for component in components {
            switch component {
            case "..":
                result = result.dropLast()
            case ".":
                break
            default:
                result.append(component)
            }
        }
        return "/" + result.joined(separator: "/")
    }
    
}

public extension STPathProtocol {
    
    var attributes: STPathAttributes { .init(path: url) }

}


public extension STPathProtocol {
    
    var eraseToAnyPath: STPath { return .init(url) }
            
    /// 文件权限
    var permission: STPathPermission { .init(url: url) }
    
    /// 当前路径是否存在
    var isExist: Bool { manager.fileExists(atPath: url.path) }
    
    /// 修改名称
    func rename(_ name: String) throws -> Self {
        let new = url.deletingLastPathComponent().appendingPathComponent(name)
        try manager.moveItem(at: url, to: new)
        return try .init(new)
    }
    
    /// 删除
    /// - Throws: FileManager error
    func delete() throws {
        guard isExist else { return }
        try manager.removeItem(at: url)
    }
    
    /// 移动至目标路径
    /// - Parameters:
    ///   - folder: 目标路径
    ///   - isOverlay: 目标目录存在相应文件, 是否覆盖
    /// - Returns: FileManagerError
    @discardableResult
    func move<Item: STPathProtocol>(to path: Item, isOverlay: Bool = false) throws -> Item {
        if isOverlay, path.isExist {
            try path.delete()
        }
        if path.parentFolder()?.isExist == false {
            try path.parentFolder()?.create()
        }
        try manager.moveItem(at: url, to: path.url)
        return path
    }
    
    @discardableResult
    func copy<Item: STPathProtocol>(to path: Item, isOverlay: Bool = false) throws -> Item {
        if isOverlay, path.isExist {
            try path.delete()
        }
        if path.parentFolder()?.isExist == false {
            try path.parentFolder()?.create()
        }
        try manager.copyItem(at: url, to: path.url)
        return path
    }

    /// 移动至目标路径
    /// - Parameters:
    ///   - folder: 目标路径
    ///   - isOverlay: 目标目录存在相应文件, 是否覆盖
    /// - Returns: FileManagerError
    @discardableResult
    func move(into folder: STFolder, isOverlay: Bool = false) throws -> Self {
        let path = folder.subpath(attributes.name)
        let result = try move(to: path, isOverlay: isOverlay)
        return try .init(result.url)
    }
    
    /// 复制至目标路径
    /// - Parameters:
    ///   - folder: 目标路径
    ///   - isOverlay: 目标目录存在相应文件, 是否覆盖
    /// - Returns: FileManagerError
    @discardableResult
    func copy(into folder: STFolder, isOverlay: Bool = false) throws -> Self {
        let path = folder.subpath(attributes.name)
        let result = try copy(to: path, isOverlay: isOverlay)
        return try .init(result.url)
    }
    
    /// 获取所在文件夹
    /// - Returns: 所在文件夹
    func parentFolder() -> STFolder? {
        let parent = url.deletingLastPathComponent()
        guard Self.standardizedPath(parent.path) != Self.standardizedPath(url.path) else {
            return nil
        }
        return .init(parent)
    }
    
}
