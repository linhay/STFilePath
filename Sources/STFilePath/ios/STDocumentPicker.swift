//
//  File.swift
//  
//
//  Created by linhey on 2022/12/18.
//

#if canImport(UIKit) && canImport(UniformTypeIdentifiers)
import UIKit
import UniformTypeIdentifiers

/// [en] A class that provides a document picker for iOS.
/// [zh] 一个为 iOS 提供文档选择器的类。
@available(iOS 14.0, *)
public class STDocumentPicker: NSObject, UIDocumentPickerDelegate {
    
    /// [en] An event that is called when the document picker finishes.
    /// [zh] 文档选择器完成时调用的事件。
    public let finishEvent: @MainActor (_ paths: [STPath]) async throws -> Void
    /// [en] The types of documents to allow the user to select.
    /// [zh] 允许用户选择的文档类型。
    public let types: [UTType]
    /// [en] Whether the user can select multiple documents.
    /// [zh] 用户是否可以选择多个文档。
    open private(set) var allowsMultipleSelection: Bool = false
    
    /// [en] Initializes a new `STDocumentPicker` instance.
    /// [zh] 初始化一个新的 `STDocumentPicker` 实例。
    /// - Parameters:
    ///   - types: The types of documents to allow the user to select.
    ///   - finishEvent: An event that is called when the document picker finishes.
    public init(types: [UTType], finishEvent: @MainActor @escaping (_ paths: [STPath]) async throws -> Void) {
        self.types = types
        self.finishEvent = finishEvent
    }
    
    /// [en] Sets whether the user can select multiple documents.
    /// [zh] 设置用户是否可以选择多个文档。
    /// - Parameter bool: Whether to allow multiple selection.
    /// - Returns: The `STDocumentPicker` instance.
    open func allowsMultipleSelection(_ bool: Bool) -> Self {
        self.allowsMultipleSelection = bool
        return self
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard urls.contains(where: { $0.startAccessingSecurityScopedResource() == false }) == false else {
            assertionFailure("[en] Authorization failed \n [zh] 授权失败")
            return
        }
        
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        var newURLs = [URL]()
        for url in urls {
            coordinator.coordinate(readingItemAt: url, error: &error) {
 url in
                newURLs.append(url)
            }
        }
        Task {
            try await finishEvent(newURLs.map(STPath.init))
//            urls.forEach { url in
//                url.stopAccessingSecurityScopedResource()
//            }
        }

    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) async throws {
        Task {
            try await finishEvent([])
        }
    }
    
    /// [en] Shows the document picker.
    /// [zh] 显示文档选择器。
    /// - Parameter source: The view controller to present the document picker from.
    /// - Returns: The `STDocumentPicker` instance.
    open func show(in source: UIViewController) -> Self {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
        controller.allowsMultipleSelection = allowsMultipleSelection
        controller.delegate = self
        source.present(controller, animated: true)
        return self
    }
    
}
#endif
