//
//  File.swift
//  
//
//  Created by linhey on 2023/3/8.
//

#if canImport(Combine) && canImport(Darwin)
import Foundation
import Combine

public final class STFolderWatcher {
    public private(set) lazy var publisher = subject.eraseToAnyPublisher()
    private let subject = PassthroughSubject<Void, Never>()
    
    // MARK: Initializers
    public convenience init(_ folder: STFolder, eventMask: DispatchSource.FileSystemEvent = .write) {
        self.init(folder.url, eventMask: eventMask)
    }
    
    public init(_ url: URL, eventMask: DispatchSource.FileSystemEvent = .write) {
        self.url = url
        self.eventMask = eventMask
    }
    
    deinit {
        stopMonitoring()
    }
    
    private let eventMask: DispatchSource.FileSystemEvent
    private var fileDescriptor: CInt = -1
    private let queue = DispatchQueue(label: "directorymonitor", attributes: .concurrent)
    private var source: DispatchSourceFileSystemObject?
    private var url: URL
    private var snapshot = Set<STPath>()
}

public extension STFolderWatcher {
    
    struct Difference {
        public let new: Set<STPath>
        public let deleted: Set<STPath>
        public let current: Set<STPath>
    }
    
    func differencePublisher(subPath predicates: [STFolder.SearchPredicate] = [.skipsHiddenFiles]) -> AnyPublisher<Difference, Error> {
        publisher
            .debounce(for: 0.2, scheduler: queue)
            .tryMap({ [weak self] _ in
                guard let self = self else { return .init(new: .init(), deleted: .init(), current: .init()) }
                let paths = Set(try STFolder(self.url).subFilePaths(predicates))
                self.snapshot = paths
                let deleted = self.snapshot.subtracting(paths)
                let new = paths.subtracting(self.snapshot)
                return Difference(new: new, deleted: deleted, current: paths)
            }).eraseToAnyPublisher()
    }
    
    // MARK: Monitoring
    func startMonitoring() throws {
        guard STFolder(url).isExist else {
            throw try STPathError.noSuchFile(url.path)
        }
        guard source == nil, fileDescriptor == -1 else {
            return
        }
        fileDescriptor = Darwin.open((url as NSURL).fileSystemRepresentation, O_EVTONLY)
        guard fileDescriptor != -1 else {
            return
        }
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: eventMask, queue: queue)
        source?.setEventHandler { [weak self] in
            guard let self = self,
                  let events = self.source?.data,
                  events.contains(self.eventMask) else {
                return
            }
            self.subject.send()
        }
        
        source?.setCancelHandler { [weak self] in
            guard let self = self else {
                return
            }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
            self.source = nil
        }
        
        source?.resume()
    }
    
    func stopMonitoring() {
        if source != nil {
            source?.cancel()
        }
    }
    
}
#endif
