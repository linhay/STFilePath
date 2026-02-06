iOS / macOS integrations

Search hints
- iOS: `rg -n "STDocumentPicker|STPathQuickLookController" Sources/STFilePath/ios`
- macOS: `rg -n "showInFinder|selectInFinder|AssociatedApplication|associatedApplications" Sources/STFilePath/macos`

Use cases
1) iOS 导入文件（DocumentPicker 选多个文件）
```swift
// iOS 14+ / UIKit
// 在 UIViewController 里：
// let picker = STDocumentPicker(types: [.json, .plainText]) { paths in
//   for p in paths { print(p.url) }
// }
// picker.allowsMultipleSelection(true).show(in: self)
```

2) iOS 快速预览（QuickLook）
```swift
// let vc = STPathQuickLookController([file1, file2], selected: file1)
// present(vc, animated: true)
```

3) macOS 让用户选目录/在 Finder 打开
```swift
// @MainActor
// let picked = STFolder("/tmp").selectInFinder(support: [.folder], allowsMultipleSelection: false)
// picked.first?.showInFinder()
```

iOS
1) Document picker (iOS 14+)
- `STDocumentPicker` wraps `UIDocumentPickerViewController`.
- You provide `types: [UTType]` and an async `finishEvent` that receives `[STPath]`.
- Implementation: `Sources/STFilePath/ios/STDocumentPicker.swift`

2) QuickLook preview
- `STPathQuickLookController` previews one or more `STPathProtocol` items.
- Implementation: `Sources/STFilePath/ios/STFilePreview.swift`

macOS
1) Finder utilities (non-Catalyst)
- `STPathProtocol.showInFinder()`
- `STPathProtocol.selectInFinder(_:support:allowsMultipleSelection:)` (static, @MainActor)
- `STFolder.selectInFinder(...)` (instance helper)
- Implementation: `Sources/STFilePath/macos/FilePath+NSOpenPanel.swift`

2) Associated applications + open with app (non-Catalyst)
- `STFile.associatedApplications -> [STFile.AssociatedApplication]`
- `STFile.open(with:)`
- `AssociatedApplication.open(_ files:)`
- Implementation: `Sources/STFilePath/macos/FilePath_File_macos.swift`

Common gotchas
- These files are conditionally compiled with `#if canImport(...)` and `!targetEnvironment(macCatalyst)`.
- UI APIs must be called on the main actor where annotated.
