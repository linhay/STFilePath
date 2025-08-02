import Testing
import STFilePath
import Foundation

@Suite("STFolder Search Tests")
struct STFolderSearchTests {
    
    @Test("Basic File Search")
    func testBasicFileSearch() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create test files
        let file1 = testFolder.file("test1.txt")
        let file2 = testFolder.file("test2.txt")  
        let file3 = testFolder.file("document.pdf")
        
        try file1.create(with: "Content 1".data(using: .utf8)!)
        try file2.create(with: "Content 2".data(using: .utf8)!)
        try file3.create(with: "PDF content".data(using: .utf8)!)
        
        // Search for all files
        let allFiles = try testFolder.files()
        #expect(allFiles.count == 3)
        
        let fileNames = allFiles.map { $0.url.lastPathComponent }.sorted()
        #expect(fileNames == ["document.pdf", "test1.txt", "test2.txt"])
    }
    
    @Test("Basic Folder Search")
    func testBasicFolderSearch() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create test folders
        let folder1 = testFolder.folder("sub1")
        let folder2 = testFolder.folder("sub2")
        let folder3 = testFolder.folder("documents")
        
        try folder1.create()
        try folder2.create()
        try folder3.create()
        
        // Search for all folders
        let allFolders = try testFolder.folders()
        #expect(allFolders.count == 3)
        
        let folderNames = allFolders.map { $0.url.lastPathComponent }.sorted()
        #expect(folderNames == ["documents", "sub1", "sub2"])
    }
    
    @Test("Recursive Search")
    func testRecursiveSearch() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create nested structure
        let level1 = testFolder.folder("level1")
        try level1.create()
        
        let level2 = level1.folder("level2")
        try level2.create()
        
        let file1 = testFolder.file("root.txt")
        let file2 = level1.file("level1.txt")
        let file3 = level2.file("level2.txt")
        
        try file1.create(with: "Root content".data(using: .utf8)!)
        try file2.create(with: "Level 1 content".data(using: .utf8)!)
        try file3.create(with: "Level 2 content".data(using: .utf8)!)
        
        // Recursive search should find all items
        let allItems = try testFolder.allSubFilePaths()
        
        // Should find: root.txt, level1/, level1/level1.txt, level1/level2/, level1/level2/level2.txt
        #expect(allItems.count >= 4) // At least the files and some folders
        
        let fileItems = allItems.filter { $0.type.isFile }
        #expect(fileItems.count == 3)
    }
    
    @Test("Search with Skip Subdirectory Descendants")
    func testSearchWithSkipSubdirectoryDescendants() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create nested structure
        let subFolder = testFolder.folder("subfolder")
        try subFolder.create()
        
        let file1 = testFolder.file("root.txt")
        let file2 = subFolder.file("nested.txt")
        
        try file1.create(with: "Root content".data(using: .utf8)!)
        try file2.create(with: "Nested content".data(using: .utf8)!)
        
        // Search without descending into subdirectories
        let shallowItems = try testFolder.allSubFilePaths([.skipsSubdirectoryDescendants])
        
        // Should only find root.txt and subfolder, not nested.txt
        let fileItems = shallowItems.filter { $0.type.isFile }
        #expect(fileItems.count == 1)
        #expect(fileItems[0].url.lastPathComponent == "root.txt")
    }
    
    @Test("Search with Skip Hidden Files")
    func testSearchWithSkipHiddenFiles() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create normal and hidden files
        let normalFile = testFolder.file("normal.txt")
        let hiddenFile = testFolder.file(".hidden.txt")
        
        try normalFile.create(with: "Normal content".data(using: .utf8)!)
        try hiddenFile.create(with: "Hidden content".data(using: .utf8)!)
        
        // Search skipping hidden files
        let visibleFiles = try testFolder.files([.skipsHiddenFiles])
        #expect(visibleFiles.count == 1)
        #expect(visibleFiles[0].url.lastPathComponent == "normal.txt")
        
        // Search including hidden files (default behavior)
        let allFiles = try testFolder.files()
        #expect(allFiles.count == 2)
    }
    
    @Test("Custom Search Predicate")
    func testCustomSearchPredicate() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create files with different extensions
        let txtFile = testFolder.file("document.txt")
        let pdfFile = testFolder.file("document.pdf")
        let jpgFile = testFolder.file("image.jpg")
        
        try txtFile.create(with: "Text content".data(using: .utf8)!)
        try pdfFile.create(with: "PDF content".data(using: .utf8)!)
        try jpgFile.create(with: "Image content".data(using: .utf8)!)
        
        // Custom predicate to find only .txt files
        let txtOnlyPredicate: STFolder.SearchPredicate = .custom { path in
            return path.url.pathExtension == "txt"
        }
        
        let txtFiles = try testFolder.files([txtOnlyPredicate])
        #expect(txtFiles.count == 1)
        #expect(txtFiles[0].url.lastPathComponent == "document.txt")
    }
    
    @Test("Multiple Custom Predicates")
    func testMultipleCustomPredicates() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create files of different sizes
        let smallFile = testFolder.file("small.txt")
        let mediumFile = testFolder.file("medium.txt")
        let largeFile = testFolder.file("large.txt")
        
        try smallFile.create(with: "Hi".data(using: .utf8)!)
        try mediumFile.create(with: String(repeating: "A", count: 100).data(using: .utf8)!)
        try largeFile.create(with: String(repeating: "B", count: 1000).data(using: .utf8)!)
        
        // Predicate for .txt files
        let txtPredicate: STFolder.SearchPredicate = .custom { path in
            return path.url.pathExtension == "txt"
        }
        
        // Predicate for files larger than 50 bytes
        let sizePredicate: STFolder.SearchPredicate = .custom { path in
            guard let file = path.asFile else { return false }
            do {
                return file.attributes.size > 50
            } catch {
                return false
            }
        }
        
        let filteredFiles = try testFolder.files([txtPredicate, sizePredicate])
        #expect(filteredFiles.count == 2) // medium.txt and large.txt
        
        let fileNames = filteredFiles.map { $0.url.lastPathComponent }.sorted()
        #expect(fileNames == ["large.txt", "medium.txt"])
    }
    
    @Test("Search in Non-existent Folder")
    func testSearchInNonExistentFolder() throws {
        let testFolder = try createTestFolder()
        let nonExistentFolder = testFolder.folder("does_not_exist")
        
        // Searching in non-existent folder should throw an error
        #expect {
            try nonExistentFolder.files()
        } throws: { _ in true }
        
        #expect {
            try nonExistentFolder.folders()
        } throws: { _ in true }
    }
    
    @Test("Empty Folder Search")
    func testEmptyFolderSearch() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Search in empty folder
        let files = try testFolder.files()
        let folders = try testFolder.folders()
        let allItems = try testFolder.allSubFilePaths()
        
        #expect(files.isEmpty)
        #expect(folders.isEmpty)
        #expect(allItems.isEmpty)
    }
    
    @Test("Complex Nested Search")
    func testComplexNestedSearch() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        // Create complex nested structure
        let docs = testFolder.folder("documents")
        let images = testFolder.folder("images")
        let temp = testFolder.folder("temp")
        
        try docs.create()
        try images.create()
        try temp.create()
        
        let subDocs = docs.folder("subdocs")
        try subDocs.create()
        
        // Create various files
        try testFolder.file("readme.txt").create(with: "Root readme".data(using: .utf8)!)
        try docs.file("doc1.txt").create(with: "Document 1".data(using: .utf8)!)
        try docs.file("doc2.pdf").create(with: "Document 2".data(using: .utf8)!)
        try subDocs.file("nested.txt").create(with: "Nested doc".data(using: .utf8)!)
        try images.file("photo.jpg").create(with: "Photo".data(using: .utf8)!)
        try temp.file(".hidden").create(with: "Hidden temp".data(using: .utf8)!)
        
        // Test various search combinations
        let allFiles = try testFolder.files()
        #expect(allFiles.count == 1) // Only readme.txt in root
        
        let allRecursiveFiles = try testFolder.allSubFilePaths().filter { $0.type.isFile }
        #expect(allRecursiveFiles.count == 6) // All files including nested ones
        
        let noHiddenFiles = try testFolder.allSubFilePaths([.skipsHiddenFiles]).filter { $0.type.isFile }
        #expect(noHiddenFiles.count == 5) // All except .hidden
        
        let txtOnly = try testFolder.allSubFilePaths([.custom { $0.url.pathExtension == "txt" }]).filter { $0.type.isFile }
        #expect(txtOnly.count == 3) // readme.txt, doc1.txt, nested.txt
    }
    
    @Test("Contains Predicate")  
    func testContainsPredicate() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()
        
        let subFolder = testFolder.folder("subfolder")
        try subFolder.create()
        
        let file1 = testFolder.file("file1.txt")
        let file2 = subFolder.file("file2.txt") 
        
        try file1.create()
        try file2.create()
        
        // Test contains functionality
        #expect(testFolder.contains(file1))
        #expect(testFolder.contains(file2)) // Should contain nested file too
        #expect(testFolder.contains(subFolder))
        
        // Test that subFolder doesn't contain file1
        #expect(!subFolder.contains(file1))
        #expect(subFolder.contains(file2))
    }
}