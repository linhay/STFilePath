//
//  Test.swift
//  STFilePath
//
//  Created by linhey on 7/31/25.
//

import Foundation
import STFilePath
import Testing

struct CompressionTest {
    
    @Test func testCompressionRoundTrip() throws {
        let text = Array(repeating: "测试字符串或大数据", count: 10000).joined()
        let algorithm = STComparator.Algorithm.zlib
        let original = Data(text.utf8)
        let compressed = try STComparator.compress(original, algorithm: algorithm)
        let decompressed = try STComparator.decompress(compressed, algorithm: algorithm)
        let decompressedText = String(data: decompressed, encoding: .utf8)
        assert(decompressedText == text, "Decompressed text does not match original text")
        assert(original == decompressed, "Decompressed data does not match original")
    }

}
