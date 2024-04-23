//
//  FBPreviewViewController.swift
//  iOS
//
//  Created by linhey on 2022/9/7.
//

#if canImport(QuickLook) && canImport(UIKit)
import UIKit
import QuickLook

class STPathPreviewItem: NSObject, QLPreviewItem {
    
    var previewItemURL: URL?
    
    init(_ path: any STPathProtocol) {
        self.previewItemURL = path.url
    }
    
}

open class STPathQuickLookController: QLPreviewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    let paths: [STPathPreviewItem]
    let selected: Int?
    
    public init(_ paths: any STPathProtocol) {
        self.paths = [STPathPreviewItem(paths)]
        self.selected = 0
        super.init(nibName: nil, bundle: nil)
    }
    
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
