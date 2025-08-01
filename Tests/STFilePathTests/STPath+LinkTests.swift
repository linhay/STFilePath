
import Testing
import STFilePath
import Foundation

@Suite("STPath.Link Tests")
struct STPathLinkTests {
    
    @Test("Symbolic Link Operations")
    func testSymbolicLinkOperations() throws {
        let temporaryFolder = try createTestFolder()
        let folder = temporaryFolder
        
        let file = folder.file("file.txt")
        try file.create(with: "hello".data(using: .utf8))
        
        let link = folder.subpath("link")
        try link.createSymbolicLink(to: file)
        
        #expect(link.isSymbolicLink)
        #expect(try link.destinationOfSymbolicLink().url == file.url)
        
        let linkedFile = try link.destinationOfSymbolicLink().asFile!
        #expect(try linkedFile.read() == "hello")
    }
    
}
