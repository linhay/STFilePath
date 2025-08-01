import Testing
import STFilePath
import Foundation

@Suite("STFile Tests")
struct STFileTests {
    
    @Test("File Operations")
    func testFileOperations() throws {
        let testFolder = try createTestFolder()
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
        
        try movedFile.append(data: " world".data(using: .utf8))
        #expect(try movedFile.read() == "hello world")
        
        try movedFile.overlay(with: "overlay".data(using: .utf8))
        #expect(try movedFile.read() == "overlay")
        
        try testFolder.delete()
    }
    
    @Test("Data Operations")
    func testDataOperations() throws {
        let testFolder = try createTestFolder()
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
        
        try testFolder.delete()
    }
    
    @Test("Line Reading")
    func testLineReading() async throws {
        let testFolder = try createTestFolder()
        try testFolder.create()
        let file = testFolder.file("lines.txt")
        try file.create(with: "line1\nline2\nline3".data(using: .utf8))
        
        var lines = [String]()
        try await file.readLines { line in
            lines.append(line)
        }
        
        #expect(lines == ["line1", "line2", "line3"])
        
        try testFolder.delete()
    }
    
}
