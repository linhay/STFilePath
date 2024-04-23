//
//  File.swift
//  
//
//  Created by linhey on 2022/9/8.
//

import Foundation

public enum STFilePathItemType: Int, Equatable, Codable {
    
    case file
    case folder
    case notExist
    
    public var isFile: Bool   { self == .file }
    public var isFolder: Bool { self == .folder }
    public var isExist: Bool  { self != .notExist }
    
}
