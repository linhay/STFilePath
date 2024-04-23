//
//  File.swift
//  
//
//  Created by linhey on 2022/9/8.
//

import Foundation

public enum STFilePathReferenceType: Identifiable, STPathProtocol {
    
    case file(STFile)
    case folder(STFolder)
    
    public init(_ url: URL) throws {
        guard let item = STPath(url).referenceType else {
            throw STPathError(message: "不存在真实扽文件路径")
        }
        self = item
    }
    
    public var id: URL { url }

    
    public var url: URL {
        switch self {
        case .file(let result):   return result.id
        case .folder(let result): return result.id
        }
    }
        
    public var type: STFilePathItemType {
        switch self {
        case .file:   return .file
        case .folder: return .folder
        }
    }
    
    public var typeID: String {
        switch self {
        case .file:   return "file"
        case .folder: return "folder"
        }
    }
    
    public var path: STPath {
        return STPath(id)
    }
    
}
