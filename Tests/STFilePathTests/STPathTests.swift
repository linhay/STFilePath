import Testing
import STFilePath
import Foundation

@Suite("STPath Tests")
struct STPathTests {
    
    @Test("Initialization and Basic Properties")
    func testInitialization() throws {
        let testFolder = try createTestFolder()
        let pathString = testFolder.url.path
        let path = STPath(pathString)
        #expect(path.url.path == pathString)
        #expect(path.id == path.url)
    }
    
    @Test("Codable Conformance")
    func testCodable() throws {
        let testFolder = try createTestFolder()
        let path = STPath(testFolder.url.path)
        let encoder = JSONEncoder()
        let data = try encoder.encode(path)
        let decoder = JSONDecoder()
        let decodedPath = try decoder.decode(STPath.self, from: data)
        #expect(path.url == decodedPath.url)
    }
    
    @Test("Path Type")
    func testPathType() throws {
        let testFolder = try createTestFolder()
        try testFolder.create()
        let path = STPath(testFolder.url.path)
        #expect(path.type == .folder)
        try testFolder.delete()
        #expect(path.type == .notExist)
        let file = try testFolder.create(file: "test.txt")
        let filePath = STPath(file.url.path)
        #expect(filePath.type == .file)
        try testFolder.delete()
    }
    
    @Test("Reference Type")
    func testReferenceType() throws {
        let testFolder = try createTestFolder()
        try testFolder.create()
        let path = STPath(testFolder.url.path)
        switch path.referenceType {
        case .folder(let folder):
            #expect(folder == testFolder)
        default:
            Issue.record("Expected folder reference type")
        }
        try testFolder.delete()
        
        let file = try testFolder.create(file: "test.txt")
        let filePath = STPath(file.url.path)
        switch filePath.referenceType {
        case .file(let f):
            #expect(f.url == file.url)
        default:
            Issue.record("Expected file reference type")
        }
        try testFolder.delete()
    }
    
    @Test("Standardized Path")
    func testStandardizedPath() {
        let homePath = STPath("~")
        #expect(homePath.url.path == NSHomeDirectory())
        
        let homeSubPath = STPath("~/Documents")
        #expect(homeSubPath.url.path == NSHomeDirectory() + "/Documents")
    }
    
    @Test("Path Components")
    func testPathComponents() throws {
        let testFolder = try createTestFolder()
        try testFolder.create()
        let file = try testFolder.create(file: "test.txt")
        let filePath = STPath(file.url.path)
        #expect(filePath.attributes.nameComponents.filename == "test.txt")
        #expect(filePath.attributes.nameComponents.extension == "txt")
        #expect(filePath.attributes.nameComponents.name == "test")
        try testFolder.delete()
    }

    @Test("Parent Folder")
    func testParentFolder() throws {
        let testFolder = try createTestFolder()
        try testFolder.create()
        let file = try testFolder.create(file: "test.txt")
        let filePath = STPath(file.url.path)
        let parent = filePath.parentFolder()
        #expect(parent?.url == testFolder.url)
        try testFolder.delete()
    }

    @Test("Hashable Conformance")
    func testHashable() throws {
        let testFolder = try createTestFolder()
        let path1 = STPath(testFolder.url.path)
        let path2 = STPath(testFolder.url.path)
        let path3 = STPath("~/another/path")

        var hasher1 = Hasher()
        path1.hash(into: &hasher1)

        var hasher2 = Hasher()
        path2.hash(into: &hasher2)
        
        var hasher3 = Hasher()
        path3.hash(into: &hasher3)

        #expect(hasher1.finalize() == hasher2.finalize())
        #expect(hasher1.finalize() != hasher3.finalize())

        let set = Set([path1, path2])
        #expect(set.count == 1)
    }

}
