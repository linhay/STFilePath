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

        try await Task.sleep(nanoseconds: 500_000_000)

        try file.overlay(with: "updated")

        var iterator = stream.makeAsyncIterator()

        // Use a task group or a simple timeout-like check
        // We expect at most a few events
        let expectationTask = Task {
            while let next = try await iterator.next() {
                if next.path.url.lastPathComponent == "test.txt" {
                    return true
                }
            }
            return false
        }

        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                return try await expectationTask.value
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 5_000_000_000)  // 5s timeout
                expectationTask.cancel()
                return false
            }
            let firstResult = try await group.next() ?? false
            group.cancelAll()
            return firstResult
        }

        #expect(result, "Did not receive any event for test.txt within 5s")
        watcher.stop()
    }

    @Test("Folder Watcher - Addition Detection")
    func testSTFolderWatcher() async throws {
        let tempFolder = try createTempFolder()
        defer { try? tempFolder.delete() }

        let watcher: STFolderWatcher = tempFolder.watcher(options: .init())
        let stream = try watcher.streamMonitoring()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let newFile = tempFolder.file("new_file.txt")
        try newFile.create(with: "hello".data(using: .utf8)!)

        var iterator = stream.makeAsyncIterator()

        let expectationTask = Task {
            while let next = try await iterator.next() {
                if next.file.url.lastPathComponent == "new_file.txt" {
                    return true
                }
            }
            return false
        }

        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                return try await expectationTask.value
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                expectationTask.cancel()
                return false
            }
            let firstResult = try await group.next() ?? false
            group.cancelAll()
            return firstResult
        }

        #expect(result, "Did not receive any event for new_file.txt within 5s")
        watcher.stopMonitoring()
    }

    @Test("Path Watcher - Unified Detection")
    func testSTPathWatcher() async throws {
        let tempFolder = try createTempFolder()
        defer { try? tempFolder.delete() }

        let watcher = tempFolder.eraseToAnyPath.watcher()
        let stream = watcher.stream()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let anotherFile = tempFolder.file("another.txt")
        try anotherFile.create(with: "world".data(using: .utf8)!)

        var iterator = stream.makeAsyncIterator()
        var found = false

        let expectationTask = Task {
            while let next = try await iterator.next() {
                if next.path.url.lastPathComponent == "another.txt" {
                    return true
                }
            }
            return false
        }

        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                return try await expectationTask.value
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                expectationTask.cancel()
                return false
            }
            let firstResult = try await group.next() ?? false
            group.cancelAll()
            return firstResult
        }

        #expect(result, "Did not receive event for another.txt within 5s")
        watcher.stop()
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
