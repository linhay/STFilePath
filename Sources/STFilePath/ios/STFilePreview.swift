//
//  FBPreviewViewController.swift
//  iOS
//
//  Created by linhey on 2022/9/7.
//

#if canImport(QuickLook) && canImport(UIKit)
import UIKit
import QuickLook

/// [en] A `QLPreviewItem` that represents a file path.
/// [zh] 一个表示文件路径的 `QLPreviewItem`。
class STPathPreviewItem: NSObject, QLPreviewItem {
    
    /// [en] The URL of the preview item.
    /// [zh] 预览项的 URL。
    var previewItemURL: URL?
    
    /// [en] Initializes a new `STPathPreviewItem` instance.
    /// [zh] 初始化一个新的 `STPathPreviewItem` 实例。
    /// - Parameter path: The path of the file to preview.
    init(_ path: any STPathProtocol) {
        self.previewItemURL = path.url
    }
    
}

/// [en] A `QLPreviewController` that displays a preview of one or more file paths.
/// [zh] 一个显示一个或多个文件路径预览的 `QLPreviewController`。
open class STPathQuickLookController: QLPreviewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    let paths: [STPathPreviewItem]
    let selected: Int?
    
    /// [en] Initializes a new `STPathQuickLookController` instance for a single file path.
    /// [zh] 为单个文件路径初始化一个新的 `STPathQuickLookController` 实例。
    /// - Parameter paths: The file path to preview.
    public init(_ paths: any STPathProtocol) {
        self.paths = [STPathPreviewItem(paths)]
        self.selected = 0
        super.init(nibName: nil, bundle: nil)
    }
    
    /// [en] Initializes a new `STPathQuickLookController` instance for multiple file paths.
    /// [zh] 为多个文件路径初始化一个新的 `STPathQuickLookController` 实例。
    /// - Parameters:
    ///   - paths: The file paths to preview.
    ///   - selected: The file path to select initially.
    public init(_ paths: [any STPathProtocol], selected: (any STPathProtocol)? = nil) {
        self.paths = paths.map(STPathPreviewItem.init)
        if let selected {
            self.selected = paths.map(\.url).firstIndex(of: selected.url) ?? 0
        } else {
            self.selected = nil
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
        self.reloadData()
        self.currentPreviewItemIndex = selected ?? 0
    }
    
    open func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        paths.count
    }
    
    open func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        paths[index] as QLPreviewItem
    }
    
}

#endif
