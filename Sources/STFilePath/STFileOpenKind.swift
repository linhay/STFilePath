//
//  File.swift
//  
//
//  Created by linhey on 2024/3/12.
//

import Foundation

/// [en] The kind of operation to perform on a file.
/// [zh] 对文件执行的操作类型。
public enum STFileOpenKind {
    /// [en] Open the file for writing.
    /// [zh] 打开文件进行写入。
    case writing
    /// [en] Open the file for reading.
    /// [zh] 打开文件进行读取。
    case reading
    /// [en] Open the file for updating.
    /// [zh] 打开文件进行更新。
    case updating
}
