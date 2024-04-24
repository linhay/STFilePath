import XCTest
@testable import STFilePath

final class STFilePathTests: XCTestCase {
    
    func test_folder_watcher() async throws {
        let watcher = STFolder("~/Desktop/tests/sources")
            .createIfNotExists()
            .watcher(options: .init(interval: .seconds(1)))
        for try await changed in try watcher.stream() {
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
            .stream()
    }
}
