#if canImport(Darwin)
    import Foundation

    #if os(macOS)
        /// [en] A file system watcher backend that uses macOS FSEvents.
        /// [zh] 使用 macOS FSEvents 的文件系统监听后端。
        final class FSEventsWatcher: WatcherBackend, @unchecked Sendable {
            private let paths: [String]
            private let sinceWhen: FSEventStreamEventId
            private let latency: CFTimeInterval
            private let flags: FSEventStreamCreateFlags

            private var streamRef: FSEventStreamRef?
            private let queue = DispatchQueue(
                label: "com.stfilepath.fsevents.watcher", qos: .userInteractive)
            private var continuation: AsyncThrowingStream<STPathChanged, Error>.Continuation?

            init(
                paths: [String],
                sinceWhen: FSEventStreamEventId = FSEventStreamEventId(
                    kFSEventStreamEventIdSinceNow),
                latency: CFTimeInterval = 0.01,
                flags: FSEventStreamCreateFlags = FSEventStreamCreateFlags(
                    kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
            ) {
                self.paths = paths
                self.sinceWhen = sinceWhen
                self.latency = latency
                self.flags = flags
            }

            func start() -> AsyncThrowingStream<STPathChanged, Error> {
                let (stream, continuation) = AsyncThrowingStream<STPathChanged, Error>.makeStream()
                self.continuation = continuation

                var context = FSEventStreamContext(
                    version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil,
                    release: nil, copyDescription: nil)

                let callback: FSEventStreamCallback = {
                    streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIDs in
                    guard let clientCallBackInfo = clientCallBackInfo else { return }
                    let watcher = Unmanaged<FSEventsWatcher>.fromOpaque(clientCallBackInfo)
                        .takeUnretainedValue()
                    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]

                    for i in 0..<numEvents {
                        let path = paths[i]
                        let flag = eventFlags[i]
                        watcher.handleEvent(path: path, flags: flag)
                    }
                }

                guard
                    let streamRef = FSEventStreamCreate(
                        kCFAllocatorDefault,
                        callback,
                        &context,
                        paths as CFArray,
                        sinceWhen,
                        latency,
                        flags)
                else {
                    continuation.finish(
                        throwing: STPathError(message: "Failed to create FSEventStream"))
                    return stream
                }

                self.streamRef = streamRef
                FSEventStreamSetDispatchQueue(streamRef, queue)
                if !FSEventStreamStart(streamRef) {
                    continuation.finish(
                        throwing: STPathError(message: "Failed to start FSEventStream"))
                    return stream
                }

                return stream
            }

            private func handleEvent(path: String, flags: FSEventStreamEventFlags) {
                let stPath = STPath(URL(fileURLWithPath: path))

                // FSEvents flags can be combined, so we try to find the most relevant one
                if flags & UInt32(kFSEventStreamEventFlagItemRenamed) != 0 {
                    continuation?.yield(STPathChanged(kind: .renamed, path: stPath))
                } else if flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0 {
                    continuation?.yield(STPathChanged(kind: .deleted, path: stPath))
                } else if flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0 {
                    continuation?.yield(STPathChanged(kind: .created, path: stPath))
                } else {
                    continuation?.yield(STPathChanged(kind: .modified, path: stPath))
                }
            }

            func stop() {
                if let streamRef = streamRef {
                    FSEventStreamStop(streamRef)
                    FSEventStreamInvalidate(streamRef)
                    FSEventStreamRelease(streamRef)
                    self.streamRef = nil
                }
                continuation?.finish()
            }

            deinit {
                stop()
            }
        }
    #endif
#endif
