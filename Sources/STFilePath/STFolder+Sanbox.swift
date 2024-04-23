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

#if !os(Linux)
import Foundation

public extension STFolder {
        
    struct Sanbox {
        
        let url: URL
        
        public static var root: Sanbox { .init(url: URL(fileURLWithPath: NSOpenStepRootDirectory())) }
        public static var home: Sanbox { .init(url: URL(fileURLWithPath: NSHomeDirectory())) }
        public static var temporary: Sanbox { .init(url: URL(fileURLWithPath: NSTemporaryDirectory())) }
        
        public static var document: Sanbox {
            get throws {
                .init(url: try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))
            }
        }
        public static var library: Sanbox {
            get throws {
                .init(url: try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false))
            }
        }
        public static var cache: Sanbox {
            get throws {
                .init(url: try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false))
            }
        }
    }
    
    init(sanbox rootPath: Sanbox) throws {
        self.init(rootPath.url)
    }
    
    init(applicationGroup: String) throws {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroup) else {
            throw STPathError(message: "applicationGroup 无法识别")
        }
        self.init(url)
    }
    
    init(ubiquityContainerIdentifier: String) throws {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier) else {
            throw STPathError(message: "iCloud 不可用")
        }
        self.init(url)
    }
    
    init(iCloud identifier: String) throws {
        try self.init(ubiquityContainerIdentifier: identifier)
    }
    
}
#endif
