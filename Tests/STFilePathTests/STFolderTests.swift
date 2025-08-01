import Testing
import STFilePath
import Foundation

@Suite("STFolder Tests")
struct STFolderTests {
        
    @Test("Folder Operations")
    func testFolderOperations() throws {
        let testFolder = try createTestFolder()
        try testFolder.create()
        #expect(testFolder.isExist)
        
        let subfolder = testFolder.folder("subfolder")
        try subfolder.create()
        #expect(subfolder.isExist)
        
        let file = try testFolder.create(file: "test.txt", data: "hello".data(using: .utf8))
        #expect(file.isExist)
        #expect(try file.read() == "hello")
        
        let subFile = subfolder.file("subfile.txt")
        #expect(!subFile.isExist)
        
        let openedFile = try testFolder.open(name: "opened.txt")
        #expect(openedFile.isExist)
        
        try testFolder.delete()
        #expect(!testFolder.isExist)
        #expect(!subfolder.isExist)
        #expect(!file.isExist)
    }
    
    @Test("Search Operations")
    func testSearchOperations() throws {
        let testFolder = try createTestFolder()
        try testFolder.create()
        let subfolder = try testFolder.create(folder: "subfolder")
        try testFolder.create(file: "file1.txt")
        try subfolder.create(file: "file2.txt")
        try testFolder.create(file: ".hidden.txt")
        
        let allPaths = try testFolder.allSubFilePaths()
        #expect(allPaths.count == 4) // subfolder, file1, file2, .hidden.txt
        
        let files = try testFolder.files()
        #expect(files.count == 2) // file1, .hidden.txt
        
        let folders = try testFolder.folders()
        #expect(folders.count == 1) // subfolder
        
        let nonHiddenFiles = try testFolder.files([.skipsHiddenFiles])
        #expect(nonHiddenFiles.count == 1)
        #expect(nonHiddenFiles.first?.attributes.name == "file1.txt")
        
        try testFolder.delete()
    }
    
    @Test("Sanbox Operations")
    func testSanboxOperations() throws {

        let home = try STFolder(sanbox: .home)
        #expect(home.url.path == NSHomeDirectory())
        
        let documents = try STFolder(sanbox: .document)
        let expectedDocuments = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        #expect(documents.url == expectedDocuments)
    }
    
}
