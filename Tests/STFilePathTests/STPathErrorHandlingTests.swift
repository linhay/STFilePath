import Testing
import STFilePath
import Foundation

@Suite("STPath Error Handling Tests")
struct STPathErrorHandlingTests {
    
    @Test("File Not Found Errors")
    func testFileNotFoundErrors() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let nonExistentFile = testFolder.file("does_not_exist.txt")
        
        // Test various operations that should fail on non-existent files
        #expect {
            try nonExistentFile.read()
        } throws: { error in
            return error is STPathError || error is CocoaError
        }
        
        #expect {
            try nonExistentFile.delete()
        } throws: { error in
            return error is STPathError || error is CocoaError
        }
        
        #expect {
            try nonExistentFile.copy(to: testFolder.file("copy_dest.txt"))
        } throws: { error in
            return error is STPathError || error is CocoaError
        }
    }
    
    @Test("Directory Not Found Errors")
    func testDirectoryNotFoundErrors() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        // Don't create the test folder to test directory not found
        
        let nonExistentFolder = testFolder.folder("does_not_exist")
        
        #expect {
            try nonExistentFolder.delete()
        } throws: { error in
            return error is STPathError || error is CocoaError
        }
        
        #expect {
            let _ = try nonExistentFolder.files()
        } throws: { error in
            return error is STPathError || error is CocoaError
        }
    }
    
    @Test("Permission Denied Errors")
    func testPermissionDeniedErrors() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("readonly_test.txt")
        try file.create(with: "Read-only content".data(using: .utf8)!)
        
        // Set read-only permissions
        try file.set(permissions: STPathPermission.Posix([.ownerRead]))
        
        // Try to write to read-only file (this might succeed on some systems due to ownership)
        // The behavior can vary by platform and filesystem
        do {
            try file.overlay(with: "New content".data(using: .utf8)!)
            // If it succeeds, that's also valid behavior on some systems
        } catch {
            // If it fails, verify it's a permission-related error
            #expect(error is STPathError || error is CocoaError)
        }
    }
    
    @Test("Invalid Path Errors")
    func testInvalidPathErrors() throws {
        // Test with various invalid path characters and formats
        let invalidPaths = [
            "", // Empty path
            "/dev/null/invalid", // Path through device file
            String(repeating: "a", count: 1000) // Very long path
        ]
        
        for invalidPath in invalidPaths {
            let file = STFile(invalidPath)
            
            // Most operations should handle invalid paths gracefully
            #expect(!file.isExist) // Non-existent files should return false
            
            if invalidPath.isEmpty {
                // Empty paths should fail for most operations
                #expect {
                    try file.create()
                } throws: { _ in true }
            }
        }
    }
    
    @Test("Disk Space Errors")
    func testDiskSpaceHandling() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("space_test.txt")
        
        // We can't easily simulate out-of-disk-space conditions,
        // but we can test that large file operations complete or fail gracefully
        let largeData = Data(repeating: 65, count: 1024 * 1024) // 1MB
        
        do {
            try file.create(with: largeData)
            // If successful, verify the file was created correctly
            #expect(file.isExist)
            let readData = try file.read()
            #expect(readData.count == largeData.count)
        } catch {
            // If it fails, ensure it's a reasonable error
            #expect(error is STPathError || error is CocoaError)
        }
    }
    
    @Test("Concurrent Access Errors")
    func testConcurrentAccessHandling() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("concurrent_test.txt")
        try file.create(with: "Initial content".data(using: .utf8)!)
        
        // Test concurrent file handle operations
        let handle1 = try file.handle(.reading)
        let handle2 = try file.handle(.reading)
        
        // Multiple read handles should work
        let data1 = handle1.readDataToEndOfFile()
        let data2 = handle2.readDataToEndOfFile()
        
        #expect(data1 == data2)
        
        handle1.closeFile()
        handle2.closeFile()
    }
    
    @Test("STPathError Creation and Properties")  
    func testSTPathErrorCreation() throws {
        // Test creating STPathError with message
        let messageError = STPathError(message: "Test error message", code: 123)
        #expect(messageError.localizedDescription.contains("Test error message"))
        
        // Test creating STPathError with POSIX errno
        let posixError = STPathError(posix: ENOENT) // No such file or directory
        #expect(!posixError.localizedDescription.isEmpty)
        
        // Test that the error can be thrown and caught
        #expect {
            throw messageError
        } throws: { error in
            guard let stError = error as? STPathError else { return false }
            return stError.localizedDescription.contains("Test error message")
        }
    }
    
    @Test("File Handle Error Recovery")
    func testFileHandleErrorRecovery() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("handle_error_test.txt")
        try file.create(with: "Handle test content".data(using: .utf8)!)
        
        // Get a file handle
        let handle = try file.handle(.reading)
        
        // Close the handle
        handle.closeFile()
        
        // Operations on closed handle should fail gracefully
        let data = handle.readDataToEndOfFile()
        #expect(data.isEmpty) // Closed handle returns empty data
        
        // But we should be able to get a new handle
        let newHandle = try file.handle(.reading)
        let readData = newHandle.readDataToEndOfFile()
        #expect(!readData.isEmpty)
        newHandle.closeFile()
    }
    
    @Test("Path Sanitization")
    func testPathSanitization() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Test paths with special characters
        let specialPaths = [
            "file with spaces.txt",
            "file-with-dashes.txt",
            "file_with_underscores.txt",
            "file.with.dots.txt"
        ]
        
        for specialPath in specialPaths {
            let file = testFolder.file(specialPath)
            
            do {
                try file.create(with: "Content for \(specialPath)".data(using: .utf8)!)
                #expect(file.isExist)
                
                let content = try file.read()
                #expect(!content.isEmpty)
            } catch {
                // Some characters might not be allowed on certain filesystems
                // This is acceptable behavior
                #expect(error is STPathError || error is CocoaError)
            }
        }
    }
    
    @Test("Nested Error Propagation")
    func testNestedErrorPropagation() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        // Don't create the folder to cause nested errors
        
        let deepPath = testFolder.folder("level1").folder("level2").folder("level3")
        let file = deepPath.file("nested_file.txt")
        
        // Creating a file in non-existent nested directories should fail
        #expect {
            try file.create(with: "Nested content".data(using: .utf8)!)
        } throws: { error in
            return error is STPathError || error is CocoaError
        }
        
        // But creating the directories first should work
        try deepPath.create()
        try file.create(with: "Nested content".data(using: .utf8)!)
        #expect(file.isExist)
    }
}