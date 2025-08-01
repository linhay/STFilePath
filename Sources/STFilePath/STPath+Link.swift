
//
//  STPath+Link.swift
//  
//
//  Created by linhey on 2025/8/1.
//

import Foundation

public extension STPathProtocol {

    /// [en] A boolean value indicating whether the path is a symbolic link.
    /// [zh] 一个布尔值，指示路径是否为符号链接。
    var isSymbolicLink: Bool {
        (try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)) != nil
    }

    /// [en] Creates a symbolic link at the specified path that points to the destination.
    /// [zh] 在指定路径创建一个指向目标的符号链接。
    /// - Parameters:
    ///   - path: The path at which to create the symbolic link.
    ///   - destination: The destination path that the link will point to.
    /// - Throws: An error if the link cannot be created.
    func createSymbolicLink(to destination: any STPathProtocol) throws {
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: destination.url)
    }
    
    /// [en] Returns the destination of the symbolic link.
    /// [zh] 返回符号链接的目标。
    /// - Returns: The destination path of the symbolic link.
    /// - Throws: An error if the destination cannot be resolved.
    func destinationOfSymbolicLink() throws -> STPath {
        let destinationPath = try FileManager.default.destinationOfSymbolicLink(atPath: url.path)
        return STPath(destinationPath)
    }
}
