import Foundation

#if canImport(Darwin)
import Darwin
#endif
#if os(Linux)
import Glibc
import Dispatch
#endif

/// [en] A file system watcher backend that uses DispatchSource.
/// [zh] 使用 DispatchSource 的文件系统监听后端。
#if canImport(Darwin)
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
#elseif os(Linux)
final class DispatchSourceWatcher: WatcherBackend, @unchecked Sendable {
    private let url: URL
    private var source: DispatchSourceRead?
    private let queue = DispatchQueue(
        label: "com.stfilepath.inotify.watcher", qos: .userInteractive)
    private var continuation: AsyncThrowingStream<STPathChanged, Error>.Continuation?
    private var fileDescriptor: Int32 = -1
    private var watchDescriptor: Int32 = -1

    init(url: URL) {
        self.url = url
    }

    func start() -> AsyncThrowingStream<STPathChanged, Error> {
        let (stream, continuation) = AsyncThrowingStream<STPathChanged, Error>.makeStream()
        self.continuation = continuation

        let fd = inotify_init1(Int32(IN_NONBLOCK))
        if fd < 0 {
            continuation.finish(throwing: STPathError(posix: errno))
            return stream
        }
        self.fileDescriptor = fd

        let mask: UInt32 = UInt32(IN_MODIFY | IN_ATTRIB | IN_DELETE_SELF | IN_MOVE_SELF)
        let wd = inotify_add_watch(fd, url.path, mask)
        if wd < 0 {
            close(fd)
            continuation.finish(throwing: STPathError(posix: errno))
            return stream
        }
        self.watchDescriptor = wd

        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            var buffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let bytesRead = read(self.fileDescriptor, &buffer, buffer.count)
                if bytesRead <= 0 {
                    break
                }
                var offset = 0
                while offset < bytesRead {
                    let eventPtr = buffer.withUnsafeBytes { raw -> UnsafePointer<inotify_event> in
                        return raw.baseAddress!
                            .advanced(by: offset)
                            .assumingMemoryBound(to: inotify_event.self)
                    }
                    let mask = eventPtr.pointee.mask
                    let stPath = STPath(self.url)

                    if (mask & UInt32(IN_MOVE_SELF)) != 0 {
                        self.continuation?.yield(STPathChanged(kind: .renamed, path: stPath))
                    } else if (mask & UInt32(IN_DELETE_SELF)) != 0 {
                        self.continuation?.yield(STPathChanged(kind: .deleted, path: stPath))
                    } else {
                        self.continuation?.yield(STPathChanged(kind: .modified, path: stPath))
                    }

                    let nameLen = Int(eventPtr.pointee.len)
                    offset += MemoryLayout<inotify_event>.size + nameLen
                }
            }
        }

        source.setCancelHandler { [fileDescriptor, watchDescriptor] in
            if watchDescriptor >= 0 {
                _ = inotify_rm_watch(fileDescriptor, UInt32(watchDescriptor))
            }
            if fileDescriptor >= 0 {
                close(fileDescriptor)
            }
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
#else
final class DispatchSourceWatcher: WatcherBackend, @unchecked Sendable {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func start() -> AsyncThrowingStream<STPathChanged, Error> {
        let (stream, continuation) = AsyncThrowingStream<STPathChanged, Error>.makeStream()
        continuation.finish(
            throwing: STPathError(
                message: "DispatchSource file watcher is only available on Darwin platforms. (\(url.path))"
            )
        )
        return stream
    }

    func stop() {}
}
#endif
