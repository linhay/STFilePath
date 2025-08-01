import Testing
import STFilePath
import Foundation

@Suite("STFolderWatcher Tests")
struct STFolderWatcherTests {

    @available(iOS 16.0, *)
    @Test("Folder Watcher Operations")
    func testWatcher() async throws {
        try await Task.sleep(for: .seconds(2))

        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let watcher = testFolder.watcher(options: .init(interval: .milliseconds(100)))
        try watcher.connect()

        let stream = try watcher.streamMonitoring()
        var iterator = stream.makeAsyncIterator()

        // 1. Test file creation
        let file1 = testFolder.file("file1.txt")
        try file1.create(with: "hello".data(using: .utf8))
        var change = try await iterator.next()!
        #expect(change.kind == .added)
        #expect(change.file.url.path.replacingOccurrences(of: "/private/var", with: "/var") == file1.url.path.replacingOccurrences(of: "/private/var", with: "/var"))

        // 2. Test file modification
        try await Task.sleep(for: .seconds(1))
        try file1.overlay(with: "world".data(using: .utf8))
        change = try await iterator.next()!
        #expect(change.kind == .changed)
        #expect(change.file.url.path.replacingOccurrences(of: "/private/var", with: "/var") == file1.url.path.replacingOccurrences(of: "/private/var", with: "/var"))

        // 3. Test file deletion
        try await Task.sleep(for: .seconds(1))
        try file1.delete()
        change = try await iterator.next()!
        #expect(change.kind == .deleted)
        #expect(change.file.url.path.replacingOccurrences(of: "/private/var", with: "/var") == file1.url.path.replacingOccurrences(of: "/private/var", with: "/var"))
        
        watcher.stopMonitoring()
    }
}
