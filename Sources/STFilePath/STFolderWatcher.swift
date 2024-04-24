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
   
    func watcher(options: STFolderWatcher.Options) -> STFolderWatcher {
        .init(folder: self, options: options)
    }
    
}

public class STFolderWatcher {
    
    public enum ChangeKind {
        case added
        case deleted
        case changed
    }
    
    public struct Changed {
        public let kind: ChangeKind
        public let file: STFile
    }
    
    public struct Options {
        public var interval: DispatchTimeInterval
        public init(interval: DispatchTimeInterval) {
            self.interval = interval
        }
    }
    
    // Properties
    public let folder: STFolder
    public let options: Options
    private var timer: DispatchSourceTimer?
    private var previousContents = [STFile: Date]()
    private var continuation: AsyncThrowingStream<Changed, Error>.Continuation?
    private var _stream: AsyncThrowingStream<Changed, Error>?

    // Initialization
    public init(folder: STFolder, options: Options) {
        self.folder = folder
        self.options = options
    }
    
    deinit {
        continuation?.finish()
    }
    
    @discardableResult
    public func connect() throws -> Self {
        let files = try folder.allSubFilePaths().compactMap(\.asFile)
        for file in files {
            previousContents[file] = file.attributes.modificationDate
        }
        return self
    }
    
    // Stream
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
