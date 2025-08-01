import Testing
import STFilePath
import Foundation

#if canImport(Darwin)
@Suite("STFileMMAP Tests")
struct STFileMMAPTests {

    @Test("Scoped MMAP with Read/Write")
    func testScopedMmap() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        
        let file = testFolder.file("mmap_scoped.txt")
        let initialContent = "Hello, MMAP!"
        try file.create(with: initialContent.data(using: .utf8))

        let readContent = try file.withMmap { mmap in
            // Read initial content
            let data = mmap.read()
            return String(data: data, encoding: .utf8)
        }

        #expect(readContent == initialContent)

        // Use withMmap to modify the file
        try file.withMmap { mmap in
            let newContent = "Modified!"
            try mmap.write(newContent.data(using: .utf8)!)
        }

        // Verify modification
        let modifiedContent = try file.read()
        #expect(modifiedContent.hasPrefix("Modified!"))
    }

    @Test("SetSize and MMAP Integration")
    func testSetSize() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        
        let file = testFolder.file("mmap_resize.txt")
        try file.create(with: Data())

        let newSize = 4096 // One page
        try file.setSize(newSize)
        #expect(file.attributes.size == newSize)

        try file.withMmap(size: newSize) { mmap in
            #expect(mmap.size == newSize)
            let content = "Data within new size"
            try mmap.write(content.data(using: .utf8)!)
        }

        let finalContent = try file.read()
        #expect(finalContent.hasPrefix("Data within new size"))
    }

    @Test("Type-Safe Buffer Pointer")
    func testTypeSafeBufferPointer() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        
        let file = testFolder.file("mmap_typesafe.bin")
        try file.create()
        try file.setSize(16) // 16 bytes

        try file.withMmap { mmap in
            try mmap.withUnsafeMutableBufferPointer(as: UInt32.self) { buffer in
                #expect(buffer.count == 4) // 16 bytes / 4 bytes per UInt32
                buffer[0] = 10
                buffer[1] = 20
                buffer[2] = .max
                buffer[3] = 0
            }
        }

        // Read back and verify
        let data = try file.data()
        let firstValue = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self) }
        let thirdValue = data.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt32.self) }
        #expect(firstValue == 10)
        #expect(thirdValue == .max)
    }
    
    @Test("Out of Bounds Write")
    func testOutOfBoundsWrite() async throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        
        let file = testFolder.file("mmap_bounds.txt")
        try file.create()
        try file.setSize(10)
        
        #expect(throws: STPathError.self) {
            try file.withMmap { mmap in
                let data = "This string is too long".data(using: .utf8)!
                // This should throw an error
                try mmap.write(data, at: 0)
            }
        }
    }

}
#endif
