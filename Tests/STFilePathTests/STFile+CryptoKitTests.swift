import Testing
import STFilePath
import Foundation

@Suite("STFile CryptoKit Tests")
struct STFileCryptoKitTests {
    
    @Test("SHA256 Hash Operations")
    func testSHA256Hash() throws {
        #if canImport(CryptoKit)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("hash_test.txt")
        let testData = "Hello, World!".data(using: .utf8)!
        try file.create(with: testData)
        
        // Test SHA256 hash
        let hash = try file.hash(with: .sha256)
        #expect(!hash.isEmpty)
        #expect(hash.count == 64) // SHA256 produces 32 bytes = 64 hex characters
        
        // Test consistency - same content should produce same hash
        let hash2 = try file.hash(with: .sha256)
        #expect(hash == hash2)
        
        // Test with different content
        let file2 = testFolder.file("hash_test2.txt")
        try file2.create(with: "Different content".data(using: .utf8)!)
        let differentHash = try file2.hash(with: .sha256)
        #expect(hash != differentHash)
        #endif
    }
    
    @Test("Multiple Hash Algorithms")
    func testMultipleHashAlgorithms() throws {
        #if canImport(CryptoKit)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("multi_hash_test.txt")
        let testData = "Test data for multiple hash algorithms".data(using: .utf8)!
        try file.create(with: testData)
        
        // Test different algorithms produce different results
        let sha256Hash = try file.hash(with: .sha256)
        let sha384Hash = try file.hash(with: .sha384)
        let sha512Hash = try file.hash(with: .sha512)
        let md5Hash = try file.hash(with: .md5)
        
        // Verify hash lengths
        #expect(sha256Hash.count == 64)  // 32 bytes * 2 hex chars
        #expect(sha384Hash.count == 96)  // 48 bytes * 2 hex chars
        #expect(sha512Hash.count == 128) // 64 bytes * 2 hex chars
        #expect(md5Hash.count == 32)     // 16 bytes * 2 hex chars
        
        // Verify they're all different
        #expect(sha256Hash != sha384Hash)
        #expect(sha256Hash != sha512Hash)
        #expect(sha256Hash != md5Hash)
        #expect(sha384Hash != sha512Hash)
        #endif
    }
    
    @Test("Large File Hash Performance")
    func testLargeFileHash() throws {
        #if canImport(CryptoKit)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("large_file.txt")
        
        // Create a larger file (1MB of data)
        let chunkSize = 1024
        let numChunks = 1024
        let chunk = String(repeating: "A", count: chunkSize).data(using: .utf8)!
        
        try file.create()
        let handle = try file.handle(.writing)
        defer { handle.closeFile() }
        
        for _ in 0..<numChunks {
            handle.write(chunk)
        }
        handle.closeFile()
        
        // Test hashing the large file
        let startTime = Date()
        let hash = try file.hash(with: .sha256)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(!hash.isEmpty)
        #expect(hash.count == 64)
        #expect(duration < 5.0) // Should complete within 5 seconds
        #endif
    }
    
    @Test("Hash Kind Direct Usage")
    func testHashKindDirectUsage() throws {
        #if canImport(CryptoKit)
        let testData = "Direct hash test".data(using: .utf8)!
        
        // Test hashing data directly through STHasherKind
        let sha256Hash = try STHasherKind.sha256.hash(with: testData)
        let md5Hash = try STHasherKind.md5.hash(with: testData)
        
        #expect(!sha256Hash.isEmpty)
        #expect(!md5Hash.isEmpty)
        #expect(sha256Hash != md5Hash)
        
        // Test consistency
        let sha256Hash2 = try STHasherKind.sha256.hash(with: testData)
        #expect(sha256Hash == sha256Hash2)
        #endif
    }
    
    @Test("Empty File Hash")
    func testEmptyFileHash() throws {
        #if canImport(CryptoKit)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("empty_file.txt")
        try file.create(with: Data())
        
        let hash = try file.hash(with: .sha256)
        #expect(!hash.isEmpty)
        #expect(hash.count == 64)
        
        // Empty files should have a consistent hash
        let hash2 = try file.hash(with: .sha256)
        #expect(hash == hash2)
        #endif
    }
}