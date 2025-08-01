//
//  File.swift
//  
//
//  Created by linhey on 2022/9/8.
//

import Foundation

/// [en] The type of a file system item.
/// [zh] 文件系统项的类型。
public enum STFilePathItemType: Int, Equatable, Codable, Sendable {
    
    /// [en] The item is a file.
    /// [zh] 该项是文件。
    case file
    /// [en] The item is a folder.
    /// [zh] 该项是文件夹。
    case folder
    /// [en] The item does not exist.
    /// [zh] 该项不存在。
    case notExist
    
    /// [en] Whether the item is a file.
    /// [zh] 该项是否是文件。
    public var isFile: Bool   { self == .file }
    /// [en] Whether the item is a folder.
    /// [zh] 该项是否是文件夹。
    public var isFolder: Bool { self == .folder }
    /// [en] Whether the item exists.
    /// [zh] 该项是否存在。
    public var isExist: Bool  { self != .notExist }
    
}
