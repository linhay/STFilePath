//
//  File.swift
//  
//
//  Created by linhey on 2022/12/18.
//

#if canImport(UIKit) && canImport(UniformTypeIdentifiers)
import UIKit
import UniformTypeIdentifiers

@available(iOS 14.0, *)
public class STDocumentPicker: NSObject, UIDocumentPickerDelegate {
    
    public let finishEvent: (_ paths: [STPath]) -> Void
    public let types: [UTType]
    open var allowsMultipleSelection: Bool = true
    
    public init(types: [UTType], finishEvent: @escaping (_ paths: [STPath]) -> Void) {
        self.types = types
        self.finishEvent = finishEvent
    }
    
    open func allowsMultipleSelection(_ bool: Bool) -> Self {
        self.allowsMultipleSelection = bool
        return self
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard urls.contains(where: { $0.startAccessingSecurityScopedResource() == false }) == false else {
            assertionFailure("授权失败")
            return
        }
        
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        var newURLs = [URL]()
        for url in urls {
            coordinator.coordinate(readingItemAt: url, error: &error) { url in
                newURLs.append(url)
            }
        }
        
        finishEvent(newURLs.map(STPath.init))
        urls.forEach { url in
            url.stopAccessingSecurityScopedResource()
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finishEvent([])
    }
    
    open func show(in source: UIViewController) -> Self {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
        controller.allowsMultipleSelection = allowsMultipleSelection
        controller.delegate = self
        source.present(controller, animated: true)
        return self
    }
    
}
#endif
