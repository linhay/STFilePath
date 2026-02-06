import Testing
import STFilePath
import Foundation

#if canImport(Darwin)
import Darwin

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

    @Test("Read-only MMAP on read-only file")
    func testReadOnlyMmapOnReadOnlyFile() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_readonly.txt")
        let content = "ReadOnly MMAP"
        try file.create(with: content.data(using: .utf8))
        try file.set(permissions: [.ownerRead])

        let readContent = try file.withMmap(prot: [.read], shareType: .private) { mmap in
            let data = mmap.read()
            return String(data: data, encoding: .utf8)
        }

        #expect(readContent == content)
    }

    @Test("MMAP with Page-Aligned Offset")
    func testMmapWithPageAlignedOffset() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let pageSize = Int(getpagesize())
        let file = testFolder.file("mmap_offset.bin")
        let pageA = Data(repeating: 0x41, count: pageSize)
        let pageB = Data(repeating: 0x42, count: pageSize)
        try file.create(with: pageA + pageB)

        let secondPage = try file.withMmap(size: pageSize, offset: pageSize) { mmap in
            mmap.read()
        }

        #expect(secondPage.count == pageSize)
        #expect(secondPage.first == 0x42)
        #expect(secondPage.last == 0x42)
    }

    @Test("MMAP with Non-Page-Aligned Offset Should Fail")
    func testMmapWithNonPageAlignedOffsetFails() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let pageSize = Int(getpagesize())
        let file = testFolder.file("mmap_offset_unaligned.bin")
        try file.create(with: Data(repeating: 0x00, count: pageSize * 2))

        #expect(throws: STPathError.self) {
            _ = try file.withMmap(size: pageSize, offset: pageSize + 1) { mmap in
                mmap.read()
            }
        }
    }

    @Test("MMAP Size Exceeds File Size Should Fail")
    func testMmapSizeExceedsFileSizeFails() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_size_exceed.bin")
        try file.create(with: Data(repeating: 0x00, count: 8))

        #expect(throws: STPathError.self) {
            _ = try file.withMmap(size: 64) { mmap in
                mmap.read()
            }
        }
    }

    @Test("MMAP Size Zero Should Fail")
    func testMmapSizeZeroFails() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_size_zero.bin")
        try file.create(with: Data(repeating: 0x00, count: 8))

        #expect(throws: STPathError.self) {
            _ = try file.withMmap(size: 0) { mmap in
                mmap.read()
            }
        }
    }

    @Test("Private MMAP Should Not Write Back")
    func testPrivateMmapDoesNotWriteBack() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_private.bin")
        let original = Data(repeating: 0x41, count: 16)
        try file.create(with: original)

        try file.withMmap(shareType: .private) { mmap in
            try mmap.write(Data(repeating: 0x42, count: 16))
            mmap.sync()
        }

        let after = try file.data()
        #expect(after == original)
    }

    @Test("MMAP Size Plus Offset Exceeds File Size Should Fail")
    func testMmapSizePlusOffsetExceedsFileSizeFails() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let pageSize = Int(getpagesize())
        let file = testFolder.file("mmap_size_offset.bin")
        try file.create(with: Data(repeating: 0x00, count: pageSize * 2))

        #expect(throws: STPathError.self) {
            _ = try file.withMmap(size: pageSize + 1, offset: pageSize) { mmap in
                mmap.read()
            }
        }
    }

    @Test("MMAP Write With Offset")
    func testMmapWriteWithOffset() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_write_offset.bin")
        try file.create(with: Data(repeating: 0x00, count: 32))

        try file.withMmap { mmap in
            let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
            try mmap.write(data, at: 4)
        }

        let data = try file.data()
        #expect(data[4] == 0xDE)
        #expect(data[5] == 0xAD)
        #expect(data[6] == 0xBE)
        #expect(data[7] == 0xEF)
    }

    @Test("MMAP Read Range")
    func testMmapReadRange() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let bytes = Data([0, 1, 2, 3, 4, 5, 6, 7])
        let file = testFolder.file("mmap_read_range.bin")
        try file.create(with: bytes)

        let slice = try file.withMmap { mmap in
            mmap.read(range: 2..<6)
        }

        #expect(slice == Data([2, 3, 4, 5]))
    }

    @Test("MMAP Default Size Uses FileSize Minus Offset")
    func testMmapDefaultSizeWithOffset() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_default_size_offset.bin")
        let pageSize = Int(getpagesize())
        let pageA = Data(repeating: 0x11, count: pageSize)
        let pageB = Data(repeating: 0x22, count: pageSize)
        try file.create(with: pageA + pageB)

        let tail = try file.withMmap(offset: pageSize) { mmap in
            mmap.read()
        }

        #expect(tail.count == pageSize)
        #expect(tail.first == 0x22)
        #expect(tail.last == 0x22)
    }

    @Test("MMAP Negative Offset Should Fail")
    func testMmapNegativeOffsetFails() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_negative_offset.bin")
        try file.create(with: Data(repeating: 0x00, count: 8))

        #expect(throws: STPathError.self) {
            _ = try file.withMmap(offset: -1) { mmap in
                mmap.read()
            }
        }
    }

    @Test("MMAP Offset At EOF Should Fail")
    func testMmapOffsetAtEndFails() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_offset_eof.bin")
        try file.create(with: Data(repeating: 0x00, count: 8))

        #expect(throws: STPathError.self) {
            _ = try file.withMmap(offset: 8) { mmap in
                mmap.read()
            }
        }
    }

    @Test("MMAP Non-Page-Aligned Offset Error Message")
    func testMmapNonPageAlignedErrorMessage() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let pageSize = Int(getpagesize())
        let file = testFolder.file("mmap_offset_error_message.bin")
        try file.create(with: Data(repeating: 0x00, count: pageSize * 2))

        do {
            _ = try file.withMmap(size: pageSize, offset: pageSize + 1) { mmap in
                mmap.read()
            }
            #expect(Bool(false), "Expected non-page-aligned offset to fail")
        } catch let error as STPathError {
            #expect(error.message.contains("page-aligned"))
        }
    }

    @Test("MMAP Negative Offset Error Message")
    func testMmapNegativeOffsetErrorMessage() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_negative_offset_error_message.bin")
        try file.create(with: Data(repeating: 0x00, count: 8))

        do {
            _ = try file.withMmap(offset: -1) { mmap in
                mmap.read()
            }
            #expect(Bool(false), "Expected negative offset to fail")
        } catch let error as STPathError {
            #expect(error.message.contains("Offset must be greater than or equal to 0"))
        }
    }

    @Test("MMAP After Truncate Uses New Size")
    func testMmapAfterTruncateUsesNewSize() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let pageSize = Int(getpagesize())
        let file = testFolder.file("mmap_truncate.bin")
        let pageA = Data(repeating: 0x11, count: pageSize)
        let pageB = Data(repeating: 0x22, count: pageSize)
        try file.create(with: pageA + pageB)

        try file.setSize(pageSize)

        try file.withMmap { mmap in
            #expect(mmap.size == pageSize)
            let data = mmap.read()
            #expect(data.count == pageSize)
            #expect(data.first == 0x11)
            #expect(data.last == 0x11)
        }
    }

    #if os(macOS)
    @Test("MMAP Shared Sees External Process Writes")
    func testMmapSharedSeesExternalProcessWrites() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let pageSize = Int(getpagesize())
        let file = testFolder.file("mmap_cross_process.bin")
        try file.create(with: Data(repeating: 0x00, count: pageSize))

        let pythonPath = "/usr/bin/python3"
        #expect(FileManager.default.fileExists(atPath: pythonPath))

        let script = """
import os, sys
path = sys.argv[1]
with open(path, "r+b") as f:
    f.seek(0)
    f.write(b'\\x33' * 4)
    f.flush()
    os.fsync(f.fileno())
"""

        try file.withMmap(prot: [.read], shareType: .share, size: pageSize, offset: 0) { mmap in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: pythonPath)
            process.arguments = ["-c", script, file.url.path]
            try process.run()
            process.waitUntilExit()

            #expect(process.terminationStatus == 0)
            let data = mmap.read(range: 0..<4)
            #expect(data == Data(repeating: 0x33, count: 4))
        }
    }
    #endif

    @Test("MMAP Write At End Boundary")
    func testMmapWriteAtEndBoundary() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_write_end.bin")
        try file.create(with: Data(repeating: 0x00, count: 8))

        try file.withMmap { mmap in
            try mmap.write(Data([0x7F]), at: 7)
        }

        let data = try file.data()
        #expect(data.count == 8)
        #expect(data[7] == 0x7F)
    }

    @Test("MMAP Sync Flushes Shared Writes")
    func testMmapSyncFlushesSharedWrites() throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("mmap_sync_shared.bin")
        try file.create(with: Data(repeating: 0x00, count: 16))

        try file.withMmap(shareType: .share) { mmap in
            try mmap.write(Data(repeating: 0x2A, count: 16))
            mmap.sync()
        }

        let data = try file.data()
        #expect(data.allSatisfy { $0 == 0x2A })
    }

}
#endif
