import Foundation

/// [en] A file system watcher backend that uses DispatchSource.
/// [zh] 使用 DispatchSource 的文件系统监听后端。
final class DispatchSourceWatcher: WatcherBackend, @unchecked Sendable {
    private let url: URL
    private var source: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(
        label: "com.stfilepath.dispatchsource.watcher", qos: .userInteractive)
    private var continuation: AsyncThrowingStream<STPathChanged, Error>.Continuation?

    init(url: URL) {
        self.url = url
    }

    func start() -> AsyncThrowingStream<STPathChanged, Error> {
        let (stream, continuation) = AsyncThrowingStream<STPathChanged, Error>.makeStream()
        self.continuation = continuation

        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            continuation.finish(throwing: STPathError(message: "Failed to open path: \(url.path)"))
            return stream
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .delete, .rename, .extend, .attrib],
            queue: queue)

        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let flags = source.data
            let stPath = STPath(self.url)

            if flags.contains(.rename) {
                self.continuation?.yield(STPathChanged(kind: .renamed, path: stPath))
            } else if flags.contains(.delete) {
                self.continuation?.yield(STPathChanged(kind: .deleted, path: stPath))
            } else {
                self.continuation?.yield(STPathChanged(kind: .modified, path: stPath))
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        self.source = source
        source.resume()

        return stream
    }

    func stop() {
        source?.cancel()
        source = nil
        continuation?.finish()
    }

    deinit {
        stop()
    }
}
