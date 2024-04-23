//
//  File.swift
//  
//
//  Created by linhey on 2023/3/15.
//

import Foundation

public extension STFolder {
    
    // 用于指定搜索的条件
    enum SearchPredicate {
        // 跳过子目录和后代文件夹
        case skipsSubdirectoryDescendants
        // 跳过包和其后代文件夹
        case skipsPackageDescendants
        // 跳过隐藏的文件
        case skipsHiddenFiles
        // 在目录中包括后代目录
        @available(iOS 13.0, *) @available(macOS 10.15, *) @available(tvOS 13.0, *)
        case includesDirectoriesPostOrder
        // 生成相对路径的URL
        @available(iOS 13.0, *) @available(macOS 10.15, *) @available(tvOS 13.0, *)
        case producesRelativePathURLs
        // 自定义搜索条件，参数为 STPath 类型，返回值为 Bool 类型
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

    @inlinable
    func contains<Element: STPathProtocol>(_ predicate: Element) -> Bool {
        let components = self.url.pathComponents
        return Array(predicate.url.pathComponents.prefix(components.count)) == components
    }
    
}

public extension STFolder {
    
    func files(_ predicates: [SearchPredicate] = []) throws -> [STFile] {
        try subFilePaths(predicates).compactMap(\.asFile)
    }
    
    func folders(_ predicates: [SearchPredicate] = []) throws -> [STFolder] {
        try subFilePaths(predicates).compactMap(\.asFolder)
    }
    
    /// 递归获取文件夹中所有文件/文件夹
    /// - Throws: FilePathError - "目标路径不是文件夹类型"
    /// - Parameter predicates: 查找条件
    /// - Returns: [FilePath]
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
    
    /// 获取当前文件夹中文件/文件夹
    /// - Throws: FilePathError - "目标路径不是文件夹类型"
    /// - Parameter predicates: 查找条件
    /// - Returns: [FilePath]
    func subFilePaths(_ predicates: [SearchPredicate] = []) throws -> [STPath] {
        let (systemPredicates, customPredicates) = predicates.split()
        return try manager
            .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: systemPredicates)
            .compactMap({ STPath($0) })
            .filter({ item -> Bool in
               return try customPredicates.contains(where: { try $0(item) == false }) == false
            })
    }
    
    
    /// 文件扫描
    /// - Parameter scanSubFolder: 是否扫描子文件夹
    /// - Returns: 文件序列
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func fileScan(folderFilter: @escaping ((STFolder) async throws -> Bool) = { _ in true },
                  fileFilter: @escaping ((STFile) async throws -> Bool) = { _ in true }) -> AsyncThrowingStream<STFile, Error> {
        .init { continuation in
            Task {
                do {
                    let urls = try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    for url in urls {
                        do {
                            let filePath = STPath(url)
                            switch filePath.referenceType {
                            case .file(let file):
                                if try await fileFilter(file) {
                                    continuation.yield(file)
                                }
                            case .folder(let folder):
                                if try await folderFilter(folder) {
                                    for try await item in folder.fileScan(folderFilter: folderFilter) {
                                        continuation.yield(item)
                                    }
                                }
                            case .none:
                                continue
                            }
                        } catch {
                            debugPrint("FilePath Scan: ", error.localizedDescription)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
}
