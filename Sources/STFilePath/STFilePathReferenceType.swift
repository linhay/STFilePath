//
//  File.swift
//  
//
//  Created by linhey on 2022/9/8.
//

import Foundation

/// [en] Represents the reference type of a file system item, which can be a file or a folder.
/// [zh] 表示文件系统项的引用类型，可以是文件或文件夹。
public enum STFilePathReferenceType: Identifiable, STPathProtocol {
    
    /// [en] The item is a file.
    /// [zh] 该项是文件。
    case file(STFile)
    /// [en] The item is a folder.
    /// [zh] 该项是文件夹。
    case folder(STFolder)
    
    /// [en] Initializes a new `STFilePathReferenceType` instance with the specified URL.
    /// [zh] 使用指定的 URL 初始化一个新的 `STFilePathReferenceType` 实例。
    /// - Parameter url: The URL of the file system item.
    /// - Throws: An error if the path does not exist.
    public init(_ url: URL) throws {
        guard let item = STPath(url).referenceType else {
            throw STPathError(message: "[en] No real file path exists \n [zh] 不存在真实文件路径")
        }
        self = item
    }
    
    /// [en] A unique identifier for the file system item.
    /// [zh] 文件系统项的唯一标识符。
    public var id: URL { url }

    
    /// [en] The URL of the file system item.
    /// [zh] 文件系统项的 URL。
    public var url: URL {
        switch self {
        case .file(let result):   return result.id
        case .folder(let result): return result.id
        }
    }
        
    /// [en] The type of the file system item.
    /// [zh] 文件系统项的类型。
    public var type: STFilePathItemType {
        switch self {
        case .file:   return .file
        case .folder: return .folder
        }
    }
    
    /// [en] A string identifier for the type of the file system item.
    /// [zh] 文件系统项类型的字符串标识符。
    public var typeID: String {
        switch self {
        case .file:   return "file"
        case .folder: return "folder"
        }
    }
    
    /// [en] The `STPath` of the file system item.
    /// [zh] 文件系统项的 `STPath`。
    public var path: STPath {
        return STPath(id)
    }
    
}
