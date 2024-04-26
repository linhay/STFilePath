//
//  File.swift
//
//
//  Created by linhey on 2024/4/24.
//

import Foundation

import Foundation
#if canImport(Darwin)
import Darwin
import Dispatch
#elseif canImport(Glibc)
import Glibc
import Dispatch
#endif

public extension STFolder {
    
    func backup(options: STFolderBackup.Options) -> STFolderBackup {
        .init(folder: self, options: options)
    }
    
}


public class STFolderBackup {
    
    public struct Options {
        public var watcher: STFolderWatcher.Options
        public var targetFolders: [STFolder]
        public init(watcher: STFolderWatcher.Options, targetFolders: [STFolder]) {
            self.watcher = watcher
            self.targetFolders = targetFolders
        }
    }
    
    public let folder: STFolder
    public let options: Options
    public let watcher: STFolderWatcher
    
    public init(folder: STFolder, options: Options) {
        self.folder = folder
        self.options = options
        self.watcher = .init(folder: folder, options: options.watcher)
    }
    
    @discardableResult
    public func connect() throws -> Self {
        try folder
            .allSubFilePaths()
            .compactMap(\.asFile)
            .forEach { file in
                try self.backup(file: file)
            }
        try self.watcher.connect()
        return self
    }
    
    public func monitoring() async throws {
        for try await changed in try watcher.streamMonitoring() {
            for targetFolder in options.targetFolders {
                try backup(file: changed.file, target: targetFolder, kind: changed.kind)
            }
        }
    }
    
    public func stopMonitoring() {
        watcher.stopMonitoring()
    }
    
    public func backup(file: STFile) throws {
        let path = file.relativePath(from: folder)
        for target in options.targetFolders {
            let target_file = target.file(path)
            if target_file.isExist {
                if target_file.attributes.modificationDate != file.attributes.modificationDate {
                    try backup(file: file, target: target, kind: .changed)
                }
            } else {
                try backup(file: file, target: target, kind: .added)
            }
        }
    }
    
    public func backup(file: STFile, target: STFolder, kind: STFolderWatcher.ChangeKind) throws {
        let path = file.relativePath(from: folder)
        let target_file = target.file(path)
        _ = target_file.parentFolder()?.createIfNotExists()
        switch kind {
        case .deleted:
            _ = try? target_file.delete()
        case .added, .changed:
            _ = try? target_file.delete()
            try file.copy(to: target_file)
            target_file.attributes.modificationDate = file.attributes.modificationDate
        }
    }
    
}
