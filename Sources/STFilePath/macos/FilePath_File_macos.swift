//
//  File.swift
//  
//
//  Created by linhey on 2022/5/13.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Foundation
import AppKit
import SwiftUI

public extension STFile {
    
    /// [en] A struct that represents an application that can be associated with a file.
    /// [zh] 一个表示可以与文件关联的应用程序的结构体。
    struct AssociatedApplication: Identifiable, Equatable, Hashable {
        
        /// [en] The unique identifier of the application.
        /// [zh] 应用程序的唯一标识符。
        public var id: URL { url }
        /// [en] The URL of the application.
        /// [zh] 应用程序的 URL。
        public let url: URL
        /// [en] The bundle of the application.
        /// [zh] 应用程序的包。
        public var bundle: Bundle { .init(path: url.path)! }
        /// [en] The name of the application.
        /// [zh] 应用程序的名称。
        public var name: String {
            if let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                return name
            } else if let name = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String {
                return name
            } else {
                return url.pathComponents.last ?? url.path
            }
        }
        
        /// [en] The icon of the application.
        /// [zh] 应用程序的图标。
        public func icon() -> NSImage {
            NSWorkspace.shared.icon(forFile: url.path)
        }
        
        /// [en] The icon of the application as a SwiftUI `Image`.
        /// [zh] 作为 SwiftUI `Image` 的应用程序图标。
        public func icon() -> Image {
            .init(nsImage: icon())
        }
        
        /// [en] Opens the specified files with the application.
        /// [zh] 使用此应用程序打开指定的文件。
        /// - Parameter files: The files to open.
        public func open(_ files: [STFile]) {
            NSWorkspace.shared.open(files.map(\.url), withApplicationAt: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }
    
    /// [en] Opens the file with the specified application.
    /// [zh] 使用指定的应用程序打开文件。
    /// - Parameter app: The application to open the file with.
    func open(with app: AssociatedApplication) {
        app.open([self])
    }
    
    /// [en] The list of applications associated with the file.
    /// [zh] 与文件关联的应用程序列表。
    var associatedApplications: [AssociatedApplication] {
        let list = (LSCopyApplicationURLsForURL(url as CFURL, .all)?.takeRetainedValue() as? [URL]) ?? []
        return list.map(AssociatedApplication.init(url:))
    }
    
}
#endif
