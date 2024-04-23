// MIT License
//
// Copyright (c) 2020 linhey
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Foundation
import AppKit

public extension STPathProtocol {
    
    func showInFinder() {
        guard let referenceType = STPath(url).referenceType else {
            return
        }
        switch referenceType {
        case .file(let value):
            NSWorkspace.shared.activateFileViewerSelecting([value.url])
        case .folder(let value):
           _ = NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: value.url.path)
        }
    }
    
    static func selectInFinder(_ folder: URL,
                               support: [STFilePathItemType] = [.file, .folder],
                               allowsMultipleSelection: Bool = true) -> [STPath] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = support.contains(.file)
        panel.canChooseDirectories = support.contains(.folder)
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.directoryURL = folder
        
        if panel.runModal() == .OK {
            return panel.urls.compactMap(STPath.init)
        }
        
        return []
    }
    
}

@available(macCatalyst, unavailable)
public extension STFolder {
    
    func selectInFinder(support: [STFilePathItemType] = [.file, .folder],
                        allowsMultipleSelection: Bool = true) -> [STPath] {
        return Self.selectInFinder(url,
                                   support: support,
                                   allowsMultipleSelection: allowsMultipleSelection)
    }
    
}

#endif
