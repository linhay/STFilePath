import Testing
import STFilePath
import Foundation

@Suite("STFile Tests")
struct STFileTests {
    
    @Test("File Operations")
    func testFileOperations() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        let file = testFolder.file("test.txt")
        try file.create(with: "hello".data(using: .utf8))
        #expect(try file.read() == "hello")
        
        let newFile = testFolder.file("new_test.txt")
        try file.copy(to: newFile)
        #expect(newFile.isExist)
        #expect(try newFile.read() == "hello")
        
        let movedFile = testFolder.file("moved_test.txt")
        try newFile.move(to: movedFile)
        #expect(!newFile.isExist)
        #expect(movedFile.isExist)
    }
    
    @Test("Data Operations")
    func testDataOperations() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        let file = testFolder.file("data.txt")
        let data = "hello world".data(using: .utf8)!
        try file.create(with: data)
        
        let readData = try file.data()
        #expect(readData == data)
        
        let rangeData = try file.data(range: 0...4)
        #expect(rangeData == "hello".data(using: .utf8))
        
        let decodedString = try file.decode { String(data: $0, encoding: .utf8) }
        #expect(decodedString == "hello world")
    }
    
    @Test("Line Reading")
    func testLineReading() async throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        let file = testFolder.file("lines.txt")
        try file.create(with: "line1\nline2\nline3".data(using: .utf8))
        
        var lines = [String]()
        try await file.readLines { line in
            lines.append(line)
        }
        
        #expect(lines == ["line1", "line2", "line3"])
    }
    
    @Test("Overlay Operation")
    func testOverlay() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        let file = testFolder.file("overlay_test.txt")

        // 1. Test overlay on a non-existent file
        try file.overlay(with: "first version".data(using: .utf8))
        #expect(file.isExist)
        #expect(try file.read() == "first version")

        // 2. Test overlay on an existing file
        try file.overlay(with: "second version".data(using: .utf8))
        #expect(try file.read() == "second version")

        // 3. Test overlay with nil data (should create an empty file)
        let emptyFile = testFolder.file("empty_overlay.txt")
        try emptyFile.overlay(with: nil)
        #expect(emptyFile.isExist)
        #expect(try emptyFile.read() == "")
    }

    @Test("Append Operation")
    func testAppend() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        let file = testFolder.file("append_test.txt")

        // 1. Test append on a non-existent file
        try file.append(data: "first chunk".data(using: .utf8))
        #expect(file.isExist)
        #expect(try file.read() == "first chunk")

        // 2. Test append on an existing file
        try file.append(data: " second chunk".data(using: .utf8))
        #expect(try file.read() == "first chunk second chunk")
        
        // 3. Test appending nil data (should do nothing)
        let originalContent = try file.read()
        try file.append(data: nil)
        #expect(try file.read() == originalContent)
    }

    @Test("Atomic Write Create and Overwrite")
    func testAtomicWriteCreateAndOverwrite() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()

        let file = testFolder.file("atomic.txt")
        try file.atomicWrite("v1".data(using: .utf8)!)
        #expect(file.isExists)
        #expect(try file.read() == "v1")

        try file.atomicWrite("v2".data(using: .utf8)!)
        #expect(try file.read() == "v2")
    }

    @Test("Atomic Write Failure Preserves Old Content")
    func testAtomicWriteFailurePreservesOldContent() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()

        let file = testFolder.file("atomic_failure.txt")
        try file.create(with: "old".data(using: .utf8)!)

        #if canImport(Darwin) || os(Linux)
            defer { try? testFolder.set(permissions: [.ownerRead, .ownerWrite, .ownerExecute]) }
            try testFolder.set(permissions: [.ownerRead, .ownerExecute])

            #expect(throws: Error.self) {
                try file.atomicWrite("new".data(using: .utf8)!)
            }
            #expect(try file.read() == "old")
        #endif
    }
}

    

    
