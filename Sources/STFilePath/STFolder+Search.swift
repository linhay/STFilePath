//
//  File.swift
//
//
//  Created by linhey on 2023/3/15.
//

import Foundation

public extension STFolder {
    
    /// [en] Predicates for searching in a folder.
    /// [zh] 在文件夹中搜索的谓词。
    enum SearchPredicate {
        /// [en] Skip subdirectory and descendant folders.
        /// [zh] 跳过子目录和后代文件夹。
        case skipsSubdirectoryDescendants
        /// [en] Skip packages and their descendant folders.
        /// [zh] 跳过包及其后代文件夹。
        case skipsPackageDescendants
        /// [en] Skip hidden files.
        /// [zh] 跳过隐藏文件。
        case skipsHiddenFiles
        /// [en] Include descendant directories in the enumeration.
        /// [zh] 在枚举中包括后代目录。
        @available(iOS 13.0, *) @available(macOS 10.15, *) @available(tvOS 13.0, *)
        case includesDirectoriesPostOrder
        /// [en] Generate relative path URLs.
        /// [zh] 生成相对路径的 URL。
        @available(iOS 13.0, *) @available(macOS 10.15, *) @available(tvOS 13.0, *)
        case producesRelativePathURLs
        /// [en] Custom search predicate.
        /// [zh] 自定义搜索谓词。
        case custom((STPath) throws -> Bool)
    }
    
}


extension Array where Element == STFolder.SearchPredicate {
    
    func split() -> (system: FileManager.DirectoryEnumerationOptions, custom: [(STPath) throws -> Bool]) {
        var systemPredicates: FileManager.DirectoryEnumerationOptions = []
        var customPredicates = [(STPath) throws -> Bool]()
        
        self.forEach { item in
            switch item {
            case .skipsSubdirectoryDescendants:
                systemPredicates.insert(.skipsSubdirectoryDescendants)
            case .skipsPackageDescendants:
                systemPredicates.insert(.skipsPackageDescendants)
            case .skipsHiddenFiles:
                systemPredicates.insert(.skipsHiddenFiles)
            case .includesDirectoriesPostOrder:
#if os(iOS)
                if #available(iOS 13.0, *) {
                    systemPredicates.insert(.includesDirectoriesPostOrder)
                }
#elseif os(tvOS)
                if #available(tvOS 13.0, *) {
                    systemPredicates.insert(.includesDirectoriesPostOrder)
                }
#elseif os(macOS)
                if #available(macOS 10.15, *) {
                    systemPredicates.insert(.includesDirectoriesPostOrder)
                }
#endif
            case .producesRelativePathURLs:
#if os(iOS)
                if #available(iOS 13.0, *) {
                    systemPredicates.insert(.producesRelativePathURLs)
                }
#elseif os(tvOS)
                if #available(tvOS 13.0, *) {
                    systemPredicates.insert(.producesRelativePathURLs)
                }
#elseif os(macOS)
                if #available(macOS 10.15, *) {
                    systemPredicates.insert(.producesRelativePathURLs)
                }
#endif
            case .custom(let v):
                customPredicates.append(v)
            }
        }
        
        return (systemPredicates, customPredicates)
    }
    
}

public extension STFolder {
    
    /// [en] Checks if the folder contains the given path.
    /// [zh] 检查文件夹是否包含给定的路径。
    /// - Parameter predicate: The path to check for.
    /// - Returns: `true` if the folder contains the path, `false` otherwise.
    @inlinable
    func contains<Element: STPathProtocol>(_ predicate: Element) -> Bool {
        let components = self.url.pathComponents
        return Array(predicate.url.pathComponents.prefix(components.count)) == components
    }
    
}

public extension STFolder {
    
    /// [en] Returns all files in the folder that match the given predicates.
    /// [zh] 返回文件夹中与给定谓词匹配的所有文件。
    /// - Parameter predicates: The predicates to filter the files with.
    /// - Returns: An array of files.
    /// - Throws: An error if the files cannot be retrieved.
    func files(_ predicates: [SearchPredicate] = []) throws -> [STFile] {
        try subFilePaths(predicates).compactMap(\.asFile)
    }
    
    /// [en] Returns all folders in the folder that match the given predicates.
    /// [zh] 返回文件夹中与给定谓词匹配的所有文件夹。
    /// - Parameter predicates: The predicates to filter the folders with.
    /// - Returns: An array of folders.
    /// - Throws: An error if the folders cannot be retrieved.
    func folders(_ predicates: [SearchPredicate] = []) throws -> [STFolder] {
        try subFilePaths(predicates).compactMap(\.asFolder)
    }
    
    /// [en] Recursively gets all files and folders in the folder.
    /// [zh] 递归获取文件夹中的所有文件和文件夹。
    /// - Parameter predicates: The predicates to filter the items with.
    /// - Returns: An array of paths.
    /// - Throws: An error if the items cannot be retrieved.
    func allSubFilePaths(_ predicates: [SearchPredicate] = []) throws -> [STPath] {
        let (systemPredicates, customPredicates) = predicates.split()
        guard let enumerator = manager.enumerator(at: url,
                                                  includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                                                  options: systemPredicates,
                                                  errorHandler: nil) else {
            return []
        }
        
        var list = [STPath]()
        for case let fileURL as URL in enumerator {
            let item = STPath(fileURL)
            if try customPredicates.contains(where: { try $0(item) == false }) {
                continue
            }
            
            list.append(item)
        }
        return list
    }
    
    /// [en] Gets all files and folders in the current folder.
    /// [zh] 获取当前文件夹中的所有文件和文件夹。
    /// - Parameter predicates: The predicates to filter the items with.
    /// - Returns: An array of paths.
    /// - Throws: An error if the items cannot be retrieved.
    func subFilePaths(_ predicates: [SearchPredicate] = []) throws -> [STPath] {
        let (systemPredicates, customPredicates) = predicates.split()
        return try manager
            .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: systemPredicates)
            .compactMap({ STPath($0) })
            .filter({ item -> Bool in
                return try customPredicates.contains(where: { try $0(item) == false }) == false
            })
    }
    
    typealias FileFilter = @Sendable (_ file: STFile) throws -> Bool
    typealias FolderFilter = @Sendable (_ folder: STFolder) throws -> Bool

    /// [en] Scans the folder for files.
    /// [zh] 扫描文件夹以查找文件。
    /// - Parameters:
    ///   - folderFilter: A filter to apply to folders.
    ///   - fileFilter: A filter to apply to files.
    /// - Returns: An asynchronous stream of files.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func files(matching fileFilter: FileFilter, in folderFilter: FolderFilter) throws -> [STFile] {
        let items = try subFilePaths()
        var result = [STFile]()
        for item in items {
            switch item.referenceType {
            case .file(let file):
                if try fileFilter(file) {
                    result.append(file)
                }
            case .folder(let folder):
                if try folderFilter(folder) {
                    let subFiles = try folder.files(matching: fileFilter, in: folderFilter)
                    result.append(contentsOf: subFiles)
                }
            case .none:
                continue
            }
        }
        return result
    }
    
}
