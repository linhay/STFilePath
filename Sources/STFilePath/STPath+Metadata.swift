//
//  STPath+Metadata.swift
//  
//
//  Created by linhey on 2025/8/1.
//

import Foundation
#if canImport(Darwin)
import Darwin
#endif

public extension STPathProtocol {

    /// [en] Sets the permissions for the file or folder.
    /// [zh] 设置文件或文件夹的权限。
    /// - Parameter permissions: The permissions to set.
    /// - Throws: An error if the permissions cannot be set.
    func set(permissions: STPathPermission.Posix) throws {
        try FileManager.default.setAttributes([.posixPermissions: permissions.rawValue], ofItemAtPath: url.path)
    }

    /// [en] Returns the permissions for the file or folder.
    /// [zh] 返回文件或文件夹的权限。
    /// - Returns: The permissions.
    /// - Throws: An error if the permissions cannot be retrieved.
    func permissions() throws -> STPathPermission.Posix {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let permissions = attributes[.posixPermissions] as? UInt16 {
            return STPathPermission.Posix(rawValue: permissions)
        }
        throw STPathError(message: "[en] Failed to get permissions. \n [zh] 获取权限失败。", code: 0)
    }

  
}

extension STPathProtocol {
    
    /// [en] Returns the extended attributes of the file or folder.
    /// [zh] 返回文件或文件夹的扩展属性。
    /// - Returns: An instance of `ExtendedAttributes`.
    var extendedAttributes: STExtendedAttributes {
        STExtendedAttributes(url: url)
    }
    
}


struct STExtendedAttributes {
    
    let url: URL
    
    #if canImport(Darwin)
    /// [en] Sets an extended attribute for the file or folder.
    /// [zh] 为文件或文件夹设置扩展属性。
    /// - Parameters:
    ///   - value: The value of the attribute.
    ///   - forName: The name of the attribute.
    /// - Throws: An error if the attribute cannot be set.
    func set(name: String, value: Data) throws {
        try url.path.withCString { fileSystemPath in
            let status = setxattr(fileSystemPath, name, value.withUnsafeBytes { $0.baseAddress! }, value.count, 0, 0)
            if status == -1 {
                throw STPathError(message: "[en] Failed to set extended attribute \(name). \n [zh] 设置扩展属性 \(name) 失败。", code: Int(errno))
            }
        }
    }

    /// [en] Returns the value of an extended attribute.
    /// [zh] 返回扩展属性的值。
    /// - Parameter forName: The name of the attribute.
    /// - Returns: The value of the attribute.
    /// - Throws: An error if the attribute cannot be retrieved.
    func value(of name: String) throws -> Data {
        try url.path.withCString { fileSystemPath in
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            if length == -1 {
                throw STPathError(message: "[en] Failed to get extended attribute \(name). \n [zh] 获取扩展属性 \(name) 失败。", code: Int(errno))
            }
            var data = Data(count: length)
            let result = data.withUnsafeMutableBytes { buffer in
                getxattr(fileSystemPath, name, buffer.baseAddress, length, 0, 0)
            }
            if result == -1 {
                throw STPathError(message: "[en] Failed to get extended attribute \(name). \n [zh] 获取扩展属性 \(name) 失败。", code: Int(errno))
            }
            return data
        }
    }

    /// [en] Removes an extended attribute from the file or folder.
    /// [zh] 从文件或文件夹中删除扩展属性。
    /// - Parameter forName: The name of the attribute to remove.
    /// - Throws: An error if the attribute cannot be removed.
    func remove(of name: String) throws {
        try url.path.withCString { fileSystemPath in
            let status = removexattr(fileSystemPath, name, 0)
            if status == -1 {
                throw STPathError(message: "[en] Failed to remove extended attribute \(name). \n [zh] 删除扩展属性 \(name) 失败。", code: Int(errno))
            }
        }
    }

    /// [en] Returns a list of all extended attributes.
    /// [zh] 返回所有扩展属性的列表。
    /// - Returns: A list of attribute names.
    /// - Throws: An error if the attributes cannot be retrieved.
    func list() throws -> [String] {
        try url.path.withCString { fileSystemPath in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            if length == -1 {
                throw STPathError(message: "[en] Failed to list extended attributes. \n [zh] 列出扩展属性失败。", code: Int(errno))
            }
            var buffer = [CChar](repeating: 0, count: length)
            let result = listxattr(fileSystemPath, &buffer, length, 0)
            if result == -1 {
                throw STPathError(message: "[en] Failed to list extended attributes. \n [zh] 列出扩展属性失败。", code: Int(errno))
            }
            return buffer.split(separator: 0).compactMap { String(cString: Array($0), encoding: .utf8) }
        }
    }
    #else
    /// [en] Extended attributes are not supported on this platform.
    /// [zh] 此平台不支持扩展属性。
    func set(name: String, value: Data) throws {
        throw STPathError(message: "[en] Extended attributes not supported on this platform. \n [zh] 此平台不支持扩展属性。", code: -1)
    }
    
    /// [en] Extended attributes are not supported on this platform.
    /// [zh] 此平台不支持扩展属性。
    func value(of name: String) throws -> Data {
        throw STPathError(message: "[en] Extended attributes not supported on this platform. \n [zh] 此平台不支持扩展属性。", code: -1)
    }
    
    /// [en] Extended attributes are not supported on this platform.
    /// [zh] 此平台不支持扩展属性。
    func remove(of name: String) throws {
        throw STPathError(message: "[en] Extended attributes not supported on this platform. \n [zh] 此平台不支持扩展属性。", code: -1)
    }
    
    /// [en] Extended attributes are not supported on this platform.
    /// [zh] 此平台不支持扩展属性。
    func list() throws -> [String] {
        throw STPathError(message: "[en] Extended attributes not supported on this platform. \n [zh] 此平台不支持扩展属性。", code: -1)
    }
    #endif
}