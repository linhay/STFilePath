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

public extension STFolder {
   
    /// [en] Creates a watcher for the folder with the specified options.
    /// [zh] 使用指定的选项为文件夹创建一个观察者。
    /// - Parameter options: The options for the watcher.
    /// - Returns: A new `STFolderWatcher` instance.
    func watcher(options: STFolderWatcher.Options) -> STFolderWatcher {
        .init(folder: self, options: options)
    }
    
}

/// [en] A class that monitors a folder for changes.
/// [zh] 一个监视文件夹变化的类。
public class STFolderWatcher {
    
    /// [en] The kind of change that occurred in the folder.
    /// [zh] 文件夹中发生的变化类型。
    public enum ChangeKind {
        /// [en] A new file was added.
        /// [zh] 添加了一个新文件。
        case added
        /// [en] A file was deleted.
        /// [zh] 删除了一个文件。
        case deleted
        /// [en] A file was changed.
        /// [zh] 一个文件被更改了。
        case changed
    }
    
    /// [en] A struct that represents a change in the folder.
    /// [zh] 一个表示文件夹变化的结构体。
    public struct Changed {
        /// [en] The kind of change.
        /// [zh] 变化的类型。
        public let kind: ChangeKind
        /// [en] The file that was changed.
        /// [zh] 被更改的文件。
        public let file: STFile
    }
    
    /// [en] The options for the folder watcher.
    /// [zh] 文件夹观察者的选项。
    public struct Options {
        /// [en] The interval at which to check for changes.
        /// [zh] 检查变化的时间间隔。
        public var interval: DispatchTimeInterval
        public init(interval: DispatchTimeInterval) {
            self.interval = interval
        }
    }
    
    // Properties
    /// [en] The folder being watched.
    /// [zh] 被监视的文件夹。
    public let folder: STFolder
    /// [en] The options for the watcher.
    /// [zh] 观察者的选项。
    public let options: Options
    private var timer: DispatchSourceTimer?
    private var previousContents = [STFile: Date]()
    private var continuation: AsyncThrowingStream<Changed, Error>.Continuation?
    private var _stream: AsyncThrowingStream<Changed, Error>?

    // Initialization
    /// [en] Initializes a new `STFolderWatcher` instance.
    /// [zh] 初始化一个新的 `STFolderWatcher` 实例。
    /// - Parameters:
    ///   - folder: The folder to watch.
    ///   - options: The options for the watcher.
    public init(folder: STFolder, options: Options) {
        self.folder = folder
        self.options = options
    }
    
    deinit {
        timer?.cancel()
        continuation?.finish()
    }
    
    /// [en] Connects the watcher to the folder and captures the initial state.
    /// [zh] 将观察者连接到文件夹并捕获初始状态。
    /// - Returns: The `STFolderWatcher` instance.
    /// - Throws: An error if the initial state cannot be captured.
    @discardableResult
    public func connect() throws -> Self {
        let files = try folder.allSubFilePaths().compactMap(\.asFile)
        for file in files {
            previousContents[file] = file.attributes.modificationDate
        }
        return self
    }
    
    // Stream
    /// [en] Starts monitoring the folder and returns an asynchronous stream of changes.
    /// [zh] 开始监视文件夹并返回一个异步的变化流。
    /// - Returns: An `AsyncThrowingStream` of `Changed` events.
    /// - Throws: An error if the stream cannot be created.
    public func streamMonitoring() throws -> AsyncThrowingStream<Changed, Error> {
        if let stream = self._stream {
            return stream
        }
        let (stream, continuation) = AsyncThrowingStream<Changed, Error>.makeStream()
        self.continuation = continuation
        self._stream = stream
        monitoring()
        return stream
    }
    
    /// [en] Starts the monitoring timer.
    /// [zh] 启动监视计时器。
    public func monitoring() {
        guard timer == nil else { return }
        
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: options.interval)
        timer.setEventHandler { [weak self] in
            self?.checkFolderChanges()
        }
        timer.resume()
        self.timer = timer
    }
    
    // Stop Monitoring
    /// [en] Stops monitoring the folder for changes.
    /// [zh] 停止监视文件夹的变化。
    public func stopMonitoring() {
        timer?.cancel()
        timer = nil
        continuation?.finish()
        _stream = nil
    }
    
    // Private Method to Check Folder Changes
    private func checkFolderChanges() {
        do {
            let files = try folder.allSubFilePaths().compactMap(\.asFile)
            
            for file in files {
                if let modificationDate = previousContents[file] {
                    if file.attributes.modificationDate != modificationDate {
                        let change = Changed(kind: .changed, file: file)
                        continuation?.yield(change)
                        previousContents[file] = file.attributes.modificationDate
                    }
                } else {
                    let change = Changed(kind: .added, file: file)
                    continuation?.yield(change)
                    previousContents[file] = file.attributes.modificationDate
                }
            }
            
            Set(previousContents.keys).subtracting(files).forEach { file in
                let change = Changed(kind: .deleted, file: file)
                continuation?.yield(change)
                previousContents[file] = nil
            }
        } catch {
            continuation?.finish(throwing: error)
        }
    }
    
}
