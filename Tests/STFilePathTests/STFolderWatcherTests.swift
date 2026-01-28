import Testing
import STFilePath
import Foundation

@Suite("STFolderWatcher Tests")
struct STFolderWatcherTests {

    @available(iOS 16.0, *)
    @Test("Folder Watcher Operations")
    func testWatcher() async throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        try testFolder.create()

        let watcher = testFolder.watcher(options: .init(interval: .milliseconds(100)))
        let stream = try watcher.streamMonitoring()
        let buffer = AsyncEventBuffer<STFolderWatcher.Changed>()
        let consumer = consumeStream(stream, into: buffer)
        defer { watcher.stopMonitoring() }
        defer { consumer.cancel() }
        
        // Give the backend a brief moment to start before triggering file system events.
        try await Task.sleep(nanoseconds: 200_000_000)

        // 1. Test file creation
        let file1 = testFolder.file("file1.txt")
        try file1.create(with: "hello".data(using: .utf8))
        var change: STFolderWatcher.Changed
        do {
            change = try await waitForMatching(buffer) { change in
                normalizedTemporaryPath(change.file.url.path) == normalizedTemporaryPath(file1.url.path)
                    && (change.kind == .added || change.kind == .changed)
            }
        } catch {
            let snapshot = await buffer.snapshot()
            let debug = snapshot
                .map { "\($0.kind) \($0.file.url.path)" }
                .joined(separator: "\n")
            throw WatcherTestTimeoutError(
                message: "Create event not observed for \(file1.url.path). Buffered events:\n\(debug)"
            )
        }
        #expect(normalizedTemporaryPath(change.file.url.path) == normalizedTemporaryPath(file1.url.path))

        // 2. Test file modification
        try await Task.sleep(nanoseconds: 200_000_000)
        try file1.overlay(with: "world".data(using: .utf8))
        do {
            change = try await waitForMatching(buffer) { change in
                normalizedTemporaryPath(change.file.url.path) == normalizedTemporaryPath(file1.url.path)
                    && change.kind == .changed
            }
        } catch {
            let snapshot = await buffer.snapshot()
            let debug = snapshot
                .map { "\($0.kind) \($0.file.url.path)" }
                .joined(separator: "\n")
            throw WatcherTestTimeoutError(
                message: "Modify event not observed for \(file1.url.path). Buffered events:\n\(debug)"
            )
        }
        #expect(normalizedTemporaryPath(change.file.url.path) == normalizedTemporaryPath(file1.url.path))

        // 3. Test file deletion
        try await Task.sleep(nanoseconds: 200_000_000)
        try file1.delete()
        do {
            change = try await waitForMatching(buffer) { change in
                normalizedTemporaryPath(change.file.url.path) == normalizedTemporaryPath(file1.url.path)
                    && (change.kind == .deleted || change.kind == .changed)
            }
        } catch {
            let snapshot = await buffer.snapshot()
            let debug = snapshot
                .map { "\($0.kind) \($0.file.url.path)" }
                .joined(separator: "\n")
            throw WatcherTestTimeoutError(
                message: "Delete event not observed for \(file1.url.path). Buffered events:\n\(debug)"
            )
        }
        #expect(normalizedTemporaryPath(change.file.url.path) == normalizedTemporaryPath(file1.url.path))
        #expect(file1.isExists == false)
    }
}
