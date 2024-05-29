import XCTest
@testable import STFilePath

final class STFilePathTests: XCTestCase {

    func test_stream_read_write() async throws {
        let folder = STFolder("~/Desktop/tests/sources")
        let from = try folder.file("from.txt").overlay(with:
                                                        ((1...10000)
                                                            .map(\.description)
                                                            .joined(separator: "\n")
                                                            .data(using: .utf8)
                                                        ))
        let to = try folder.file("to").createIfNotExists().overlay(with: .init()).handle(.writing)
        try await from.readStream(handle: from.handle(.reading), chunkSize: 1) { slice in
           try to.write(contentsOf: slice.data)
        } finish: { handle in
            try to.close()
            try handle.close()
        }
    }
    
    func test_folder_watcher() async throws {
        let watcher = try STFolder("~/Desktop/tests/sources")
            .createIfNotExists()
            .watcher(options: .init(interval: .seconds(1)))
            .connect()
        for try await changed in try watcher.streamMonitoring() {
            print(changed.kind, changed.file.path)
        }
    }
    
    func test_folder_backup() async throws {
        try await STFolder("~/Desktop/tests/sources")
            .createIfNotExists()
            .backup(options: .init(watcher: .init(interval: .seconds(1)),
                                   targetFolders: [
                                    STFolder("~/Desktop/tests/backup1"),
                                    STFolder("~/Desktop/tests/backup2"),
                                   ]))
            .connect()
            .monitoring()
    }
}
