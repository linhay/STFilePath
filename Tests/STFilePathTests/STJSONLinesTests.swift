import Testing
import STFilePath
import Foundation

@Suite("STJSONLines Tests")
struct STJSONLinesTests {
    
    @Test("Basic JSON Lines Operations")
    func testBasicJSONLinesOperations() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("jsonlines_test.jsonl")
        try file.create()
        
        // Test writing JSON lines
        let writer = try file.lineFile.newLineWriter
        
        struct TestModel: Codable, Equatable {
            let id: Int
            let name: String
            let active: Bool
        }
        
        let model1 = TestModel(id: 1, name: "Alice", active: true)
        let model2 = TestModel(id: 2, name: "Bob", active: false)
        let model3 = TestModel(id: 3, name: "Charlie", active: true)
        
        try writer.append(model: model1)
        try writer.append(model: model2)
        try writer.append(model: model3)
        
        // Test reading JSON lines
        let readModels = try file.lineFile.lines(as: TestModel.self)
        #expect(readModels.count == 3)
        #expect(readModels[0] == model1)
        #expect(readModels[1] == model2)
        #expect(readModels[2] == model3)
    }
    
    @Test("Raw Data JSON Lines")
    func testRawDataJSONLines() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("raw_jsonlines.jsonl")
        try file.create()
        
        let writer = try file.lineFile.newLineWriter
        
        // Write raw JSON data
        let jsonData1 = "{\"message\":\"Hello\",\"timestamp\":1234567890}".data(using: .utf8)!
        let jsonData2 = "{\"message\":\"World\",\"timestamp\":1234567891}".data(using: .utf8)!
        
        try writer.append(jsonData1)
        try writer.append(jsonData2)
        
        // Read back as raw data
        let lines = try file.lineFile.lines()
        #expect(lines.count == 2)
        #expect(lines[0] == jsonData1)
        #expect(lines[1] == jsonData2)
    }
    
    @Test("Mixed Content JSON Lines")
    func testMixedContentJSONLines() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("mixed_jsonlines.jsonl")
        try file.create()
        
        let writer = try file.lineFile.newLineWriter
        
        struct LogEntry: Codable {
            let level: String
            let message: String
            let timestamp: Int
        }
        
        struct UserAction: Codable {
            let userId: Int
            let action: String
            let metadata: [String: String]
        }
        
        let logEntry = LogEntry(level: "INFO", message: "User logged in", timestamp: 1234567890)
        let userAction = UserAction(userId: 123, action: "click", metadata: ["button": "submit"])
        
        try writer.append(model: logEntry)
        try writer.append(model: userAction)
        
        // Read back as raw lines
        let rawLines = try file.lineFile.lines()
        #expect(rawLines.count == 2)
        
        // Verify each line is valid JSON by decoding
        let decoder = JSONDecoder()
        let decodedLog = try decoder.decode(LogEntry.self, from: rawLines[0])
        let decodedAction = try decoder.decode(UserAction.self, from: rawLines[1])
        
        #expect(decodedLog.level == "INFO")
        #expect(decodedAction.userId == 123)
    }
    
    @Test("Large JSON Lines File")
    func testLargeJSONLinesFile() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("large_jsonlines.jsonl")
        try file.create()
        
        let writer = try file.lineFile.newLineWriter
        
        struct DataPoint: Codable, Equatable {
            let id: Int
            let value: Double
            let category: String
        }
        
        let numEntries = 1000
        var expectedData: [DataPoint] = []
        
        // Write many entries
        for i in 0..<numEntries {
            let dataPoint = DataPoint(
                id: i,
                value: Double(i) * 1.5,
                category: "category_\(i % 10)"
            )
            expectedData.append(dataPoint)
            try writer.append(model: dataPoint)
        }
        
        // Read back and verify
        let readData = try file.lineFile.lines(as: DataPoint.self)
        #expect(readData.count == numEntries)
        
        // Spot check some entries
        #expect(readData.first == expectedData.first)
        #expect(readData.last == expectedData.last)
        #expect(readData[numEntries/2] == expectedData[numEntries/2])
    }
    
    @Test("JSON Lines with Special Characters")
    func testJSONLinesWithSpecialCharacters() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("special_chars_jsonlines.jsonl")
        try file.create()
        
        let writer = try file.lineFile.newLineWriter
        
        struct MessageData: Codable, Equatable {
            let message: String
            let emoji: String
            let unicode: String
        }
        
        let specialMessage = MessageData(
            message: "Hello \"World\" with 'quotes' and\nnewlines",
            emoji: "🌟✨🎉",
            unicode: "Üñíçødé tëxt"
        )
        
        try writer.append(model: specialMessage)
        
        let readMessages = try file.lineFile.lines(as: MessageData.self)
        #expect(readMessages.count == 1)
        #expect(readMessages[0] == specialMessage)
    }
    
    @Test("Empty and Whitespace JSON Lines")
    func testEmptyAndWhitespaceJSONLines() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let file = testFolder.file("empty_jsonlines.jsonl")
        try file.create()
        
        let writer = try file.lineFile.newLineWriter
        
        struct EmptyData: Codable, Equatable {
            let empty: String
            let whitespace: String
        }
        
        let emptyData = EmptyData(empty: "", whitespace: "   ")
        try writer.append(model: emptyData)
        
        let readData = try file.lineFile.lines(as: EmptyData.self)
        #expect(readData.count == 1)
        #expect(readData[0] == emptyData)
    }
    
    @Test("JSON Lines File Handling")
    func testJSONLinesFileHandling() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Test with existing file with content
        let file = testFolder.file("existing_content.jsonl")
        try file.create(with: "{\"existing\":\"data\"}\n".data(using: .utf8)!)
        
        let writer = try file.lineFile.newLineWriter
        
        struct NewData: Codable {
            let new: String
        }
        
        let newData = NewData(new: "appended")
        try writer.append(model: newData)
        
        // Should have both old and new data
        let lines = try file.lineFile.lines()
        #expect(lines.count == 2)
        
        // Verify the existing data is still there
        let decoder = JSONDecoder()
        let existingData = try decoder.decode([String: String].self, from: lines[0])
        #expect(existingData["existing"] == "data")
        
        let appendedData = try decoder.decode(NewData.self, from: lines[1])
        #expect(appendedData.new == "appended")
    }
}