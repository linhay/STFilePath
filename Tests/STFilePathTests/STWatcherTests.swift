import Foundation
import STFilePath
import Testing

@Suite("Watcher Implementation Tests")
struct STWatcherTests {

    func createTempFolder() throws -> STFolder {
        let tempFolder = STFolder(STFolder.Sanbox.temporary.url).folder(
            "WatcherTests_\(UUID().uuidString)")
        _ = try? tempFolder.delete()
        try tempFolder.create()
        return tempFolder
    }

    @Test("File Watcher - Modification Detection")
    func testSTFileWatcher() async throws {
        let tempFolder = try createTempFolder()
        defer { try? tempFolder.delete() }

        let file = tempFolder.file("test.txt")
        try file.create(with: "initial".data(using: .utf8)!)

        let watcher = file.watcher()
        let stream = watcher.stream()
        let buffer = AsyncEventBuffer<STPathChanged>()
        let consumer = consumeStream(stream, into: buffer)
        defer { watcher.stop() }
        defer { consumer.cancel() }

        try await Task.sleep(nanoseconds: 200_000_000)
        try file.overlay(with: "updated")

        _ = try await waitForMatching(buffer) { next in
            normalizedTemporaryPath(next.path.url.path) == normalizedTemporaryPath(file.url.path)
        }
    }

    @Test("Folder Watcher - Addition Detection")
    func testSTFolderWatcher() async throws {
        let tempFolder = try createTempFolder()
        defer { try? tempFolder.delete() }

        let watcher: STFolderWatcher = tempFolder.watcher(options: .init())
        let stream = try watcher.streamMonitoring()
        let buffer = AsyncEventBuffer<STFolderWatcher.Changed>()
        let consumer = consumeStream(stream, into: buffer)
        defer { watcher.stopMonitoring() }
        defer { consumer.cancel() }

        try await Task.sleep(nanoseconds: 200_000_000)

        let newFile = tempFolder.file("new_file.txt")
        try newFile.create(with: "hello".data(using: .utf8)!)

        _ = try await waitForMatching(buffer) { next in
            normalizedTemporaryPath(next.file.url.path) == normalizedTemporaryPath(newFile.url.path)
                && (next.kind == .added || next.kind == .changed)
        }
    }

    @Test("Path Watcher - Unified Detection")
    func testSTPathWatcher() async throws {
        let tempFolder = try createTempFolder()
        defer { try? tempFolder.delete() }

        let watcher = tempFolder.eraseToAnyPath.watcher()
        let stream = watcher.stream()
        let buffer = AsyncEventBuffer<STPathChanged>()
        let consumer = consumeStream(stream, into: buffer)
        defer { watcher.stop() }
        defer { consumer.cancel() }

        try await Task.sleep(nanoseconds: 200_000_000)

        let anotherFile = tempFolder.file("another.txt")
        try anotherFile.create(with: "world".data(using: .utf8)!)

        _ = try await waitForMatching(buffer) { next in
            normalizedTemporaryPath(next.path.url.path) == normalizedTemporaryPath(anotherFile.url.path)
        }
    }

    @Test("Process Identification")
    func testOpeningProcesses() async throws {
        #if os(macOS)
            let tempFolder = try createTempFolder()
            defer { try? tempFolder.delete() }

            let file = tempFolder.file("locked.txt")
            try file.create(with: "locked".data(using: .utf8)!)

            let handle = try FileHandle(forReadingFrom: file.url)
            defer { try? handle.close() }

            try await Task.sleep(nanoseconds: 500_000_000)

            let processes = file.openingProcesses()
            #expect(!processes.isEmpty)
            let currentPID = Int32(ProcessInfo.processInfo.processIdentifier)
            #expect(processes.contains(where: { $0.pid == currentPID }))
        #endif
    }
}
