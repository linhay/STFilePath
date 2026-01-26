import Foundation

/// [en] A class that monitors a file for changes.
/// [zh] 一个监视文件变化的类。
public class STFileWatcher: @unchecked Sendable {
    public let file: STFile
    private let backend: WatcherBackend

    public init(file: STFile) {
        self.file = file
        self.backend = DispatchSourceWatcher(url: file.url)
    }

    /// [en] Starts monitoring the file and returns an asynchronous stream of changes.
    /// [zh] 开始监视文件并返回一个异步的变化流。
    public func stream() -> AsyncThrowingStream<STPathChanged, Error> {
        return backend.start()
    }

    /// [en] Stops monitoring the file.
    /// [zh] 停止监视文件。
    public func stop() {
        backend.stop()
    }
}
