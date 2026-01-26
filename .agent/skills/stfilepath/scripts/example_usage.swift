// Example usage of STFilePath APIs - minimal reproducible Swift script
import Foundation
import STFilePath

func example() async throws {
    let documents = STFolder.documents
    let demo = try documents.folder(name: "SkillDemo").create()

    let file = try demo.file(name: "hello.txt").create(with: "Hello from skill example".data(using: .utf8))
    let content = try file.read()
    print("Read content:\n\(content)")

    let sha = try file.hash(with: .sha256)
    print("Hash: \(sha)")

    try file.append(data: "\nAppended line".data(using: .utf8))

    // Demonstrate folder watcher (short-lived example)
    let watcher = demo.watcher(options: .init(interval: .seconds(1)))
    Task {
        do {
            for try await change in try watcher.streamMonitoring() {
                print("Watcher: file \(change.file.name) was \(change.kind)")
            }
        } catch {
            print("Watcher error: \(error)")
        }
    }

    try watcher.connect()
    watcher.monitoring()
}

@main
struct RunExample {
    static func main() async {
        do {
            try await example()
        } catch {
            print("Example failed: \(error)")
        }
    }
}
