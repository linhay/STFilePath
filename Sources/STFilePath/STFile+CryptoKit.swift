//
//  STFile+.swift
//  STFilePath
//
//  Created by linhey on 4/3/25.
//


#if canImport(CryptoKit)
import CryptoKit
import Foundation

/// [en] The kind of hasher to use.
/// [zh] 要使用的哈希算法类型。
public enum STHasherKind {
    case sha256
    case sha384
    case sha512
    case md5
    
    /// [en] The `HashFunction` for the hasher kind.
    /// [zh] 哈希算法类型对应的 `HashFunction`。
    public var hasher: any HashFunction {
        switch self {
        case .sha256:
            return SHA256()
        case .sha512:
            return SHA512()
        case .sha384:
            return SHA384()
        case .md5:
            return Insecure.MD5()
        }
    }
    
    /// [en] Hashes the given data.
    /// [zh] 对给定的数据进行哈希。
    /// - Parameter data: The data to hash.
    /// - Returns: The hash string.
    /// - Throws: An error if hashing fails.
    public func hash(with data: Data) throws -> String {
        var hasher = hasher
        hasher.update(data: data)
        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// [en] Hashes the given file.
    /// [zh] 对给定的文件进行哈希。
    /// - Parameter file: The file to hash.
    /// - Returns: The hash string.
    /// - Throws: An error if hashing fails.
    public func hash(with file: STFile) throws -> String {
        try file.hash(with: self)
    }
    
}

public extension STFile {
    
    /// [en] Hashes the file with the given hasher kind.
    /// [zh] 使用给定的哈希算法类型对文件进行哈希。
    /// - Parameter kind: The hasher kind to use.
    /// - Returns: The hash string.
    /// - Throws: An error if hashing fails.
    func hash(with kind: STHasherKind) throws -> String {
        return try hash(with: kind.hasher)
    }
    
    /// [en] Hashes the file with the given hasher.
    /// [zh] 使用给定的哈希算法对文件进行哈希。
    /// - Parameter hasher: The hasher to use.
    /// - Returns: The hash string.
    /// - Throws: An error if hashing fails.
    func hash<Hasher: HashFunction>(with hasher: Hasher) throws -> String {
        let handle = try handle(.reading)
        defer { handle.closeFile() }
        var hasher = hasher
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 1024 * 1024) // [en] Read in chunks (to avoid memory explosion) 
            if data.isEmpty { return false } // [en] End of loop
            hasher.update(data: data)
            return true
        }) { /* Continue */ }
        
        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
}
#endif
