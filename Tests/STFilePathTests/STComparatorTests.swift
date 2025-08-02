import Testing
import STFilePath
import Foundation

@Suite("STComparator Tests")
struct STComparatorTests {
    
    @Test("Basic Compression and Decompression")
    func testBasicCompressionDecompression() throws {
        #if canImport(Compression)
        let originalData = "This is a test string for compression. It should compress well because it has repeating patterns and common words.".data(using: .utf8)!
        
        // Test ZLIB compression
        let compressedData = try STComparator.compress(originalData, algorithm: .zlib)
        #expect(compressedData.count > 0)
        #expect(compressedData.count < originalData.count) // Should be smaller
        
        let decompressedData = try STComparator.decompress(compressedData, algorithm: .zlib)
        #expect(decompressedData == originalData)
        #endif
    }
    
    @Test("Different Compression Algorithms")
    func testDifferentCompressionAlgorithms() throws {
        #if canImport(Compression)
        let testData = String(repeating: "ABCDEFGHIJ", count: 100).data(using: .utf8)!
        
        let algorithms: [STComparator.Algorithm] = [.lz4, .zlib, .lzfse, .lzma]
        
        for algorithm in algorithms {
            let compressed = try STComparator.compress(testData, algorithm: algorithm)
            #expect(compressed.count > 0)
            
            let decompressed = try STComparator.decompress(compressed, algorithm: algorithm)
            #expect(decompressed == testData)
        }
        #endif
    }
    
    @Test("Empty Data Compression")
    func testEmptyDataCompression() throws {
        #if canImport(Compression)
        let emptyData = Data()
        
        let compressed = try STComparator.compress(emptyData, algorithm: .zlib)
        let decompressed = try STComparator.decompress(compressed, algorithm: .zlib)
        
        #expect(decompressed == emptyData)
        #endif
    }
    
    @Test("Small Data Compression")
    func testSmallDataCompression() throws {
        #if canImport(Compression)
        let smallData = "Hi".data(using: .utf8)!
        
        let compressed = try STComparator.compress(smallData, algorithm: .lz4)
        let decompressed = try STComparator.decompress(compressed, algorithm: .lz4)
        
        #expect(decompressed == smallData)
        #endif
    }
    
    @Test("Large Data Compression")
    func testLargeDataCompression() throws {
        #if canImport(Compression)
        // Create a large dataset with patterns that should compress well
        let pattern = "This is a repeating pattern that should compress very well. "
        let largeData = String(repeating: pattern, count: 1000).data(using: .utf8)!
        
        let compressed = try STComparator.compress(largeData, algorithm: .zlib)
        #expect(compressed.count > 0)
        #expect(compressed.count < largeData.count) // Should achieve good compression ratio
        
        let decompressed = try STComparator.decompress(compressed, algorithm: .zlib)
        #expect(decompressed == largeData)
        
        // Verify compression ratio is reasonable (should be much smaller)
        let compressionRatio = Double(compressed.count) / Double(largeData.count)
        #expect(compressionRatio < 0.5) // Should compress to less than 50% of original size
        #endif
    }
    
    @Test("Binary Data Compression")
    func testBinaryDataCompression() throws {
        #if canImport(Compression)
        // Create some binary data
        var binaryData = Data()
        for i in 0..<1024 {
            binaryData.append(UInt8(i % 256))
        }
        
        let compressed = try STComparator.compress(binaryData, algorithm: .lzfse)
        let decompressed = try STComparator.decompress(compressed, algorithm: .lzfse)
        
        #expect(decompressed == binaryData)
        #endif
    }
    
    @Test("Random Data Compression")
    func testRandomDataCompression() throws {
        #if canImport(Compression)
        // Random data typically doesn't compress well
        var randomData = Data()
        for _ in 0..<1024 {
            randomData.append(UInt8.random(in: 0...255))
        }
        
        let compressed = try STComparator.compress(randomData, algorithm: .zlib)
        let decompressed = try STComparator.decompress(compressed, algorithm: .zlib)
        
        #expect(decompressed == randomData)
        
        // Random data might actually get larger when compressed
        // So we just verify it works, not that it's smaller
        #expect(compressed.count > 0)
        #endif
    }
    
    @Test("Compression Algorithm Comparison")
    func testCompressionAlgorithmComparison() throws {
        #if canImport(Compression)
        let testData = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """.data(using: .utf8)!
        
        let algorithms: [STComparator.Algorithm] = [.lz4, .zlib, .lzfse, .lzma]
        var compressionResults: [STComparator.Algorithm: Int] = [:]
        
        for algorithm in algorithms {
            let compressed = try STComparator.compress(testData, algorithm: algorithm)
            let decompressed = try STComparator.decompress(compressed, algorithm: algorithm)
            
            #expect(decompressed == testData)
            compressionResults[algorithm] = compressed.count
        }
        
        // All algorithms should produce compressed data
        for (algorithm, size) in compressionResults {
            #expect(size > 0, "Algorithm \(algorithm) produced empty compressed data")
        }
        #endif
    }
    
    @Test("Compression Error Handling")
    func testCompressionErrorHandling() throws {
        #if canImport(Compression)
        // Test with malformed compressed data
        let invalidCompressedData = Data([0xFF, 0xFF, 0xFF, 0xFF])
        
        #expect {
            try STComparator.decompress(invalidCompressedData, algorithm: .zlib)
        } throws: { error in
            return error is STComparator.Errors
        }
        #endif
    }
    
    @Test("Compression Consistency")
    func testCompressionConsistency() throws {
        #if canImport(Compression)
        let testData = "Consistency test data".data(using: .utf8)!
        
        // Compress the same data multiple times
        let compressed1 = try STComparator.compress(testData, algorithm: .zlib)
        let compressed2 = try STComparator.compress(testData, algorithm: .zlib)
        
        // The compressed data should be identical for the same input
        #expect(compressed1 == compressed2)
        
        // Both should decompress to the original data
        let decompressed1 = try STComparator.decompress(compressed1, algorithm: .zlib)
        let decompressed2 = try STComparator.decompress(compressed2, algorithm: .zlib)
        
        #expect(decompressed1 == testData)
        #expect(decompressed2 == testData)
        #expect(decompressed1 == decompressed2)
        #endif
    }
}