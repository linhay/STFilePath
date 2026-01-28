// Example usage of STFilePath APIs (API-accurate snippets)
import Foundation
import STFilePath

func example() async throws {
    let documents = try STFolder(sanbox: .document)
    let demo = try documents.folder("SkillDemo").create()

    let file = try demo.file("hello.txt").create(with: Data("Hello from skill example".utf8))
    let content = try file.read()
    print("Read content:\n\(content)")

    let sha = try file.hash(with: .sha256)
    print("Hash: \(sha)")

    try file.append(data: Data("\nAppended line".utf8))

    // Demonstrate folder watcher (short-lived example)
    let watcher = demo.watcher(options: .init(interval: .seconds(1)))
    Task {
        do {
            for try await change in try watcher.streamMonitoring() {
                print("Watcher: file \(change.file.url.lastPathComponent) was \(change.kind)")
            }
        } catch {
            print("Watcher error: \(error)")
        }
    }

    // `connect()` / `monitoring()` are deprecated; keep the stream alive by awaiting in Task above.
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
