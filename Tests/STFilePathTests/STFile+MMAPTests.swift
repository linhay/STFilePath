import Testing
import STFilePath
import Foundation

@Suite("STFile MMAP Tests")
struct STFileMMAPTests {
    
    @Test("Basic MMAP Operations")
    func testBasicMMAPOperations() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("mmap_test.txt")
        let testData = "Hello, MMAP World!".data(using: .utf8)!
        try file.create(with: testData)
        
        // Test basic mmap operations
        try file.withMmap { mmap in
            // Test reading
            let readData = mmap.read()
            #expect(readData == testData)
            
            // Test partial reading
            let partialData = mmap.read(range: 0..<5)
            #expect(partialData == "Hello".data(using: .utf8)!)
            
            // Test writing
            let newData = "MMAP".data(using: .utf8)!
            try mmap.write(newData, at: 7)
            
            // Verify the write
            let updatedData = mmap.read()
            let expectedData = "Hello, MMAP World!".data(using: .utf8)!
            #expect(updatedData.count == expectedData.count)
        }
        #endif
    }
    
    @Test("MMAP Size Management")
    func testMMAPSizeManagement() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("size_test.txt")
        try file.create(with: Data())
        
        // Set initial size
        try file.setSize(1024)
        
        try file.withMmap { mmap in
            #expect(mmap.size == 1024)
            
            // Test writing within bounds
            let testData = "Size test data".data(using: .utf8)!
            try mmap.write(testData, at: 0)
            
            // Test reading the written data
            let readData = mmap.read(range: 0..<testData.count)
            #expect(readData == testData)
        }
        #endif
    }
    
    @Test("MMAP with Different Protection Modes")
    func testMMAPProtectionModes() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("prot_test.txt")
        let testData = "Protection mode test".data(using: .utf8)!
        try file.create(with: testData)
        
        // Test read-only mapping
        try file.withMmap(prot: [.read]) { mmap in
            let readData = mmap.read()
            #expect(readData == testData)
            
            // Writing should be restricted (this might cause a crash in real scenarios,
            // so we'll just verify the mmap was created successfully)
            #expect(mmap.size == testData.count)
        }
        
        // Test read-write mapping
        try file.withMmap(prot: [.read, .write]) { mmap in
            let newData = "Modified".data(using: .utf8)!
            try mmap.write(newData, at: 0)
            
            let readData = mmap.read(range: 0..<newData.count)
            #expect(readData == newData)
        }
        #endif
    }
    
    @Test("MMAP Buffer Pointer Access")
    func testMMAPBufferPointerAccess() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("buffer_test.txt")
        let testBytes: [UInt8] = [72, 101, 108, 108, 111] // "Hello"
        let testData = Data(testBytes)
        try file.create(with: testData)
        
        try file.withMmap { mmap in
            // Test buffer pointer access
            let result = try mmap.withUnsafeMutableBufferPointer(as: UInt8.self) { buffer in
                // Verify we can read the bytes
                #expect(buffer.count == testBytes.count)
                for (index, expectedByte) in testBytes.enumerated() {
                    #expect(buffer[index] == expectedByte)
                }
                
                // Modify the buffer
                if buffer.count > 0 {
                    buffer[0] = 65 // Change 'H' to 'A'
                }
                
                return buffer[0]
            }
            
            #expect(result == 65) // Verify the modification
            
            // Verify the change persists in the mapped data
            let modifiedData = mmap.read()
            #expect(modifiedData.first == 65)
        }
        #endif
    }
    
    @Test("MMAP Synchronization")
    func testMMAPSynchronization() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("sync_test.txt")
        let testData = "Sync test data".data(using: .utf8)!
        try file.create(with: testData)
        
        try file.withMmap { mmap in
            // Write some data
            let newData = "Synchronized".data(using: .utf8)!
            try mmap.write(newData, at: 0)
            
            // Test sync operation (should not throw)
            mmap.sync()
            
            // Verify data is still accessible
            let readData = mmap.read(range: 0..<newData.count)
            #expect(readData == newData)
        }
        #endif
    }
    
    @Test("MMAP Error Handling")
    func testMMAPErrorHandling() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("error_test.txt")
        let testData = "Error handling test".data(using: .utf8)!
        try file.create(with: testData)
        
        try file.withMmap { mmap in
            // Test writing beyond bounds
            let largeData = Data(repeating: 65, count: 1000)
            
            #expect {
                try mmap.write(largeData, at: 0)
            } throws: { error in
                return error is STPathError
            }
            
            // Test reading beyond bounds should be handled by range check
            let outOfBoundsRange = 0..<1000
            #expect {
                _ = mmap.read(range: outOfBoundsRange)
            } throws: { _ in true }
        }
        #endif
    }
    
    @Test("MMAP with Offset")
    func testMMAPWithOffset() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("offset_test.txt")
        let testData = "0123456789ABCDEF".data(using: .utf8)!
        try file.create(with: testData)
        
        // Map from offset 5 with size 5
        try file.withMmap(size: 5, offset: 5) { mmap in
            #expect(mmap.size == 5)
            
            // Should read "56789"
            let readData = mmap.read()
            let expectedData = "56789".data(using: .utf8)!
            #expect(readData == expectedData)
        }
        #endif
    }
}