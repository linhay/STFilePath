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
    
    /// [en] Creates a backup of the folder with the specified options.
    /// [zh] 使用指定的选项创建文件夹的备份。
    /// - Parameter options: The options for the backup.
    /// - Returns: A new `STFolderBackup` instance.
    func backup(options: STFolderBackup.Options) -> STFolderBackup {
        .init(folder: self, options: options)
    }
    
}


/// [en] A class that backs up a folder to one or more target folders.
/// [zh] 一个将文件夹备份到一个或多个目标文件夹的类。
public class STFolderBackup {
    
    /// [en] The options for the folder backup.
    /// [zh] 文件夹备份的选项。
    public struct Options {
        /// [en] The options for the folder watcher.
        /// [zh] 文件夹观察者的选项。
        public var watcher: STFolderWatcher.Options
        /// [en] The target folders to back up to.
        /// [zh] 要备份到的目标文件夹。
        public var targetFolders: [STFolder]
        public init(watcher: STFolderWatcher.Options, targetFolders: [STFolder]) {
            self.watcher = watcher
            self.targetFolders = targetFolders
        }
    }
    
    /// [en] The folder to back up.
    /// [zh] 要备份的文件夹。
    public let folder: STFolder
    /// [en] The options for the backup.
    /// [zh] 备份的选项。
    public let options: Options
    /// [en] The folder watcher.
    /// [zh] 文件夹观察者。
    public let watcher: STFolderWatcher
    
    /// [en] Initializes a new `STFolderBackup` instance.
    /// [zh] 初始化一个新的 `STFolderBackup` 实例。
    /// - Parameters:
    ///   - folder: The folder to back up.
    ///   - options: The options for the backup.
    public init(folder: STFolder, options: Options) {
        self.folder = folder
        self.options = options
        self.watcher = .init(folder: folder, options: options.watcher)
    }
    
    /// [en] Connects the backup and performs an initial backup.
    /// [zh] 连接备份并执行初始备份。
    /// - Returns: The `STFolderBackup` instance.
    /// - Throws: An error if the initial backup fails.
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
    
    /// [en] Starts monitoring the folder for changes and backs them up.
    /// [zh] 开始监视文件夹的更改并进行备份。
    /// - Throws: An error if monitoring fails.
    public func monitoring() async throws {
        for try await changed in try watcher.streamMonitoring() {
            for targetFolder in options.targetFolders {
                try backup(file: changed.file, target: targetFolder, kind: changed.kind)
            }
        }
    }
    
    /// [en] Stops monitoring the folder for changes.
    /// [zh] 停止监视文件夹的更改。
    public func stopMonitoring() {
        watcher.stopMonitoring()
    }
    
    /// [en] Backs up a single file to all target folders.
    /// [zh] 将单个文件备份到所有目标文件夹。
    /// - Parameter file: The file to back up.
    /// - Throws: An error if the backup fails.
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
    
    /// [en] Backs up a single file to a target folder.
    /// [zh] 将单个文件备份到目标文件夹。
    /// - Parameters:
    ///   - file: The file to back up.
    ///   - target: The target folder.
    ///   - kind: The kind of change that occurred.
    /// - Throws: An error if the backup fails.
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
