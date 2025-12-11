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

/// [en] A protocol that defines the basic properties and methods required for a file path.
/// [zh] 文件路径协议，定义文件路径所需的基本属性和方法。
public protocol STPathProtocol: Identifiable, Hashable {
    
    /// [en] The type of the file system item.
    /// [zh] 文件系统项的类型。
    var type: STFilePathItemType { get }

    /// [en] The URL of the file path.
    /// [zh] 文件路径的 URL。
    var url: URL { get }

    /// [en] A unique identifier for the file, useful for handling duplicate data in an array.
    /// [zh] 文件的唯一标识符，方便在数组中处理重复数据。
    var id: URL {get }

    /// [en] Initializes the protocol with the URL of the file path.
    /// [zh] 使用文件路径的 URL 初始化协议。
    init(_ url: URL) throws
    
}

public extension STPathProtocol {
    
    /// [en] Checks if the path points to an existing folder.
    /// [zh] 检查路径是否指向一个存在的文件夹。
    var isFolderExists: Bool {
        do {
            return try Self.isFolder(url)
        } catch {
            return false
        }
    }
    
    @available(*, deprecated, renamed: "isFolderExists")
    var isExistFolder: Bool { isFolderExists }
    
    /// [en] Checks if the path points to an existing file.
    /// [zh] 检查路径是否指向一个存在的文件。
    var isFileExists: Bool {
        do {
            return try Self.isFile(url)
        } catch {
            return false
        }
    }

    @available(*, deprecated, renamed: "isFileExists")
    var isExistFile: Bool { isFileExists }

    /// [en] Checks if the given URL points to a file.
    /// [zh] 检查给定的 URL 是否指向一个文件。
    /// - Parameter url: The URL to check.
    /// - Returns: `true` if the URL points to a file.
    /// - Throws: An error if the file does not exist at the path.
    static func isFile(_ url: URL) throws -> Bool {
        return try isFile(url.path)
    }
    
    /// [en] Checks if the given path string points to a file.
    /// [zh] 检查给定的路径字符串是否指向一个文件。
    /// - Parameter path: The path string to check.
    /// - Returns: `true` if the path points to a file.
    /// - Throws: An error if the file does not exist at the path.
    static func isFile(_ path: String) throws -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                return false
            } else {
                return true
            }
        } else {
            throw STPathError(message: "[en] Target path file does not exist: \(path) \n [zh] 目标路径文件不存在: \(path)")
        }
    }
    
    /// [en] Checks if the given URL points to a folder.
    /// [zh] 检查给定的 URL 是否指向一个文件夹。
    /// - Parameter url: The URL to check.
    /// - Returns: `true` if the URL points to a folder.
    /// - Throws: An error if the folder does not exist at the path.
    static func isFolder(_ url: URL) throws -> Bool {
        return try isFolder(url.path)
    }
    
    /// [en] Checks if the given path string points to a folder.
    /// [zh] 检查给定的路径字符串是否指向一个文件夹。
    /// - Parameter path: The path string to check.
    /// - Returns: `true` if the path points to a folder.
    /// - Throws: An error if the folder does not exist at the path.
    static func isFolder(_ path: String) throws -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                return true
            } else {
                return false
            }
        } else {
            throw STPathError(message: "[en] Target path folder does not exist: \(path) \n [zh] 目标路径文件夹不存在: \(path)")
        }
    }
    
}

public extension STPathProtocol {
    
    /// [en] Returns this path as an `STFile` if it represents a file.
    /// [zh] 如果此路径代表一个文件，则将其作为 `STFile` 返回。
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
    
    /// [en] Returns this path as an `STFolder` if it represents a folder.
    /// [zh] 如果此路径代表一个文件夹，则将其作为 `STFolder` 返回。
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
    
    /// [en] The string representation of the path.
    /// [zh] 路径的字符串表示形式。
    public var path: String { url.path }
    
    /// [en] A unique identifier for the path.
    /// [zh] 路径的唯一标识符。
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
    
    /// [en] Stops accessing the security-scoped resource.
    /// [zh] 停止访问安全范围的资源。
    func stopAccessingSecurityScopedResource() {
        url.stopAccessingSecurityScopedResource()
    }
   
    /// [en] Starts accessing the security-scoped resource.
    /// [zh] 开始访问安全范围的资源。
    /// - Returns: `true` if access was granted, `false` otherwise.
    /// - Throws: An error if the resource cannot be accessed.
    @discardableResult
    func startAccessingSecurityScopedResource() throws -> Bool {
        return url.startAccessingSecurityScopedResource()
    }
    
}
#endif

public extension STPathProtocol {

    /// [en] Returns the relative path from a base file.
    /// [zh] 返回相对于基文件的相对路径。
    /// - Parameter base: The base file to calculate the relative path from.
    /// - Returns: The relative path string.
    func relativePath(from base: STFile) -> String {
        relativePath(from: base.parentFolder()!)
    }
    
    /// [en] Returns the relative path from a base folder.
    /// [zh] 返回相对于基文件夹的相对路径。
    /// - Parameters:
    ///   - base: The base folder to calculate the relative path from.
    ///   - prefix: A string to prepend to the relative path.
    /// - Returns: The relative path string.
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
    
    /// [en] Creates a standardized URL from a path string. Handles special cases like `~` and `~/`.
    /// [zh] 从路径字符串创建标准化的 URL。处理特殊情况，如 `~` 和 `~/`。
    /// - Parameter path: The path string to standardize.
    /// - Returns: A standardized URL.
    static func standardizedPath(_ path: String) -> URL {
        if path == "~" {
#if os(Linux)
            return URL(fileURLWithPath: NSHomeDirectory())
#else
            return STFolder.Sanbox.home.url
#endif
        } else if path.hasPrefix("~/") {
            var components = path.split(separator: "/").map({ $0.description })
            components = Array(components.dropFirst())
#if os(Linux)
            let home = NSHomeDirectory().split(separator: "/").map(\.description)
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
    
    /// [en] The attributes of the path.
    /// [zh] 路径的属性。
    var attributes: STPathAttributes { .init(path: url) }

}


public extension STPathProtocol {
    
    /// [en] Erases the specific type of the path to `STPath`.
    /// [zh] 将路径的特定类型擦除为 `STPath`。
    var eraseToAnyPath: STPath { return .init(url) }
            
    /// [en] The permissions of the path.
    /// [zh] 路径的权限。
    var permission: STPathPermission { .init(url: url) }
    
    /// [en] Checks if the path exists.
    /// [zh] 检查路径是否存在。
    @available(*, deprecated, renamed: "isExists")
    var isExist: Bool { isExists }
    var isExists: Bool { manager.fileExists(atPath: url.path) }

    /// [en] Renames the file or folder.
    /// [zh] 重命名文件或文件夹。
    /// - Parameter name: The new name for the item.
    /// - Returns: An instance of the conforming type with the new name.
    /// - Throws: An error if the rename operation fails.
    func rename(_ name: String) throws -> Self {
        let new = url.deletingLastPathComponent().appendingPathComponent(name)
        try manager.moveItem(at: url, to: new)
        return try .init(new)
    }
    
    /// [en] Deletes the file or folder.
    /// [zh] 删除文件或文件夹。
    /// - Throws: An error if the deletion fails.
    func delete() throws {
        guard isExist else { return }
        try manager.removeItem(at: url)
    }
    
    /// [en] Moves the item to a new path.
    /// [zh] 将项目移动到新路径。
    /// - Parameters:
    ///   - path: The destination path.
    ///   - isOverlay: If `true`, the destination will be overwritten if it exists.
    /// - Returns: The destination item.
    /// - Throws: An error if the move operation fails.
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
    
    /// [en] Copies the item to a new path.
    /// [zh] 将项目复制到新路径。
    /// - Parameters:
    ///   - path: The destination path.
    ///   - isOverlay: If `true`, the destination will be overwritten if it exists.
    /// - Returns: The copied item at the destination.
    /// - Throws: An error if the copy operation fails.
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

    /// [en] Moves the item into a destination folder.
    /// [zh] 将项目移动到目标文件夹中。
    /// - Parameters:
    ///   - folder: The destination folder.
    ///   - isOverlay: If `true`, the destination will be overwritten if it exists.
    /// - Returns: The moved item in the new folder.
    /// - Throws: An error if the move operation fails.
    @discardableResult
    func move(into folder: STFolder, isOverlay: Bool = false) throws -> Self {
        let path = folder.subpath(attributes.name)
        let result = try move(to: path, isOverlay: isOverlay)
        return try .init(result.url)
    }
    
    /// [en] Copies the item into a destination folder.
    /// [zh] 将项目复制到目标文件夹中。
    /// - Parameters:
    ///   - folder: The destination folder.
    ///   - isOverlay: If `true`, the destination will be overwritten if it exists.
    /// - Returns: The copied item in the new folder.
    /// - Throws: An error if the copy operation fails.
    @discardableResult
    func copy(into folder: STFolder, isOverlay: Bool = false) throws -> Self {
        let path = folder.subpath(attributes.name)
        let result = try copy(to: path, isOverlay: isOverlay)
        return try .init(result.url)
    }
    
    /// [en] Returns the parent folder of the current path.
    /// [zh] 返回当前路径的父文件夹。
    /// - Returns: The parent `STFolder`, or `nil` if it's the root.
    func parentFolder() -> STFolder? {
        let parent = url.deletingLastPathComponent()
        guard Self.standardizedPath(parent.path) != Self.standardizedPath(url.path) else {
            return nil
        }
        return .init(parent)
    }
    
}
