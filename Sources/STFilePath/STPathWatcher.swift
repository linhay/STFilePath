import Foundation

/// [en] A unified class that monitors a path for changes.
/// [zh] 一个统一的监视路径变化的类。
public class STPathWatcher: @unchecked Sendable {
    public let path: STPath
    private let backend: WatcherBackend

    public init(path: STPath) {
        self.path = path
        #if os(macOS)
            if path.isFolderExists {
                self.backend = FSEventsWatcher(paths: [path.path])
            } else {
                self.backend = DispatchSourceWatcher(url: path.url)
            }
        #else
            self.backend = DispatchSourceWatcher(url: path.url)
        #endif
    }

    /// [en] Starts monitoring the path and returns an asynchronous stream of changes.
    /// [zh] 开始监视路径并返回一个异步的变化流。
    public func stream() -> AsyncThrowingStream<STPathChanged, Error> {
        return backend.start()
    }

    /// [en] Stops monitoring the path.
    /// [zh] 停止监视路径。
    public func stop() {
        backend.stop()
    }
}
