//
//  STFile+.swift
//  STFilePath
//
//  Created by linhey on 4/3/25.
//


#if canImport(CryptoKit)
import CryptoKit
import Foundation

public extension STFile {
    
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
