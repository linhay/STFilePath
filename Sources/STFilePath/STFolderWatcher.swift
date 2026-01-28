//
//  File.swift
//
//
//  Created by linhey on 2023/3/8.
//

import Foundation

#if canImport(Darwin)
    import Darwin
    import Dispatch
#elseif canImport(Glibc)
    import Glibc
    import Dispatch
#endif

extension STFolder {

    /// [en] Creates a watcher for the folder with the specified options.
    /// [zh] 使用指定的选项为文件夹创建一个观察者。
    /// - Parameter options: The options for the watcher.
    /// - Returns: A new `STFolderWatcher` instance.
    public func watcher(options: STFolderWatcher.Options) -> STFolderWatcher {
        .init(folder: self, options: options)
    }

}

/// [en] A class that monitors a folder for changes.
/// [zh] 一个监视文件夹变化的类。
public class STFolderWatcher: @unchecked Sendable {

    /// [en] The kind of change that occurred in the folder.
    /// [zh] 文件夹中发生的变化类型。
    public enum ChangeKind: Sendable {
        case added
        case deleted
        case changed

        init(_ kind: STPathChangeKind) {
            switch kind {
            case .created: self = .added
            case .deleted: self = .deleted
            case .modified, .renamed: self = .changed
            }
        }
    }

    /// [en] A struct that represents a change in the folder.
    /// [zh] 一个表示文件夹变化的结构体。
    public struct Changed: Sendable {
        public let kind: ChangeKind
        public let file: STFile
    }

    /// [en] The options for the folder watcher.
    /// [zh] 文件夹观察者的选项。
    public struct Options: Sendable {
        public var interval: DispatchTimeInterval
        public init(interval: DispatchTimeInterval = .milliseconds(200)) {
            self.interval = interval
        }
    }

    // Properties
    public let folder: STFolder
    public let options: Options
    private let backend: WatcherBackend
    private var continuation: AsyncThrowingStream<Changed, Error>.Continuation?
    private var _stream: AsyncThrowingStream<Changed, Error>?

    // Initialization
    public init(folder: STFolder, options: Options = .init()) {
        self.folder = folder
        self.options = options
        #if os(macOS)
            self.backend = FSEventsWatcher(paths: [folder.path])
        #else
            self.backend = DispatchSourceWatcher(url: folder.url)
        #endif
    }

    deinit {
        stopMonitoring()
    }

    @available(*, deprecated, message: "Use streamMonitoring() instead")
    @discardableResult
    public func connect() throws -> Self {
        return self
    }

    /// [en] Starts monitoring the folder and returns an asynchronous stream of changes.
    /// [zh] 开始监视文件夹并返回一个异步的变化流。
    public func streamMonitoring() throws -> AsyncThrowingStream<Changed, Error> {
        if let stream = self._stream {
            return stream
        }

        let (stream, continuation) = AsyncThrowingStream<Changed, Error>.makeStream()
        self.continuation = continuation
        self._stream = stream

        Task { @Sendable [weak self] in
            guard let self = self else { return }
            do {
                for try await change in self.backend.start() {
                    let folderChange = Changed(
                        kind: ChangeKind(change.kind), file: STFile(change.path.url))
                    self.continuation?.yield(folderChange)
                }
            } catch {
                self.continuation?.finish(throwing: error)
            }
        }

        return stream
    }

    @available(
        *, deprecated, message: "Use stream() from WatcherBackend directly or streamMonitoring()"
    )
    public func monitoring() {
        _ = try? streamMonitoring()
    }

    /// [en] Stops monitoring the folder for changes.
    /// [zh] 停止监视文件夹的变化。
    public func stopMonitoring() {
        backend.stop()
        continuation?.finish()
        _stream = nil
    }
}
