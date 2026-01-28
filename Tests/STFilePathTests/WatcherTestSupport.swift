import Foundation
import Testing

struct WatcherTestTimeoutError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

actor AsyncEventBuffer<Element: Sendable> {
    private var buffer: [Element] = []

    func push(_ element: Element) {
        buffer.append(element)
    }

    func popFirst(where match: @Sendable (Element) -> Bool) -> Element? {
        guard let index = buffer.firstIndex(where: match) else { return nil }
        return buffer.remove(at: index)
    }

    func snapshot() -> [Element] {
        buffer
    }
}

func normalizedTemporaryPath(_ path: String) -> String {
    path.replacingOccurrences(of: "/private/var", with: "/var")
}

func consumeStream<Element: Sendable>(
    _ stream: AsyncThrowingStream<Element, Error>,
    into buffer: AsyncEventBuffer<Element>
) -> Task<Void, Never> {
    Task { @Sendable in
        do {
            for try await element in stream {
                await buffer.push(element)
            }
        } catch {
            // Test helper: ignore stream errors; tests assert on expected behavior via timeouts.
        }
    }
}

func waitForMatching<Element: Sendable>(
    _ buffer: AsyncEventBuffer<Element>,
    timeoutNanoseconds: UInt64 = 5_000_000_000,
    pollNanoseconds: UInt64 = 20_000_000,
    where match: @escaping @Sendable (Element) -> Bool
) async throws -> Element {
    let start = DispatchTime.now().uptimeNanoseconds
    while DispatchTime.now().uptimeNanoseconds - start < timeoutNanoseconds {
        if let found = await buffer.popFirst(where: match) {
            return found
        }
        try await Task.sleep(nanoseconds: pollNanoseconds)
    }
    throw WatcherTestTimeoutError(message: "Timed out waiting for matching watcher event in \(timeoutNanoseconds)ns")
}
