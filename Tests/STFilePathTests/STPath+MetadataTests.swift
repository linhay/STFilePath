import Testing
import STFilePath
import Foundation

@Suite("STPath Metadata Tests")
struct STPathMetadataTests {
    
    @Test("File Permissions")
    func testFilePermissions() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("permission_test.txt")
        try file.create(with: "Permission test content".data(using: .utf8)!)
        
        // Test setting and getting permissions
        try file.set(permissions: STPathPermission.Posix([.ownerRead, .ownerWrite]))
        let permissions = try file.permissions()
        #expect(permissions.contains(.ownerRead))
        #expect(permissions.contains(.ownerWrite))
    }
    
    @Test("Directory Permissions")  
    func testDirectoryPermissions() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let subFolder = testFolder.folder("sub_folder")
        try subFolder.create()
        
        // Test directory permissions
        try subFolder.set(permissions: STPathPermission.Posix([.ownerRead, .ownerWrite, .ownerExecute]))
        let permissions = try subFolder.permissions()
        #expect(permissions.contains(.ownerRead))
        #expect(permissions.contains(.ownerWrite))
        #expect(permissions.contains(.ownerExecute))
    }
    
    @Test("Extended Attributes")
    func testExtendedAttributes() throws {
        #if canImport(Darwin)
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("xattr_test.txt")
        try file.create(with: "Extended attributes test".data(using: .utf8)!)
        
        let attributeName = "com.test.myattribute"
        let attributeValue = "test value".data(using: .utf8)!
        
        // Test setting extended attribute
        try file.extendedAttributes.set(name: attributeName, value: attributeValue)
        
        // Test getting extended attribute
        let retrievedValue = try file.extendedAttributes.value(of: attributeName)
        #expect(retrievedValue == attributeValue)
        
        // Test listing attributes
        let attributeNames = try file.extendedAttributes.list()
        #expect(attributeNames.contains(attributeName))
        
        // Test removing attribute
        try file.extendedAttributes.remove(of: attributeName)
        
        // Verify attribute is removed
        #expect {
            try file.extendedAttributes.value(of: attributeName)
        } throws: { _ in true }
        #endif
    }
    
    @Test("File Statistics")
    func testFileStatistics() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("stats_test.txt")
        let testContent = "File statistics test content"
        try file.create(with: testContent.data(using: .utf8)!)
        
        // Test basic file properties
        #expect(file.isExist)
        #expect(file.type.isFile)
        #expect(!file.type.isFolder)
        
        // Test file size
        let expectedSize = testContent.data(using: .utf8)!.count
        #expect(file.attributes.size == expectedSize)
    }
    
    @Test("Directory Statistics")
    func testDirectoryStatistics() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let subFolder = testFolder.folder("stats_test_dir")
        try subFolder.create()
        
        #expect(subFolder.isExist)
        #expect(!subFolder.type.isFile)
        #expect(subFolder.type.isFolder)
    }
    
    @Test("File Dates and Times")
    func testFileDatesAndTimes() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("date_test.txt")
        let beforeCreate = Date()
        try file.create(with: "Date test content".data(using: .utf8)!)
        let afterCreate = Date()
        
        #expect(file.isExist)
        
        // Creation date should be between before and after create
        // Note: Not all filesystems support creation date, so we'll just check it doesn't throw
        do {
            let creationDate = file.attributes.creationDate
            #expect(creationDate >= beforeCreate.addingTimeInterval(-1))
            #expect(creationDate <= afterCreate.addingTimeInterval(1))
        } catch {
            // Some filesystems/platforms may not support creation date
            // This is acceptable
        }
        
        // Modification date should be supported on most systems
        do {
            let modificationDate = file.attributes.modificationDate
            #expect(modificationDate >= beforeCreate.addingTimeInterval(-1))
            #expect(modificationDate <= afterCreate.addingTimeInterval(1))
        } catch {
            // If modification date isn't supported, that's unusual but acceptable
        }
    }
    
    @Test("Complex Permission Combinations")
    func testComplexPermissionCombinations() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("complex_perms.txt")
        try file.create(with: "Complex permissions test".data(using: .utf8)!)
        
        // Test various permission combinations
        let permissionSets: [STPathPermission.Posix] = [
            [.ownerRead],
            [.ownerWrite],
            [.ownerExecute],
            [.ownerRead, .ownerWrite],
            [.ownerRead, .ownerExecute],
            [.ownerWrite, .ownerExecute],
            [.ownerRead, .ownerWrite, .ownerExecute],
            [.groupRead, .groupWrite, .groupExecute],
            [.othersRead, .othersWrite, .othersExecute]
        ]
        
        for permSet in permissionSets {
            try file.set(permissions: permSet)
            let retrievedPerms = try file.permissions()
            
            // Check that the core permissions are set correctly
            // Note: The retrieved permissions might include additional bits
            // so we check if the intersection contains our original set
            let intersection = STPathPermission.Posix(rawValue: retrievedPerms.rawValue & permSet.rawValue)
            #expect(intersection == permSet)
        }
    }
    
    @Test("Metadata Error Handling")  
    func testMetadataErrorHandling() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let nonExistentFile = testFolder.file("does_not_exist.txt")
        
        // Test that operations on non-existent files throw appropriate errors
        #expect {
            try nonExistentFile.permissions()
        } throws: { _ in true }
        
        #expect {
            let _ = nonExistentFile.attributes.size
        } throws: { _ in true }
        
        #if canImport(Darwin)
        #expect {
            try nonExistentFile.value(of: "com.test.nonexistent")
        } throws: { _ in true }
        #endif
    }
    
    @Test("Large File Size Handling")
    func testLargeFileSizeHandling() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("large_size_test.txt")
        try file.create()
        
        // Create a moderately large file by appending data
        let chunkSize = 1024
        let numChunks = 100
        let chunk = Data(repeating: 65, count: chunkSize) // 'A' repeated
        
        let handle = try file.handle(.writing)
        defer { handle.closeFile() }
        
        for _ in 0..<numChunks {
            handle.write(chunk)
        }
        handle.closeFile()
        
        // Test size calculation
        let expectedSize = chunkSize * numChunks
        let actualSize = file.attributes.size
        #expect(actualSize == expectedSize)
    }
}
