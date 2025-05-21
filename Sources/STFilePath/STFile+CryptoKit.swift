//
//  STFile+.swift
//  STFilePath
//
//  Created by linhey on 4/3/25.
//


#if canImport(CryptoKit)
import CryptoKit
import Foundation

public enum STHasherKind {
    case sha256
    case sha384
    case sha512
    case md5
    
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
    
    public func hash(with data: Data) throws -> String {
        var hasher = hasher
        hasher.update(data: data)
        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    public func hash(with file: STFile) throws -> String {
        try file.hash(with: self)
    }
    
}

public extension STFile {
    
    func hash(with kind: STHasherKind) throws -> String {
        return try hash(with: kind.hasher)
    }
    
    func hash<Hasher: HashFunction>(with hasher: Hasher) throws -> String {
        let handle = try handle(.reading)
        defer { handle.closeFile() }
        var hasher = hasher
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 1024 * 1024) // 分块读取（避免内存爆炸）
            if data.isEmpty { return false } // 结束循环
            hasher.update(data: data)
            return true
        }) { /* Continue */ }
        
        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
}
#endif
