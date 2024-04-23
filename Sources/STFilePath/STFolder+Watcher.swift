//
//  File.swift
//  
//
//  Created by linhey on 2022/7/13.
//

#if canImport(Combine) && canImport(Darwin)
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension STFolder {
    
    func watcher() throws -> STFolderWatcher {
        let watcher = STFolderWatcher(self)
        try watcher.startMonitoring()
        return watcher
    }
    
}
#endif
